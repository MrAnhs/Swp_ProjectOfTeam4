package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@MultipartConfig
public class SubmitHealthRecordServlet extends HttpServlet {

    private static final String HARD_LIMIT_MESSAGE =
            "Giá trị này nằm ngoài phạm vi sinh lý của con người, vui lòng kiểm tra lại.";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        Integer patientId = findPatientId(currentUser);
        if (patientId == null) {
            response.setStatus(404);
            response.getWriter().print("{\"error\":\"Patient not found\"}");
            return;
        }

        // Read form parameters
        String ureaStr = request.getParameter("urea");
        String creatinineStr = request.getParameter("creatinine");
        String hba1cStr = request.getParameter("hba1c");
        String cholesterolStr = request.getParameter("cholesterol");
        String tgStr = request.getParameter("tg");
        String hdlStr = request.getParameter("hdl");
        String ldlStr = request.getParameter("ldl");
        String vldlStr = request.getParameter("vldl");
        String weightStr = request.getParameter("weight");
        String heightStr = request.getParameter("height");
        String symptoms = trimToNull(request.getParameter("symptoms"));
        String chatHistory = request.getParameter("chatHistory");

        BigDecimal urea = parseDecimal(ureaStr);
        BigDecimal creatinine = parseDecimal(creatinineStr);
        BigDecimal hba1c = parseDecimal(hba1cStr);
        BigDecimal cholesterol = parseDecimal(cholesterolStr);
        BigDecimal tg = parseDecimal(tgStr);
        BigDecimal hdl = parseDecimal(hdlStr);
        BigDecimal ldl = parseDecimal(ldlStr);
        BigDecimal vldl = parseDecimal(vldlStr);
        BigDecimal weight = parseDecimal(weightStr);
        BigDecimal height = parseDecimal(heightStr);
        BigDecimal bmi = calculateBMI(weight, height);

        String validationError = validateHealthData(
                ureaStr, creatinineStr, hba1cStr, cholesterolStr, tgStr, hdlStr, ldlStr, vldlStr,
                weightStr, heightStr, urea, creatinine, hba1c, cholesterol, tg, hdl, ldl, vldl, weight, height);
        if (validationError != null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"" + escapeJson(validationError) + "\"}");
            return;
        }

        if (allHealthDataEmpty(urea, creatinine, hba1c, cholesterol, tg, hdl, ldl, vldl,
                weight, height, symptoms)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Health record must contain at least one health value or symptom\"}");
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction
            
            // Insert into Healthy_Record first
            String sql = "INSERT INTO Healthy_Record (urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, patient_id, weight, height, other_information, status, created_at) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', GETDATE())";

            int healthRecordId = -1;
            try (PreparedStatement stmt = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                stmt.setBigDecimal(1, urea);
                stmt.setBigDecimal(2, creatinine);
                stmt.setBigDecimal(3, hba1c);
                stmt.setBigDecimal(4, cholesterol);
                stmt.setBigDecimal(5, tg);
                stmt.setBigDecimal(6, hdl);
                stmt.setBigDecimal(7, ldl);
                stmt.setBigDecimal(8, vldl);
                stmt.setBigDecimal(9, bmi);
                stmt.setInt(10, patientId);
                stmt.setBigDecimal(11, weight);
                stmt.setBigDecimal(12, height);
                stmt.setString(13, symptoms);

                int rows = stmt.executeUpdate();

                if (rows > 0) {
                    // Get the generated health_record_id
                    try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                        if (generatedKeys.next()) {
                            healthRecordId = generatedKeys.getInt(1);
                        }
                    }
                }
            }

            // Link existing AI_Conversation record where health_record_id IS NULL to the new healthRecordId
            boolean updatedActiveSummary = false;
            if (healthRecordId > 0) {
                String updateSummarySql = "UPDATE AI_Conversation SET health_record_id = ?, created_at = GETDATE() " +
                                         "WHERE patient_id = ? AND health_record_id IS NULL";
                try (PreparedStatement updateStmt = conn.prepareStatement(updateSummarySql)) {
                    updateStmt.setInt(1, healthRecordId);
                    updateStmt.setInt(2, patientId);
                    int rowsUpdated = updateStmt.executeUpdate();
                    if (rowsUpdated > 0) {
                        updatedActiveSummary = true;
                    }
                }
            }

            // If no active AI chat summary was linked, but symptoms are provided in the submission,
            // we can create a record in AI_Conversation with only the symptoms summary and no chat history.
            if (healthRecordId > 0 && !updatedActiveSummary && symptoms != null && !symptoms.trim().isEmpty()) {
                String insertSummarySql = "INSERT INTO AI_Conversation (patient_id, health_record_id, chat_history, AI_Conversation, created_at) " +
                                         "VALUES (?, ?, NULL, ?, GETDATE())";
                try (PreparedStatement insertStmt = conn.prepareStatement(insertSummarySql)) {
                    insertStmt.setInt(1, patientId);
                    insertStmt.setInt(2, healthRecordId);
                    insertStmt.setString(3, symptoms.trim());
                    insertStmt.executeUpdate();
                }
            }

            // Clear session chat history for this patient since the session has ended
            request.getSession().removeAttribute("chatHistory_" + patientId);

            conn.commit(); // Commit transaction

            if (healthRecordId > 0) {
                try (PrintWriter out = response.getWriter()) {
                    out.print("{\"success\":true,\"message\":\"Hồ sơ sức khỏe đã được lưu thành công!\",\"healthRecordId\":" + healthRecordId + "}");
                }
            } else {
                response.setStatus(500);
                response.getWriter().print("{\"error\":\"Failed to save health record\"}");
            }
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    rollbackError.printStackTrace();
                }
            }
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Database error: " + escapeJson(e.getMessage()) + "\"}");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException closeError) {
                    closeError.printStackTrace();
                }
            }
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

    private BigDecimal parseDecimal(String value) {
        if (value == null || value.trim().isEmpty() || value.equals("-")) {
            return null;
        }
        try {
            return new BigDecimal(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private BigDecimal calculateBMI(BigDecimal weight, BigDecimal height) {
        if (weight == null || height == null || height.compareTo(BigDecimal.ZERO) == 0) {
            return null;
        }
        BigDecimal heightInMeters = height.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        BigDecimal heightSquared = heightInMeters.multiply(heightInMeters);
        return weight.divide(heightSquared, 2, RoundingMode.HALF_UP);
    }

    private String validateHealthData(String ureaRaw, String creatinineRaw, String hba1cRaw,
            String cholesterolRaw, String tgRaw, String hdlRaw, String ldlRaw, String vldlRaw,
            String weightRaw, String heightRaw, BigDecimal urea, BigDecimal creatinine,
            BigDecimal hba1c, BigDecimal cholesterol, BigDecimal tg, BigDecimal hdl,
            BigDecimal ldl, BigDecimal vldl, BigDecimal weight, BigDecimal height) {
        String invalidNumber = firstInvalidNumber(
                new String[]{"Urea", "Creatinine", "HbA1c", "Cholesterol", "Triglycerides",
                    "HDL", "LDL", "VLDL", "Cân nặng", "Chiều cao"},
                new String[]{ureaRaw, creatinineRaw, hba1cRaw, cholesterolRaw, tgRaw,
                    hdlRaw, ldlRaw, vldlRaw, weightRaw, heightRaw});
        if (invalidNumber != null) {
            return invalidNumber;
        }

        if (outsideInclusive(urea, "0.5", "60")) return "Urea: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(creatinine, "10", "2000")) return "Creatinine: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(hba1c, "2", "25")) return "HbA1c: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(cholesterol, "0.5", "25")) return "Cholesterol: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(tg, "0.1", "50")) return "Triglycerides: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(hdl, "0.1", "5")) return "HDL: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(ldl, "0.1", "15")) return "LDL: " + HARD_LIMIT_MESSAGE;
        if (outsideInclusive(vldl, "0.05", "10")) return "VLDL: " + HARD_LIMIT_MESSAGE;
        if (outsideExclusiveMin(weight, BigDecimal.ZERO, new BigDecimal("800"))) {
            return "Cân nặng: " + HARD_LIMIT_MESSAGE;
        }
        if (outsideExclusiveMin(height, BigDecimal.ZERO, new BigDecimal("300"))) {
            return "Chiều cao: " + HARD_LIMIT_MESSAGE;
        }
        return null;
    }

    private String firstInvalidNumber(String[] labels, String[] values) {
        for (int i = 0; i < values.length; i++) {
            String value = values[i];
            if (value != null && !value.trim().isEmpty() && parseDecimal(value) == null) {
                return labels[i] + ": Giá trị phải là một số hợp lệ.";
            }
        }
        return null;
    }

    private boolean outsideInclusive(BigDecimal value, String min, String max) {
        return value != null && (value.compareTo(new BigDecimal(min)) < 0
                || value.compareTo(new BigDecimal(max)) > 0);
    }

    private boolean outsideExclusiveMin(BigDecimal value, BigDecimal min, BigDecimal max) {
        return value != null && (value.compareTo(min) <= 0 || value.compareTo(max) > 0);
    }

    private boolean allHealthDataEmpty(BigDecimal urea, BigDecimal creatinine, BigDecimal hba1c,
            BigDecimal cholesterol, BigDecimal tg, BigDecimal hdl, BigDecimal ldl, BigDecimal vldl,
            BigDecimal weight, BigDecimal height, String symptoms) {
        return urea == null && creatinine == null && hba1c == null && cholesterol == null
                && tg == null && hdl == null && ldl == null && vldl == null
                && weight == null && height == null && symptoms == null;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
