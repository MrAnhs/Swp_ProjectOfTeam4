package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.GeminiIntegration;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class AIChatServlet extends HttpServlet {
    private static final String PENDING_ABNORMAL_MESSAGE = "pendingAbnormalHealthMessage";
    private final GeminiIntegration geminiIntegration = new GeminiIntegration();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        String message = request.getParameter("message");
        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (message == null || message.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().print("{\"error\":\"Message is required\"}");
            return;
        }

        String userName = currentUser.getFullName();
        Integer patientId = findPatientId(currentUser);
        if (patientId == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().print("{\"error\":\"Patient not found\"}");
            return;
        }

        String conversationHistory = getConversationHistory(request, patientId);
        int turnCount = 0;
        int idx = 0;
        while ((idx = conversationHistory.indexOf("Patient:", idx)) != -1) {
            turnCount++;
            idx += "Patient:".length();
        }
        if (turnCount >= 10) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            String limitMsg = "Bạn đã đạt giới hạn 10 lượt trao đổi tin nhắn với Trợ lý AI trong phiên này. Vui lòng bấm nút 'Tạo hồ sơ từ cuộc trò chuyện' ở bên phải để gửi thông tin triệu chứng cho bác sĩ.";
            response.getWriter().print("{\"reply\":\"" + escapeJson(limitMsg) + "\",\"reachedLimit\":true,\"healthData\":{\"urea\":0,\"cr\":0,\"hba1c\":0,\"chol\":0,\"bmi\":0,\"tg\":0,\"hdl\":0,\"ldl\":0,\"vldl\":0,\"weight\":0,\"height\":0,\"symptoms\":\"\"}}");
            return;
        }

        String effectiveMessage = message.trim();
        String pendingMessage = (String) request.getSession().getAttribute(PENDING_ABNORMAL_MESSAGE);
        if (pendingMessage != null && isAffirmativeConfirmation(effectiveMessage)) {
            effectiveMessage = pendingMessage + "\nBệnh nhân đã xác nhận các chỉ số trên là chính xác.";
            request.getSession().removeAttribute(PENDING_ABNORMAL_MESSAGE);
        } else {
            request.getSession().removeAttribute(PENDING_ABNORMAL_MESSAGE);
            String confirmationQuestion = buildAbnormalValueConfirmation(effectiveMessage);
            if (confirmationQuestion != null) {
                request.getSession().setAttribute(PENDING_ABNORMAL_MESSAGE, effectiveMessage);
                String jsonReply = createFallbackJson(confirmationQuestion);
                saveAiState(request, patientId, message, jsonReply);
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().print(jsonReply);
                return;
            }
        }

        String currentHealthContext = getCurrentHealthContext(patientId);
        String promptWithContext = "User Name: " + userName
                + "\nPatient ID: " + patientId
                + "\nSaved health data:\n" + currentHealthContext
                + "\nPrevious conversation:\n" + conversationHistory
                + "\nCurrent message: " + effectiveMessage
                + "\nInstruction: Continue the conversation using previous information. If lab test indicators are missing, ask for diabetes-related symptoms and return symptoms in healthData.symptoms.";
        String aiReply = geminiIntegration.getChatResponse(promptWithContext);

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        try (PrintWriter out = response.getWriter()) {
            String cleanReply = aiReply.trim();
            String jsonReply;

            if (cleanReply.startsWith("{") && cleanReply.endsWith("}")) {
                jsonReply = cleanReply;
            } else {
                jsonReply = createFallbackJson(cleanReply);
            }
            jsonReply = unwrapNestedReply(jsonReply);
            saveAiState(request, patientId, message, jsonReply);
            jsonReply = mergeHealthSummary(patientId, jsonReply);
            out.print(jsonReply);
        }
    }

    private String buildAbnormalValueConfirmation(String message) {
        StringBuilder abnormalValues = new StringBuilder();
        appendIfAbove(abnormalValues, message, "HbA1c", "hba1c", 10.0, "%");
        appendGlucoseIfHigh(abnormalValues, message);
        appendTriglycerideIfHigh(abnormalValues, message);
        appendIfAbove(abnormalValues, message, "Creatinine", "creatinine|cr", 500.0, "μmol/L");

        if (abnormalValues.length() == 0) return null;
        return "Tôi thấy " + abnormalValues
                + " đang ở mức rất cao. Bạn vui lòng kiểm tra lại và xác nhận giá trị cùng đơn vị đã nhập đúng chưa? "
                + "Nếu đúng, hãy trả lời \"Đúng\" để tôi tiếp tục hỗ trợ.";
    }

    private void appendGlucoseIfHigh(StringBuilder result, String message) {
        Pattern pattern = Pattern.compile(
                "(?iu)(?:đường\\s*huyết(?:\\s*lúc\\s*đói|\\s*đói)?|glucose(?:\\s*lúc\\s*đói)?)"
                + "[^0-9]{0,35}(\\d+(?:[.,]\\d+)?)\\s*(mg/dl|mmol/l)?");
        Matcher matcher = pattern.matcher(message);
        if (!matcher.find()) return;

        double value = parseNumber(matcher.group(1));
        String unit = matcher.group(2);
        boolean mmol = unit != null && unit.toLowerCase(Locale.ROOT).startsWith("mmol");
        if ((mmol && value >= 13.9) || (!mmol && value >= 250)) {
            appendAbnormalValue(result, "đường huyết " + matcher.group(1)
                    + " " + (unit == null ? "mg/dL" : unit));
        }
    }

    private void appendTriglycerideIfHigh(StringBuilder result, String message) {
        Pattern pattern = Pattern.compile(
                "(?iu)(?:triglyceride|triglycerides|tg)[^0-9]{0,35}"
                + "(\\d+(?:[.,]\\d+)?)\\s*(mg/dl|mmol/l)?");
        Matcher matcher = pattern.matcher(message);
        if (!matcher.find()) return;

        double value = parseNumber(matcher.group(1));
        String unit = matcher.group(2);
        boolean mgDl = unit != null && unit.toLowerCase(Locale.ROOT).startsWith("mg");
        if ((mgDl && value >= 500) || (!mgDl && value >= 5.6)) {
            appendAbnormalValue(result, "Triglyceride " + matcher.group(1)
                    + " " + (unit == null ? "mmol/L" : unit));
        }
    }

    private void appendIfAbove(StringBuilder result, String message, String displayName,
            String labelPattern, double threshold, String defaultUnit) {
        Pattern pattern = Pattern.compile("(?iu)(?:" + labelPattern + ")[^0-9]{0,35}"
                + "(\\d+(?:[.,]\\d+)?)\\s*([%a-zA-Zμ/]+)?");
        Matcher matcher = pattern.matcher(message);
        if (matcher.find() && parseNumber(matcher.group(1)) >= threshold) {
            String unit = matcher.group(2);
            appendAbnormalValue(result, displayName + " " + matcher.group(1)
                    + " " + (unit == null ? defaultUnit : unit));
        }
    }

    private void appendAbnormalValue(StringBuilder result, String value) {
        if (result.length() > 0) result.append(" và ");
        result.append(value);
    }

    private double parseNumber(String value) {
        try {
            return Double.parseDouble(value.replace(',', '.'));
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private boolean isAffirmativeConfirmation(String message) {
        String normalized = message.toLowerCase(Locale.ROOT).trim();
        return normalized.equals("đúng") || normalized.equals("đúng rồi")
                || normalized.equals("chính xác") || normalized.equals("phải")
                || normalized.equals("yes") || normalized.equals("ok");
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

    private String getCurrentHealthContext(int patientId) {
        StringBuilder context = new StringBuilder();
        String patientSql = "SELECT full_name, date_of_birth, gender FROM Patient WHERE patient_id = ?";
        String healthRecordSql = "SELECT TOP 1 urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, " +
                "weight, height, other_information, created_at FROM Healthy_Record " +
                "WHERE patient_id = ? ORDER BY created_at DESC, health_record_id DESC";
        try (Connection connection = DatabaseConnection.getConnection()) {
            try (PreparedStatement statement = connection.prepareStatement(patientSql)) {
                statement.setInt(1, patientId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        context.append("Patient: ").append(nullToEmpty(resultSet.getString("full_name")))
                               .append(", DOB: ").append(nullToEmpty(resultSet.getString("date_of_birth")))
                               .append(", Gender: ").append(nullToEmpty(resultSet.getString("gender"))).append("\n");
                    }
                }
            }
            try (PreparedStatement statement = connection.prepareStatement(healthRecordSql)) {
                statement.setInt(1, patientId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        context.append("Latest health record: created_at=").append(nullToEmpty(resultSet.getString("created_at")))
                               .append(", urea=").append(nullToEmpty(resultSet.getString("urea")))
                               .append(", cr=").append(nullToEmpty(resultSet.getString("cr")))
                               .append(", hba1c=").append(nullToEmpty(resultSet.getString("hba1c")))
                               .append(", chol=").append(nullToEmpty(resultSet.getString("chol")))
                               .append(", tg=").append(nullToEmpty(resultSet.getString("tg")))
                               .append(", hdl=").append(nullToEmpty(resultSet.getString("hdl")))
                               .append(", ldl=").append(nullToEmpty(resultSet.getString("ldl")))
                               .append(", vldl=").append(nullToEmpty(resultSet.getString("vldl")))
                               .append(", bmi=").append(nullToEmpty(resultSet.getString("bmi")))
                               .append(", weight=").append(nullToEmpty(resultSet.getString("weight")))
                               .append(", height=").append(nullToEmpty(resultSet.getString("height")))
                               .append(", symptoms=").append(nullToEmpty(resultSet.getString("other_information"))).append("\n");
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return context.length() == 0 ? "No saved patient/lab data found." : context.toString();
    }

    private String getConversationHistory(HttpServletRequest request, int patientId) {
        String history = (String) request.getSession().getAttribute("chatHistory_" + patientId);
        return history == null ? "" : history;
    }

    private void saveAiState(HttpServletRequest request, int patientId, String userMessage, String aiJson) {
        String oldHistory = getConversationHistory(request, patientId);
        String reply = extractJsonString(aiJson, "reply");
        String newHistory = trimHistory(oldHistory + "\nPatient: " + nullToEmpty(userMessage) + "\nAI: " + reply);
        request.getSession().setAttribute("chatHistory_" + patientId, newHistory);

        String symptoms = extractJsonString(aiJson, "symptoms");
        if (symptoms == null) {
            symptoms = "";
        }

        String checkSql = "SELECT COUNT(*) FROM AI_Conversation WHERE patient_id = ? AND health_record_id IS NULL";
        String updateSql = "UPDATE AI_Conversation SET AI_Conversation = ?, created_at = GETDATE() WHERE patient_id = ? AND health_record_id IS NULL";
        String insertSql = "INSERT INTO AI_Conversation (patient_id, AI_Conversation, created_at) VALUES (?, ?, GETDATE())";

        try (Connection connection = DatabaseConnection.getConnection()) {
            boolean exists = false;
            try (PreparedStatement checkStmt = connection.prepareStatement(checkSql)) {
                checkStmt.setInt(1, patientId);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        exists = true;
                    }
                }
            }
            if (exists) {
                try (PreparedStatement updateStmt = connection.prepareStatement(updateSql)) {
                    updateStmt.setString(1, symptoms);
                    updateStmt.setInt(2, patientId);
                    updateStmt.executeUpdate();
                }
            } else {
                try (PreparedStatement insertStmt = connection.prepareStatement(insertSql)) {
                    insertStmt.setInt(1, patientId);
                    insertStmt.setString(2, symptoms);
                    insertStmt.executeUpdate();
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private String mergeHealthSummary(int patientId, String aiJson) {
        BigDecimal urea = extractJsonDecimal(aiJson, "urea");
        BigDecimal cr = extractJsonDecimal(aiJson, "cr");
        BigDecimal hba1c = extractJsonDecimal(aiJson, "hba1c");
        BigDecimal chol = extractJsonDecimal(aiJson, "chol");
        BigDecimal bmi = extractJsonDecimal(aiJson, "bmi");
        BigDecimal tg = extractJsonDecimal(aiJson, "tg");
        BigDecimal hdl = extractJsonDecimal(aiJson, "hdl");
        BigDecimal ldl = extractJsonDecimal(aiJson, "ldl");
        BigDecimal vldl = extractJsonDecimal(aiJson, "vldl");
        BigDecimal weight = extractJsonDecimal(aiJson, "weight");
        BigDecimal height = extractJsonDecimal(aiJson, "height");
        String symptoms = extractJsonString(aiJson, "symptoms");
        String healthRecordSql = "SELECT TOP 1 urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, " +
                "weight, height, other_information FROM Healthy_Record WHERE patient_id = ? " +
                "ORDER BY created_at DESC, health_record_id DESC";
        try (Connection connection = DatabaseConnection.getConnection()) {
            try (PreparedStatement statement = connection.prepareStatement(healthRecordSql)) {
                statement.setInt(1, patientId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        if (isEmptyNumber(urea)) urea = resultSet.getBigDecimal("urea");
                        if (isEmptyNumber(cr)) cr = resultSet.getBigDecimal("cr");
                        if (isEmptyNumber(hba1c)) hba1c = resultSet.getBigDecimal("hba1c");
                        if (isEmptyNumber(chol)) chol = resultSet.getBigDecimal("chol");
                        if (isEmptyNumber(bmi)) bmi = resultSet.getBigDecimal("bmi");
                        if (isEmptyNumber(tg)) tg = resultSet.getBigDecimal("tg");
                        if (isEmptyNumber(hdl)) hdl = resultSet.getBigDecimal("hdl");
                        if (isEmptyNumber(ldl)) ldl = resultSet.getBigDecimal("ldl");
                        if (isEmptyNumber(vldl)) vldl = resultSet.getBigDecimal("vldl");
                        if (isEmptyNumber(weight)) weight = resultSet.getBigDecimal("weight");
                        if (isEmptyNumber(height)) height = resultSet.getBigDecimal("height");
                        if (symptoms.isEmpty()) symptoms = nullToEmpty(resultSet.getString("other_information"));
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        String reply = cleanReplyText(extractJsonString(aiJson, "reply"));
        return "{\"reply\":\"" + escapeJson(reply) + "\",\"healthData\":{\"urea\":" + numberToJson(urea)
                + ",\"cr\":" + numberToJson(cr)
                + ",\"hba1c\":" + numberToJson(hba1c)
                + ",\"chol\":" + numberToJson(chol)
                + ",\"bmi\":" + numberToJson(bmi)
                + ",\"tg\":" + numberToJson(tg)
                + ",\"hdl\":" + numberToJson(hdl)
                + ",\"ldl\":" + numberToJson(ldl)
                + ",\"vldl\":" + numberToJson(vldl)
                + ",\"weight\":" + numberToJson(weight)
                + ",\"height\":" + numberToJson(height)
                + ",\"symptoms\":\"" + escapeJson(symptoms) + "\"}}";
    }

    private String unwrapNestedReply(String json) {
        String current = json == null ? "" : json.trim();
        for (int i = 0; i < 2; i++) {
            String nestedReply = extractJsonString(current, "reply").trim();
            if (!nestedReply.startsWith("{") || !nestedReply.endsWith("}")
                    || !nestedReply.contains("\"reply\"")) {
                break;
            }
            current = nestedReply;
        }
        return current.startsWith("{") && current.endsWith("}")
                ? current
                : createFallbackJson(current);
    }

    private String createFallbackJson(String reply) {
        return "{\"reply\":\"" + escapeJson(cleanReplyText(reply))
                + "\",\"healthData\":{\"urea\":0,\"cr\":0,\"hba1c\":0,\"chol\":0,"
                + "\"bmi\":0,\"tg\":0,\"hdl\":0,\"ldl\":0,\"vldl\":0,"
                + "\"weight\":0,\"height\":0,\"symptoms\":\"\"}}";
    }

    private String cleanReplyText(String reply) {
        if (reply == null) return "";
        String text = reply.trim()
                .replaceFirst("(?is)^```(?:json)?\\s*", "")
                .replaceFirst("(?is)\\s*```$", "");

        if (text.matches("(?is)^\\s*\\{\\s*\"reply\"\\s*:.*")) {
            text = text.replaceFirst("(?is)^\\s*\\{\\s*\"reply\"\\s*:\\s*\"", "")
                    .replaceFirst("(?is)\"\\s*,?\\s*\"healthData\"\\s*:[\\s\\S]*$", "")
                    .replaceFirst("(?is)\"\\s*}\\s*$", "");
        }

        text = text
                .replace("\\n", "\n")
                .replace("\\r", "")
                .replace("\\t", " ")
                .replace("**", "")
                .replace("__", "")
                .replace("`", "");

        StringBuilder cleaned = new StringBuilder();
        for (String line : text.split("\\R")) {
            String cleanLine = line.replaceFirst("\\\\+\\s*$", "").stripTrailing();
            if (cleanLine.isEmpty()) {
                if (cleaned.length() > 0 && cleaned.charAt(cleaned.length() - 1) != '\n') {
                    cleaned.append('\n');
                }
                continue;
            }
            if (cleaned.length() > 0) cleaned.append('\n');
            cleaned.append(cleanLine);
        }
        return cleaned.toString().replaceAll("\\n{3,}", "\n\n").trim();
    }

    private String extractJsonString(String json, String key) {
        String search = "\"" + key + "\"";
        int keyIndex = json.indexOf(search);
        if (keyIndex == -1) return "";
        int colonIndex = json.indexOf(":", keyIndex);
        int startQuote = json.indexOf("\"", colonIndex + 1);
        if (colonIndex == -1 || startQuote == -1) return "";
        StringBuilder value = new StringBuilder();
        boolean escaped = false;
        for (int i = startQuote + 1; i < json.length(); i++) {
            char c = json.charAt(i);
            if (escaped) {
                switch (c) {
                    case 'n':
                        value.append('\n');
                        break;
                    case 'r':
                        value.append('\r');
                        break;
                    case 't':
                        value.append('\t');
                        break;
                    case 'b':
                        value.append('\b');
                        break;
                    case 'f':
                        value.append('\f');
                        break;
                    default:
                        value.append(c);
                        break;
                }
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

    private BigDecimal extractJsonDecimal(String json, String key) {
        String search = "\"" + key + "\"";
        int keyIndex = json.indexOf(search);
        if (keyIndex == -1) return null;
        int colonIndex = json.indexOf(":", keyIndex);
        if (colonIndex == -1) return null;
        int start = colonIndex + 1;
        while (start < json.length() && Character.isWhitespace(json.charAt(start))) start++;
        int end = start;
        while (end < json.length() && "-0123456789.".indexOf(json.charAt(end)) >= 0) end++;
        try {
            return new BigDecimal(json.substring(start, end));
        } catch (Exception e) {
            return null;
        }
    }

    private String trimHistory(String history) {
        if (history == null) return "";
        return history.length() > 4000 ? history.substring(history.length() - 4000) : history;
    }

    private boolean isEmptyNumber(BigDecimal value) {
        return value == null || value.compareTo(BigDecimal.ZERO) == 0;
    }

    private String numberToJson(BigDecimal value) {
        if (value == null) return "0";
        return value.stripTrailingZeros().toPlainString();
    }

    private String escapeJson(String text) {
        if (text == null) return "";
        return text.replace("\\", "\\\\")
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
}
