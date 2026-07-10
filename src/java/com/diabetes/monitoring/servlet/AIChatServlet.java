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

public class AIChatServlet extends HttpServlet {
    private final GeminiIntegration geminiIntegration = new GeminiIntegration();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Bạn chưa đăng nhập.");
            return;
        }

        try {
            ChatContext context = resolveContext(currentUser.getId(),
                    parseOptionalPositiveId(request.getParameter("appointmentId")));
            String action = request.getParameter("action");
            if ("finish".equals(action)) {
                finishConversation(response, context);
                return;
            }

            String message = requireMessage(request.getParameter("message"));
            continueConversation(response, currentUser, context, message);
        } catch (IllegalArgumentException e) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (ChatAccessException e) {
            writeError(response, e.status, e.getMessage());
        } catch (SQLException e) {
            e.printStackTrace();
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không thể lưu cuộc trò chuyện.");
        }
    }

    private void continueConversation(HttpServletResponse response, User currentUser,
            ChatContext context, String message) throws SQLException, IOException {
        String history = getConversationHistory(context);
        String prompt = "Patient: " + currentUser.getFullName()
                + "\nAppointment ID: " + (context.appointmentId == null ? "none" : context.appointmentId)
                + "\nDoctor: " + nullToEmpty(context.doctorName)
                + "\nPrevious conversation:\n" + history
                + "\nCurrent patient message: " + message
                + "\nInstruction: Continue asking useful questions about symptoms, duration, severity, "
                + "medical history and current medication so the assigned doctor can understand the patient.";

        String aiJson = normalizeAiJson(geminiIntegration.getChatResponse(prompt));
        String reply = extractJsonString(aiJson, "reply");
        if (reply.isEmpty()) {
            reply = "Tôi chưa thể xử lý thông tin này. Bạn vui lòng mô tả rõ hơn.";
        }

        String newHistory = trimHistory(history + "\nPatient: " + message + "\nAI: " + reply);
        int conversationId = saveConversation(context, newHistory);
        response.getWriter().print("{\"reply\":\"" + escapeJson(reply)
                + "\",\"conversationId\":" + conversationId + "}");
    }

    private void finishConversation(HttpServletResponse response, ChatContext context)
            throws SQLException, IOException, ChatAccessException {
        String history = getConversationHistory(context);
        if (context.conversationId == null || history.isBlank()) {
            throw new ChatAccessException(HttpServletResponse.SC_CONFLICT,
                    "Cuộc trò chuyện chưa có nội dung để tổng hợp.");
        }

        String summaryPrompt = "Hãy tóm tắt ngắn gọn cuộc trò chuyện sau cho bác sĩ phụ trách. "
                + "Chỉ nêu triệu chứng, thời điểm, mức độ, tiền sử, thuốc đang dùng và thông tin quan trọng "
                + "mà bệnh nhân đã cung cấp. Không tự đưa ra chẩn đoán.\n\n" + history;
        String summaryJson = normalizeAiJson(geminiIntegration.getChatResponse(summaryPrompt));
        String summary = extractJsonString(summaryJson, "reply");
        if (summary.isEmpty()) {
            summary = fallbackSummary(history);
        }

        String sql = "UPDATE AI_Conversation SET ai_summary = ? WHERE conversation_id = ? AND patient_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, summary);
            statement.setInt(2, context.conversationId);
            statement.setInt(3, context.patientId);
            statement.executeUpdate();
        }

        response.getWriter().print("{\"success\":true,\"summary\":\""
                + escapeJson(summary) + "\"}");
    }

    private ChatContext resolveContext(int accountId, Integer appointmentId)
            throws SQLException, ChatAccessException {
        String patientSql = "SELECT patient_id FROM Patient WHERE account_id = ?";
        ChatContext context = new ChatContext();

        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(patientSql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new ChatAccessException(HttpServletResponse.SC_NOT_FOUND,
                            "Không tìm thấy hồ sơ bệnh nhân.");
                }
                context.patientId = resultSet.getInt("patient_id");
            }
        }

        context.appointmentId = appointmentId;
        try (Connection connection = DatabaseConnection.getConnection()) {
            boolean hasAppointmentConversation = hasColumn(connection, "Appointment", "conversation_id");
            if (appointmentId == null) {
                String generalConversationSql = hasAppointmentConversation
                        ? "SELECT TOP 1 c.conversation_id "
                        + "FROM AI_Conversation c "
                        + "WHERE c.patient_id = ? "
                        + "AND NOT EXISTS (SELECT 1 FROM Appointment a "
                        + "WHERE a.conversation_id = c.conversation_id) "
                        + "ORDER BY c.created_at DESC, c.conversation_id DESC"
                        : "SELECT TOP 1 c.conversation_id "
                        + "FROM AI_Conversation c "
                        + "WHERE c.patient_id = ? "
                        + "ORDER BY c.created_at DESC, c.conversation_id DESC";
                try (PreparedStatement statement = connection.prepareStatement(generalConversationSql)) {
                    statement.setInt(1, context.patientId);
                    try (ResultSet resultSet = statement.executeQuery()) {
                        if (resultSet.next()) {
                            context.conversationId = resultSet.getInt("conversation_id");
                        }
                    }
                }
                return context;
            }

            String appointmentSql = "SELECT "
                    + (hasAppointmentConversation ? "a.conversation_id" : "CAST(NULL AS int) AS conversation_id")
                    + ", d.full_name "
                    + "FROM Appointment a "
                    + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                    + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                    + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                    + "WHERE a.appointment_id = ? AND p.account_id = ? AND a.status <> 'Cancelled'";
            try (PreparedStatement statement = connection.prepareStatement(appointmentSql)) {
                statement.setInt(1, appointmentId);
                statement.setInt(2, accountId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (!resultSet.next()) {
                        throw new ChatAccessException(HttpServletResponse.SC_NOT_FOUND,
                                "Không tìm thấy lịch hẹn hoặc lịch đã bị hủy.");
                    }
                    int conversationId = resultSet.getInt("conversation_id");
                    context.conversationId = resultSet.wasNull() ? null : conversationId;
                    context.doctorName = resultSet.getString("full_name");
                }
            }
        }
        return context;
    }

    private String getConversationHistory(ChatContext context) throws SQLException {
        if (context.conversationId == null) {
            return "";
        }
        String sql = "SELECT chat_history FROM AI_Conversation "
                + "WHERE conversation_id = ? AND patient_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, context.conversationId);
            statement.setInt(2, context.patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? nullToEmpty(resultSet.getString("chat_history")) : "";
            }
        }
    }

    private int saveConversation(ChatContext context, String history) throws SQLException {
        Connection connection = null;
        try {
            connection = DatabaseConnection.getConnection();
            connection.setAutoCommit(false);

            if (context.conversationId != null) {
                String updateSql = "UPDATE AI_Conversation SET chat_history = ? "
                        + "WHERE conversation_id = ? AND patient_id = ?";
                try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                    statement.setString(1, history);
                    statement.setInt(2, context.conversationId);
                    statement.setInt(3, context.patientId);
                    if (statement.executeUpdate() == 0) {
                        throw new SQLException("Conversation not found");
                    }
                }
                connection.commit();
                return context.conversationId;
            }

            String insertSql = "INSERT INTO AI_Conversation "
                    + "(patient_id, chat_history, ai_summary, created_at) "
                    + "VALUES (?, ?, NULL, GETDATE())";
            int conversationId;
            try (PreparedStatement statement = connection.prepareStatement(insertSql,
                    Statement.RETURN_GENERATED_KEYS)) {
                statement.setInt(1, context.patientId);
                statement.setString(2, history);
                statement.executeUpdate();
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("Unable to retrieve conversation ID");
                    }
                    conversationId = keys.getInt(1);
                }
            }

            if (context.appointmentId != null && hasColumn(connection, "Appointment", "conversation_id")) {
                String appointmentSql = "UPDATE Appointment SET conversation_id = ? "
                        + "WHERE appointment_id = ? AND patient_id = ? AND conversation_id IS NULL";
                try (PreparedStatement statement = connection.prepareStatement(appointmentSql)) {
                    statement.setInt(1, conversationId);
                    statement.setInt(2, context.appointmentId);
                    statement.setInt(3, context.patientId);
                    if (statement.executeUpdate() == 0) {
                        throw new SQLException("Appointment conversation was changed concurrently");
                    }
                }
            }

            connection.commit();
            context.conversationId = conversationId;
            return conversationId;
        } catch (SQLException e) {
            if (connection != null) {
                try {
                    connection.rollback();
                } catch (SQLException rollbackError) {
                    rollbackError.printStackTrace();
                }
            }
            throw e;
        } finally {
            if (connection != null) {
                try {
                    connection.close();
                } catch (SQLException closeError) {
                    closeError.printStackTrace();
                }
            }
        }
    }

    private boolean hasColumn(Connection connection, String tableName, String columnName)
            throws SQLException {
        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS "
                + "WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, tableName);
            statement.setString(2, columnName);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }
    private Integer parseOptionalPositiveId(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        int id = Integer.parseInt(value);
        if (id <= 0) {
            throw new IllegalArgumentException("Mã lịch hẹn không hợp lệ.");
        }
        return id;
    }

    private String requireMessage(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Tin nhắn không được để trống.");
        }
        String message = value.trim();
        if (message.length() > 2000) {
            throw new IllegalArgumentException("Tin nhắn không được vượt quá 2000 ký tự.");
        }
        return message;
    }

    private String normalizeAiJson(String aiResponse) {
        String clean = nullToEmpty(aiResponse).trim();
        if (clean.startsWith("{") && clean.endsWith("}")) {
            return clean;
        }
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
        for (int index = startQuote + 1; index < json.length(); index++) {
            char current = json.charAt(index);
            if (escaped) {
                if (current == 'n') value.append('\n');
                else if (current == 'r') value.append('\r');
                else if (current == 't') value.append('\t');
                else value.append(current);
                escaped = false;
            } else if (current == '\\') {
                escaped = true;
            } else if (current == '"') {
                break;
            } else {
                value.append(current);
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

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
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

    private static class ChatContext {
        private int patientId;
        private Integer appointmentId;
        private Integer conversationId;
        private String doctorName;
    }

    private static class ChatAccessException extends Exception {
        private final int status;

        private ChatAccessException(int status, String message) {
            super(message);
            this.status = status;
        }
    }
}
