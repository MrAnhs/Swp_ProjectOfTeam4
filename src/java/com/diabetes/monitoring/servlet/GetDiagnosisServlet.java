package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class GetDiagnosisServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        String healthRecordIdStr = request.getParameter("healthRecordId");
        if (healthRecordIdStr == null || healthRecordIdStr.isEmpty()) {
            response.setStatus(400);
            response.getWriter().print("{\"error\":\"Missing healthRecordId\"}");
            return;
        }

        int healthRecordId;
        try {
            healthRecordId = Integer.parseInt(healthRecordIdStr);
        } catch (NumberFormatException e) {
            response.setStatus(400);
            response.getWriter().print("{\"error\":\"Invalid healthRecordId\"}");
            return;
        }

        Integer patientId = findPatientId(currentUser);
        if (patientId == null) {
            response.setStatus(404);
            response.getWriter().print("{\"error\":\"Patient not found\"}");
            return;
        }

        // Verify this health record belongs to this patient
        if (!isHealthRecordOwnedByPatient(healthRecordId, patientId)) {
            response.setStatus(403);
            response.getWriter().print("{\"error\":\"Bạn không có quyền truy cập.\"}");
            return;
        }

        // Query Medical_record for diagnosis with this health_record_id
        String sql = "SELECT mr.record_id, mr.final_diagnosis, mr.doctor_note, " +
                "mr.processed_at, d.full_name as doctor_name, p.full_name as patient_name " +
                "FROM Medical_record mr " +
                "LEFT JOIN Doctor d ON mr.doctor_id = d.doctor_id " +
                "LEFT JOIN Patient p ON mr.patient_id = p.patient_id " +
                "WHERE mr.health_record_id = ? AND mr.patient_id = ?";

        Map<String, String> diagnosis = new HashMap<>();
        String patientName = "";
        String doctorName = "";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, healthRecordId);
            stmt.setInt(2, patientId);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                diagnosis.put("recordId", String.valueOf(rs.getInt("record_id")));
                diagnosis.put("finalDiagnosis", rs.getString("final_diagnosis"));
                diagnosis.put("doctorNote", rs.getString("doctor_note"));
                diagnosis.put("processedAt", rs.getString("processed_at"));
                patientName = rs.getString("patient_name");
                doctorName = rs.getString("doctor_name");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Database error: " + escapeJson(e.getMessage()) + "\"}");
            return;
        }

        // Build JSON response
        StringBuilder json = new StringBuilder();
        json.append("{");
        if (!diagnosis.isEmpty()) {
            json.append("\"diagnosis\":{");
            json.append("\"recordId\":").append(diagnosis.get("recordId")).append(",");
            json.append("\"final_diagnosis\":\"").append(escapeJson(diagnosis.get("finalDiagnosis"))).append("\",");
            json.append("\"doctor_note\":\"").append(escapeJson(diagnosis.get("doctorNote"))).append("\",");
            json.append("\"processed_at\":\"").append(escapeJson(diagnosis.get("processedAt"))).append("\"");
            json.append("},");
        }
        json.append("\"patientName\":\"").append(escapeJson(patientName)).append("\",");
        json.append("\"doctorName\":\"").append(escapeJson(doctorName)).append("\"");
        json.append("}");

        try (PrintWriter out = response.getWriter()) {
            out.print(json.toString());
        }
    }

    private Integer findPatientId(User user) {
        if (user == null || user.getEmail() == null) return null;
        String sql = "SELECT patient_id FROM Patient WHERE email = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, user.getEmail());
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("patient_id");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private boolean isHealthRecordOwnedByPatient(int healthRecordId, int patientId) {
        String sql = "SELECT 1 FROM Healthy_Record WHERE health_record_id = ? AND patient_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, healthRecordId);
            stmt.setInt(2, patientId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
