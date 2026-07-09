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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
public class MedicalHistoryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        System.out.println("[MedicalHistoryServlet] doGet called");
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            System.out.println("[MedicalHistoryServlet] No user in session");
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        int accountId = currentUser.getId();
        System.out.println("[MedicalHistoryServlet] accountId=" + accountId);
        List<Map<String, Object>> records = new ArrayList<>();

        // Query to get patient_id first
        String patientSql = "SELECT patient_id FROM Patient WHERE account_id = ?";
        int patientId = -1;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(patientSql)) {
            stmt.setInt(1, accountId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                patientId = rs.getInt("patient_id");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Database error\"}");
            return;
        }

        if (patientId == -1) {
            System.out.println("[MedicalHistoryServlet] Patient not found for accountId=" + accountId);
            response.setStatus(404);
            response.getWriter().print("{\"error\":\"Patient not found\"}");
            return;
        }

        // Query Healthy_Record for this patient
        String healthRecordSql = "SELECT health_record_id, urea, cr, hba1c, chol, tg, hdl, idl AS ldl, vldl, " +
                "bmi, weight, height, other_information, status, created_at " +
                "FROM Healthy_Record " +
                "WHERE patient_id = ? " +
                "ORDER BY created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(healthRecordSql)) {
            stmt.setInt(1, patientId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("healthRecordId", rs.getInt("health_record_id"));
                record.put("urea", rs.getString("urea"));
                record.put("cr", rs.getString("cr"));
                record.put("hba1c", rs.getString("hba1c"));
                record.put("chol", rs.getString("chol"));
                record.put("tg", rs.getString("tg"));
                record.put("hdl", rs.getString("hdl"));
                record.put("ldl", rs.getString("ldl"));
                record.put("vldl", rs.getString("vldl"));
                record.put("bmi", rs.getString("bmi"));
                record.put("weight", rs.getString("weight"));
                record.put("height", rs.getString("height"));
                record.put("symptoms", rs.getString("other_information"));
                record.put("status", rs.getString("status"));
                record.put("createdAt", rs.getString("created_at"));
                records.add(record);
            }

        } catch (SQLException e) {
            System.out.println("[MedicalHistoryServlet] SQL Error getting patientId: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Database error: " + escJson(e.getMessage()) + "\"}");
            return;
        }

        // Manual JSON building (no external library)
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        try (PrintWriter out = response.getWriter()) {
            StringBuilder json = new StringBuilder();
            json.append("{\"records\":[");
            for (int i = 0; i < records.size(); i++) {
                Map<String, Object> r = records.get(i);
                if (i > 0) json.append(",");
                json.append("{");
                json.append("\"healthRecordId\":").append(r.get("healthRecordId")).append(",");
                json.append("\"urea\":\"").append(escJson((String)r.get("urea"))).append("\",");
                json.append("\"cr\":\"").append(escJson((String)r.get("cr"))).append("\",");
                json.append("\"hba1c\":\"").append(escJson((String)r.get("hba1c"))).append("\",");
                json.append("\"chol\":\"").append(escJson((String)r.get("chol"))).append("\",");
                json.append("\"tg\":\"").append(escJson((String)r.get("tg"))).append("\",");
                json.append("\"hdl\":\"").append(escJson((String)r.get("hdl"))).append("\",");
                json.append("\"ldl\":\"").append(escJson((String)r.get("ldl"))).append("\",");
                json.append("\"vldl\":\"").append(escJson((String)r.get("vldl"))).append("\",");
                json.append("\"bmi\":\"").append(escJson((String)r.get("bmi"))).append("\",");
                json.append("\"weight\":\"").append(escJson((String)r.get("weight"))).append("\",");
                json.append("\"height\":\"").append(escJson((String)r.get("height"))).append("\",");
                json.append("\"symptoms\":\"").append(escJson((String)r.get("symptoms"))).append("\",");
                json.append("\"status\":\"").append(escJson((String)r.get("status"))).append("\",");
                json.append("\"createdAt\":\"").append(escJson((String)r.get("createdAt"))).append("\"");
                json.append("}");
            }
            json.append("]}");
            out.print(json.toString());
            System.out.println("[MedicalHistoryServlet] Success - returned " + records.size() + " records");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        // POST not needed for this servlet
        response.setStatus(405);
        response.getWriter().print("{\"error\":\"Method not allowed\"}");
    }

    // JSON string escape helper
    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "")
                .replace("\t", "\\t");
    }
}
