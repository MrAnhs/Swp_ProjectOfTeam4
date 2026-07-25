package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.RecordSharingDAO;
import com.diabetes.monitoring.model.RecordSharing;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class FamilyDashboardServlet extends HttpServlet {
    private final RecordSharingDAO sharingDAO = new RecordSharingDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!"Patient".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String ownerIdStr = request.getParameter("ownerId");
        if (ownerIdStr == null || ownerIdStr.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thieu tham so ownerId.");
            return;
        }

        int ownerId;
        try {
            ownerId = Integer.parseInt(ownerIdStr.trim());
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ownerId khong hop le.");
            return;
        }

        // Verify sharing relationship
        RecordSharing sharing;
        try {
            sharing = sharingDAO.getAcceptedSharingWithOwnerInfo(ownerId, currentUser.getId());
            if (sharing == null) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Ban khong co quyen truy cap ho so cua nguoi nay.");
                return;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Loi kiem tra quyen truy cap.");
            return;
        }

        // Check if this is an AJAX data request
        String type = request.getParameter("type");
        if (type != null) {
            handleAjaxData(request, response, ownerId, type, sharing);
            return;
        }

        // Otherwise, forward to JSP view
        request.setAttribute("sharing", sharing);
        request.getRequestDispatcher("/WEB-INF/views/patient/family-dashboard.jsp").forward(request, response);
    }

    private void handleAjaxData(HttpServletRequest request, HttpServletResponse response,
                                int ownerId, String type, RecordSharing sharing) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        
        // Validate specific permissions
        if ("appointments".equals(type) && !sharing.isCanViewAppointments()) {
            response.getWriter().print("{\"success\":false,\"message\":\"Ban chua duoc cap quyen xem lich hen.\"}");
            return;
        }
        if ("invoices".equals(type) && !sharing.isCanViewInvoices()) {
            response.getWriter().print("{\"success\":false,\"message\":\"Ban chua duoc cap quyen xem hoa don.\"}");
            return;
        }
        if ("records".equals(type) && !sharing.isCanViewRecords()) {
            response.getWriter().print("{\"success\":false,\"message\":\"Ban chua duoc cap quyen xem ho so benh an.\"}");
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            StringBuilder json = new StringBuilder("{\"success\":true,\"data\":[");
            if ("appointments".equals(type)) {
                String sql = "SELECT a.appointment_id, CAST(a.appointment_time AS date) AS work_date, ds.time_slot, d.full_name AS doctor_name, a.status "
                        + "FROM Appointment a "
                        + "JOIN Patient p ON p.patient_id = a.patient_id "
                        + "JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                        + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                        + "WHERE p.account_id = ? "
                        + "ORDER BY a.appointment_time DESC, a.appointment_id DESC";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, ownerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        int count = 0;
                        while (rs.next()) {
                            if (count++ > 0) json.append(",");
                            java.sql.Date workDate = rs.getDate("work_date");
                            String workDateStr = workDate != null ? workDate.toString() : "";
                            
                            json.append("{")
                                .append("\"id\":").append(rs.getInt("appointment_id")).append(",")
                                .append("\"workDate\":\"").append(workDateStr).append("\",")
                                .append("\"timeSlot\":\"").append(escapeJson(rs.getString("time_slot"))).append("\",")
                                .append("\"doctorName\":\"").append(escapeJson(rs.getString("doctor_name"))).append("\",")
                                .append("\"status\":\"").append(escapeJson(rs.getString("status"))).append("\"")
                                .append("}");
                        }
                    }
                }
            } else if ("invoices".equals(type)) {
                String sql = "SELECT i.invoice_id, i.final_amount, i.status, i.created_at "
                        + "FROM Invoice i "
                        + "JOIN Patient p ON p.patient_id = i.patient_id "
                        + "WHERE p.account_id = ? "
                        + "ORDER BY i.created_at DESC, i.invoice_id DESC";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, ownerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        int count = 0;
                        while (rs.next()) {
                            if (count++ > 0) json.append(",");
                            java.sql.Timestamp createdAt = rs.getTimestamp("created_at");
                            String createdAtStr = createdAt != null ? createdAt.toString() : "";

                            json.append("{")
                                .append("\"id\":").append(rs.getInt("invoice_id")).append(",")
                                .append("\"totalAmount\":").append(rs.getBigDecimal("final_amount")).append(",")
                                .append("\"finalAmount\":").append(rs.getBigDecimal("final_amount")).append(",")
                                .append("\"status\":\"").append(escapeJson(rs.getString("status"))).append("\",")
                                .append("\"createdAt\":\"").append(createdAtStr).append("\"")
                                .append("}");
                        }
                    }
                }
            } else if ("records".equals(type)) {
                String sql = "SELECT hr.health_record_id, hr.created_at, hr.urea, hr.cr, hr.hba1c, hr.bmi, hr.weight, hr.height, hr.status, d.full_name AS doctor_name, mr.final_diagnosis, "
                        + "hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl "
                        + "FROM Healthy_Record hr "
                        + "LEFT JOIN Doctor d ON d.doctor_id = hr.doctor_id "
                        + "LEFT JOIN Medical_record mr ON (mr.health_record_id = hr.health_record_id OR mr.record_id = hr.record_id) "
                        + "WHERE hr.patient_id = (SELECT patient_id FROM Patient WHERE account_id = ?) "
                        + "ORDER BY hr.created_at DESC, hr.health_record_id DESC";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, ownerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        int count = 0;
                        while (rs.next()) {
                            if (count++ > 0) json.append(",");
                            java.sql.Timestamp createdAt = rs.getTimestamp("created_at");
                            String createdAtStr = createdAt != null ? createdAt.toString() : "";

                            json.append("{")
                                .append("\"id\":").append(rs.getInt("health_record_id")).append(",")
                                .append("\"createdAt\":\"").append(createdAtStr).append("\",")
                                .append("\"urea\":").append(rs.getObject("urea") != null ? rs.getBigDecimal("urea") : "null").append(",")
                                .append("\"cr\":").append(rs.getObject("cr") != null ? rs.getBigDecimal("cr") : "null").append(",")
                                .append("\"hba1c\":").append(rs.getObject("hba1c") != null ? rs.getBigDecimal("hba1c") : "null").append(",")
                                .append("\"bmi\":").append(rs.getObject("bmi") != null ? rs.getBigDecimal("bmi") : "null").append(",")
                                .append("\"weight\":").append(rs.getObject("weight") != null ? rs.getBigDecimal("weight") : "null").append(",")
                                .append("\"height\":").append(rs.getObject("height") != null ? rs.getBigDecimal("height") : "null").append(",")
                                .append("\"chol\":").append(rs.getObject("chol") != null ? rs.getBigDecimal("chol") : "null").append(",")
                                .append("\"tg\":").append(rs.getObject("tg") != null ? rs.getBigDecimal("tg") : "null").append(",")
                                .append("\"hdl\":").append(rs.getObject("hdl") != null ? rs.getBigDecimal("hdl") : "null").append(",")
                                .append("\"ldl\":").append(rs.getObject("ldl") != null ? rs.getBigDecimal("ldl") : "null").append(",")
                                .append("\"vldl\":").append(rs.getObject("vldl") != null ? rs.getBigDecimal("vldl") : "null").append(",")
                                .append("\"status\":\"").append(escapeJson(rs.getString("status"))).append("\",")
                                .append("\"finalDiagnosis\":").append(rs.getString("final_diagnosis") != null ? "\"" + escapeJson(rs.getString("final_diagnosis")) + "\"" : "null").append(",")
                                .append("\"doctorName\":").append(rs.getString("doctor_name") != null ? "\"" + escapeJson(rs.getString("doctor_name")) + "\"" : "null")
                                .append("}");
                        }
                    }
                }
            }
            json.append("]}");
            response.getWriter().print(json.toString());
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"success\":false,\"message\":\"Loi tai du lieu nguoi than tu CSDL.\"}");
        }
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\b", "\\b")
                  .replace("\f", "\\f")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t");
    }
}
