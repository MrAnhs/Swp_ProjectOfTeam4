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

public class AISummaryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        String conversationId = request.getParameter("id");
        if (conversationId == null || conversationId.trim().isEmpty()) {
            response.setStatus(400);
            response.getWriter().print("{\"error\":\"Missing summary ID\"}");
            return;
        }

        int conversationIdValue;
        try {
            conversationIdValue = Integer.parseInt(conversationId);
        } catch (NumberFormatException e) {
            response.setStatus(400);
            response.getWriter().print("{\"error\":\"Invalid summary ID\"}");
            return;
        }

        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> messages = new ArrayList<>();

        // Only return a summary owned by the patient account in the session.
        String sql = "SELECT c.conversation_id, c.patient_id, c.chat_history, c.created_at " +
                "FROM AI_Conversation c " +
                "INNER JOIN Patient p ON c.patient_id = p.patient_id " +
                "WHERE c.conversation_id = ? AND p.account_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
            PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, conversationIdValue);
            stmt.setInt(2, currentUser.getId());
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                result.put("conversationId", rs.getInt("conversation_id"));
                result.put("patientId", rs.getInt("patient_id"));
                result.put("analysisTime", rs.getString("created_at"));

                // Parse the stored chat history into individual messages.
                String conversationHistory = rs.getString("chat_history");
                if (conversationHistory != null && !conversationHistory.isEmpty()) {
                    messages = parseConversationHistory(conversationHistory);
                }
                result.put("messages", messages);
            } else {
                response.setStatus(404);
                response.getWriter().print("{\"error\":\"Summary not found\"}");
                return;
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Database error: " + e.getMessage() + "\"}");
            return;
        }

        // Manual JSON building
        try (PrintWriter out = response.getWriter()) {
            StringBuilder json = new StringBuilder();
            json.append("{\"conversationId\":").append(result.get("conversationId")).append(",");
            json.append("\"patientId\":").append(result.get("patientId")).append(",");
            json.append("\"analysisTime\":\"").append(escJson((String)result.get("analysisTime"))).append("\",");
            json.append("\"messages\":[");
            
            List<Map<String, Object>> msgs = messages;
            for (int i = 0; i < msgs.size(); i++) {
                Map<String, Object> m = msgs.get(i);
                if (i > 0) json.append(",");
                json.append("{");
                json.append("\"sender\":\"").append(m.get("sender")).append("\",");
                json.append("\"message\":\"").append(escJson((String)m.get("message"))).append("\",");
                json.append("\"time\":\"").append(escJson((String)m.get("time"))).append("\"");
                json.append("}");
            }
            json.append("]}");
            out.print(json.toString());
        }
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

    private List<Map<String, Object>> parseConversationHistory(String history) {
        List<Map<String, Object>> messages = new ArrayList<>();

        if (history == null || history.isEmpty()) {
            return messages;
        }

        String[] lines = history.split("\n");
        StringBuilder currentMessage = new StringBuilder();
        String currentSender = "";

        for (String line : lines) {
            line = line.trim();
            if (line.startsWith("User:") || line.startsWith("Patient:") || line.startsWith("Người dùng:")) {
                if (!currentSender.isEmpty() && currentMessage.length() > 0) {
                    Map<String, Object> msg = new HashMap<>();
                    msg.put("sender", currentSender.equals("User") ? "user" : "ai");
                    msg.put("message", currentMessage.toString().trim());
                    msg.put("time", "");
                    messages.add(msg);
                }
                currentSender = "User";
                currentMessage = new StringBuilder(line.substring(line.indexOf(":") + 1).trim());
            } else if (line.startsWith("AI:") || line.startsWith("Bác sĩ AI:")) {
                if (!currentSender.isEmpty() && currentMessage.length() > 0) {
                    Map<String, Object> msg = new HashMap<>();
                    msg.put("sender", currentSender.equals("User") ? "user" : "ai");
                    msg.put("message", currentMessage.toString().trim());
                    msg.put("time", "");
                    messages.add(msg);
                }
                currentSender = "AI";
                currentMessage = new StringBuilder(line.substring(line.indexOf(":") + 1).trim());
            } else if (!line.isEmpty()) {
                currentMessage.append(" ").append(line);
            }
        }

        if (!currentSender.isEmpty() && currentMessage.length() > 0) {
            Map<String, Object> msg = new HashMap<>();
            msg.put("sender", currentSender.equals("User") ? "user" : "ai");
            msg.put("message", currentMessage.toString().trim());
            msg.put("time", "");
            messages.add(msg);
        }

        return messages;
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setStatus(405);
        response.getWriter().print("{\"error\":\"Method not allowed\"}");
    }
}
