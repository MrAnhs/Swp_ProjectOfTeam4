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
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
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

    private void saveAiSummaryToDatabase(int patientId, String aiSummary, String symptoms, String history) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            boolean hasAiSummaryTable = false;
            boolean hasAiConvTable = false;

            try (ResultSet rs = conn.getMetaData().getTables(null, null, "AI_Summary", null)) {
                if (rs.next()) hasAiSummaryTable = true;
            }
            try (ResultSet rs = conn.getMetaData().getTables(null, null, "AI_Conversation", null)) {
                if (rs.next()) hasAiConvTable = true;
            }

            if (!hasAiSummaryTable && !hasAiConvTable) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute("CREATE TABLE AI_Summary (" +
                                 "summary_id INT IDENTITY(1,1) PRIMARY KEY, " +
                                 "patient_id INT NOT NULL, " +
                                 "ai_summary NVARCHAR(MAX) NULL, " +
                                 "created_at DATETIME DEFAULT GETDATE())");
                    hasAiSummaryTable = true;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            String targetTable = hasAiSummaryTable ? "AI_Summary" : "AI_Conversation";

            Set<String> existingColumns = new HashSet<>();
            try (ResultSet rs = conn.getMetaData().getColumns(null, null, targetTable, null)) {
                while (rs.next()) {
                    existingColumns.add(rs.getString("COLUMN_NAME").toLowerCase());
                }
            }

            List<String> colNames = new ArrayList<>();
            List<Object> values = new ArrayList<>();

            if (existingColumns.contains("summary_id") && isVarcharColumn(conn, targetTable, "summary_id")) {
                colNames.add("summary_id");
                values.add(UUID.randomUUID().toString().replace("-", "").substring(0, 20));
            }

            if (existingColumns.contains("patient_id")) {
                colNames.add("patient_id");
                values.add(patientId);
            }

            if (existingColumns.contains("ai_summary")) {
                colNames.add("ai_summary");
                values.add(aiSummary);
            } else if (existingColumns.contains("symptoms")) {
                colNames.add("symptoms");
                values.add(aiSummary);
            }

            if (existingColumns.contains("symptoms") && !colNames.contains("symptoms") && !symptoms.isBlank()) {
                colNames.add("symptoms");
                values.add(symptoms);
            }

            if (existingColumns.contains("chat_history") && !history.isBlank()) {
                colNames.add("chat_history");
                values.add(history);
            }

            if (existingColumns.contains("created_at")) {
                colNames.add("created_at");
                values.add("GETDATE()");
            }

            StringBuilder sql = new StringBuilder("INSERT INTO ").append(targetTable).append(" (");
            StringBuilder valPlaceholders = new StringBuilder();

            int paramCount = 0;
            for (int i = 0; i < colNames.size(); i++) {
                if (i > 0) {
                    sql.append(", ");
                    valPlaceholders.append(", ");
                }
                sql.append(colNames.get(i));
                if ("created_at".equalsIgnoreCase(colNames.get(i))) {
                    valPlaceholders.append("GETDATE()");
                } else {
                    valPlaceholders.append("?");
                    paramCount++;
                }
            }
            sql.append(") VALUES (").append(valPlaceholders).append(")");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                int paramIdx = 1;
                for (int i = 0; i < colNames.size(); i++) {
                    if (!"created_at".equalsIgnoreCase(colNames.get(i))) {
                        ps.setObject(paramIdx++, values.get(i));
                    }
                }
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    System.out.println("[AIChatServlet] Summary inserted successfully into " + targetTable);
                    return;
                }
            } catch (SQLException ex) {
                System.err.println("[AIChatServlet] Dynamic insert into " + targetTable + " failed: " + ex.getMessage());
                throw ex;
            }
        }
    }

    private boolean isVarcharColumn(Connection conn, String tableName, String colName) {
        try (ResultSet rs = conn.getMetaData().getColumns(null, null, tableName, colName)) {
            if (rs.next()) {
                String typeName = rs.getString("TYPE_NAME");
                return typeName != null && (typeName.toLowerCase().contains("char") || typeName.toLowerCase().contains("text"));
            }
        } catch (Exception ignored) {}
        return false;
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
