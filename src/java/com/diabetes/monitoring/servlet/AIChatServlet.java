package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.GeminiIntegration;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;

public class AIChatServlet extends HttpServlet {
    private final GeminiIntegration geminiIntegration = new GeminiIntegration();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED,
                    "\u0422\u1ea1i kho\u1ea3n ch\u01b0a \u0111\u0103ng nh\u1eadp.");
            return;
        }

        try {
            int patientId = resolvePatientId(currentUser.getId());
            String action = request.getParameter("action");

            if ("finish".equals(action)) {
                finishConversation(request, response, patientId);
                return;
            }

            String message = requireMessage(request.getParameter("message"));
            continueConversation(response, currentUser, patientId, message);

        } catch (IllegalArgumentException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (ChatAccessException e) {
            writeError(response, e.status, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Kh\u00f4ng th\u1ec3 x\u1eed l\u00fd y\u00eau c\u1ea7u.");
        } catch (Exception e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "L\u1ed7i h\u1ec7 th\u1ed1ng. Vui l\u00f2ng th\u1eed l\u1ea1i.");
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  CONTINUE CONVERSATION  (mỗi lượt chat)
    // ──────────────────────────────────────────────────────────────
    private void continueConversation(HttpServletResponse response, User currentUser,
            int patientId, String message) throws IOException {

        // Lấy lịch sử chat từ session (memory)
        String history = nullToEmpty((String) getServletContext()
                .getAttribute("chatHistory_" + patientId));

        String prompt = "B\u1ec7nh nh\u00e2n: " + currentUser.getFullName()
                + "\nL\u1ecbch s\u1eed h\u1ed9i tho\u1ea1i:\n" + history
                + "\nTin nh\u1eafn hi\u1ec7n t\u1ea1i: " + message;

        String rawResponse = geminiIntegration.getChatResponse(prompt);
        String aiJson = normalizeAiJson(rawResponse);

        // Extract reply text
        String reply = extractJsonString(aiJson, "reply");
        if (reply.isEmpty() && rawResponse != null && !rawResponse.isBlank()) {
            // Fallback: nếu AI trả về plain text thay vì JSON
            reply = rawResponse.startsWith("{") ? 
                    "Xin h\u00e3y ti\u1ebfp t\u1ee5c chia s\u1ebb tri\u1ec7u ch\u1ee9ng c\u1ee7a b\u1ea1n." :
                    rawResponse.trim();
        }

        // Extract symptoms từ healthData (nếu có) — KHÔNG nhúng raw JSON
        String symptoms = extractJsonString(aiJson, "symptoms");

        // Cập nhật lịch sử chat trong memory
        String newHistory = trimHistory(history + "\nB\u1ec7nh nh\u00e2n: " + message + "\nAI: " + reply);
        getServletContext().setAttribute("chatHistory_" + patientId, newHistory);

        // Trả về JSON đơn giản, an toàn — không nhúng raw JSON
        StringBuilder sb = new StringBuilder();
        sb.append("{\"reply\":\"").append(escapeJson(reply)).append("\"");
        if (symptoms != null && !symptoms.isEmpty() && !symptoms.equals("0")) {
            sb.append(",\"symptoms\":\"").append(escapeJson(symptoms)).append("\"");
        }
        sb.append("}");
        response.getWriter().print(sb.toString());
    }

    // ──────────────────────────────────────────────────────────────
    //  FINISH → lưu vào AI_Summary / AI_Conversation
    // ──────────────────────────────────────────────────────────────
    private void finishConversation(HttpServletRequest request,
            HttpServletResponse response, int patientId)
            throws SQLException, IOException, ChatAccessException {

        String symptoms = nullToEmpty(request.getParameter("symptoms"));
        String clientHistory = nullToEmpty(request.getParameter("chatHistory"));
        String history = nullToEmpty((String) getServletContext()
                .getAttribute("chatHistory_" + patientId));

        if (history.isBlank()) {
            history = clientHistory;
        }

        if (history.isBlank() && symptoms.isBlank()) {
            throw new ChatAccessException(HttpServletResponse.SC_CONFLICT,
                    "Cu\u1ed9c tr\u00f2 chuy\u1ec7n ch\u01b0a c\u00f3 n\u1ed9i dung.");
        }

        // AI tóm tắt triệu chứng
        String aiSummary = "";
        if (!history.isBlank()) {
            try {
                String summaryPrompt = "H\u00e3y t\u00f3m t\u1eaft ng\u1eafn g\u1ecdn c\u00e1c tri\u1ec7u ch\u1ee9ng ch\u00ednh b\u1ec7nh nh\u00e2n \u0111\u00e3 chia s\u1ebb trong cu\u1ed9c tr\u00f2 chuy\u1ec7n sau "
                        + "(ch\u1ec9 li\u1ec7t k\u00ea tri\u1ec7u ch\u1ee9ng, kh\u00f4ng ch\u1ea9n \u0111o\u00e1n):\n\n" + history;
                String summaryJson = normalizeAiJson(geminiIntegration.getChatResponse(summaryPrompt));
                aiSummary = extractJsonString(summaryJson, "reply");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (aiSummary.isEmpty()) {
            // Fallback: dùng symptoms do user cung cấp hoặc fallbackSummary từ history
            aiSummary = symptoms.isEmpty() ? fallbackSummary(history) : symptoms;
        }

        // Save into DB
        saveAiSummaryToDatabase(patientId, aiSummary, symptoms, history);

        // Xóa lịch sử chat trong memory
        getServletContext().removeAttribute("chatHistory_" + patientId);

        response.getWriter().print("{\"success\":true,\"summary\":\""
                + escapeJson(aiSummary) + "\"}");
    }

    private void saveAiSummaryToDatabase(int patientId, String aiSummary, String symptoms, String history) {
        // Attempt 1: Ensure appointment_id is nullable if AI_Summary table exists
        try (Connection conn = DatabaseConnection.getConnection();
             java.sql.Statement stmt = conn.createStatement()) {
            stmt.execute("IF OBJECT_ID('dbo.AI_Summary', 'U') IS NOT NULL " +
                         "AND EXISTS (SELECT 1 FROM sys.columns c JOIN sys.objects o ON c.object_id = o.object_id " +
                         "WHERE o.name = 'AI_Summary' AND c.name = 'appointment_id' AND c.is_nullable = 0) " +
                         "BEGIN ALTER TABLE dbo.AI_Summary ALTER COLUMN appointment_id INT NULL; END");
        } catch (Exception ignored) {}

        // Attempt 2: Ensure AI_Summary table exists if missing
        try (Connection conn = DatabaseConnection.getConnection();
             java.sql.Statement stmt = conn.createStatement()) {
            stmt.execute("IF OBJECT_ID('dbo.AI_Summary', 'U') IS NULL " +
                         "BEGIN CREATE TABLE dbo.AI_Summary (" +
                         "summary_id VARCHAR(50) PRIMARY KEY, " +
                         "patient_id INT NOT NULL, " +
                         "appointment_id INT NULL, " +
                         "ai_summary NVARCHAR(MAX) NOT NULL, " +
                         "created_at DATETIME DEFAULT GETDATE()); END");
        } catch (Exception ignored) {}

        // Attempt 3: Insert into AI_Summary with UUID summary_id
        String summaryId = UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        String sql1 = "INSERT INTO AI_Summary (summary_id, patient_id, appointment_id, ai_summary, created_at) "
                + "VALUES (?, ?, NULL, ?, GETDATE())";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql1)) {
            ps.setString(1, summaryId);
            ps.setInt(2, patientId);
            ps.setString(3, aiSummary);
            ps.executeUpdate();
            return;
        } catch (Exception e1) {
            System.err.println("Notice: AI_Summary insert with summary_id failed: " + e1.getMessage());
        }

        // Attempt 4: Insert into AI_Summary without summary_id (in case summary_id is identity int)
        String sql2 = "INSERT INTO AI_Summary (patient_id, appointment_id, ai_summary, created_at) "
                + "VALUES (?, NULL, ?, GETDATE())";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql2)) {
            ps.setInt(1, patientId);
            ps.setString(2, aiSummary);
            ps.executeUpdate();
            return;
        } catch (Exception e2) {
            System.err.println("Notice: AI_Summary insert without summary_id failed: " + e2.getMessage());
        }

        // Attempt 5: Fallback to AI_Conversation table if present
        try {
            com.diabetes.monitoring.doctor.dao.AIConversationDAO dao = new com.diabetes.monitoring.doctor.dao.AIConversationDAO();
            dao.saveLatestConversation(patientId, history, aiSummary);
        } catch (Exception e3) {
            System.err.println("Notice: AIConversationDAO fallback failed: " + e3.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  HELPERS
    // ──────────────────────────────────────────────────────────────
    private int resolvePatientId(int accountId) throws SQLException, ChatAccessException {
        String sql = "SELECT patient_id FROM Patient WHERE account_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new ChatAccessException(HttpServletResponse.SC_NOT_FOUND,
                            "Kh\u00f4ng t\u00ecm th\u1ea5y h\u1ed3 s\u01a1 b\u1ec7nh nh\u00e2n.");
                }
                return rs.getInt("patient_id");
            }
        }
    }

    private String requireMessage(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Tin nh\u1eafn kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng.");
        }
        String msg = value.trim();
        if (msg.length() > 2000) {
            throw new IllegalArgumentException("Tin nh\u1eafn kh\u00f4ng \u0111\u01b0\u1ee3c v\u01b0\u1ee3t qu\u00e1 2000 k\u00fd t\u1ef1.");
        }
        return msg;
    }

    private String normalizeAiJson(String aiResponse) {
        String clean = nullToEmpty(aiResponse).trim();
        if (clean.startsWith("{") && clean.endsWith("}")) return clean;
        return "{\"reply\":\"" + escapeJson(clean) + "\"}";
    }

    private String extractJsonString(String json, String key) {
        String search = "\"" + key + "\"";
        int keyIndex = json.indexOf(search);
        if (keyIndex < 0) return "";
        int colonIndex = json.indexOf(':', keyIndex + search.length());
        int startQuote = colonIndex < 0 ? -1 : json.indexOf('"', colonIndex + 1);
        if (startQuote < 0) return "";

        StringBuilder value = new StringBuilder();
        boolean escaped = false;
        for (int i = startQuote + 1; i < json.length(); i++) {
            char c = json.charAt(i);
            if (escaped) {
                if (c == 'n') value.append('\n');
                else if (c == 'r') value.append('\r');
                else if (c == 't') value.append('\t');
                else value.append(c);
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                break;
            } else {
                value.append(c);
            }
        }
        return value.toString().trim();
    }

    private String trimHistory(String history) {
        return history.length() > 8000 ? history.substring(history.length() - 8000) : history;
    }

    private String fallbackSummary(String history) {
        String compact = history.replaceAll("\\s+", " ").trim();
        return compact.length() > 1500 ? compact.substring(compact.length() - 1500) : compact;
    }

    private void writeError(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.getWriter().print("{\"error\":\"" + escapeJson(message) + "\"}");
    }

    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static class ChatAccessException extends Exception {
        private final int status;
        private ChatAccessException(int status, String message) {
            super(message);
            this.status = status;
        }
    }
}
