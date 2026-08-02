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

public class GetAISummaryServlet extends HttpServlet {

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

        // Query AI_Conversation table for this patient's AI summaries
        String sql = "SELECT conversation_id, health_record_id, chat_history, AI_Conversation, created_at " +
                "FROM AI_Conversation " +
                "WHERE patient_id = ? AND health_record_id = ? " +
                "ORDER BY created_at DESC";

        List<Map<String, String>> summaries = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, patientId);
            stmt.setInt(2, healthRecordId);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                Map<String, String> item = new HashMap<>();
                item.put("conversationId", String.valueOf(rs.getInt("conversation_id")));
                item.put("chatHistory", rs.getString("chat_history"));
                item.put("aiSummary", rs.getString("AI_Conversation"));
                item.put("createdAt", rs.getString("created_at"));
                summaries.add(item);
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
        json.append("\"summaries\":[");
        for (int i = 0; i < summaries.size(); i++) {
            Map<String, String> s = summaries.get(i);
            if (i > 0) json.append(",");
            json.append("{");
            json.append("\"conversationId\":").append(s.get("conversationId")).append(",");
            json.append("\"chatHistory\":\"").append(escapeJson(s.get("chatHistory"))).append("\",");
            json.append("\"aiSummary\":\"").append(escapeJson(s.get("aiSummary"))).append("\",");
            json.append("\"createdAt\":\"").append(escapeJson(s.get("createdAt"))).append("\"");
            json.append("}");
        }
        json.append("]}");

        try (PrintWriter out = response.getWriter()) {
            out.print(json.toString());
        }
    }

    private Integer findPatientId(User user) {
        if (user == null) return null;
        String sql = "SELECT patient_id FROM Patient WHERE account_id = ? OR (email = ? AND email IS NOT NULL AND email <> '')";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, user.getId());
            statement.setString(2, user.getEmail() != null ? user.getEmail() : "");
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

    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
