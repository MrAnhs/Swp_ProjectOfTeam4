package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Anti-Fraud Servlet - AI Giám sát hành vi & Phát hiện gian lận dữ liệu
 * URL Mapping: /admin-anti-fraud
 * 
 * Luồng xử lý:
 * 1. Admin gửi request quét hệ thống
 * 2. Lấy TOP 20 bản ghi mới nhất từ Healthy_Record (PreparedStatement)
 * 3. Gửi dữ liệu qua Gemini AI để phân tích spam/gian lận
 * 4. Trả về JSON: {has_anomaly, anomalies[]}
 * 5. Hỗ trợ ban patient qua action=banPatient
 */
public class AntiFraudServlet extends HttpServlet {
    
    private static final Logger LOGGER = Logger.getLogger(AntiFraudServlet.class.getName());
    
    // API Key nên được cấu hình qua environment variable hoặc config file
    private static final String GEMINI_API_KEY = System.getenv("GEMINI_API_KEY");
    private static final String GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("currentUser");
        
        // Kiểm tra quyền admin
        if (currentUser == null || !"Admin".equalsIgnoreCase(currentUser.getRole())) {
            sendJsonError(response, "Unauthorized access", 403);
            return;
        }
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Bước 1: Lấy TOP 20 bản ghi mới nhất từ Healthy_Record (PreparedStatement - không cộng chuỗi SQL)
            List<HealthRecordData> records = getLatestRecords(conn);
            
            if (records.isEmpty()) {
                sendJsonResponse(response, "{\"has_anomaly\": false, \"anomalies\": [], \"message\": \"Không có dữ liệu để phân tích\"}");
                return;
            }
            
            LOGGER.log(Level.INFO, "Phân tích {0} bản ghi để phát hiện gian lận", records.size());
            
            // Bước 2: Tạo prompt và gọi Gemini AI
            String prompt = createFraudDetectionPrompt(records);
            String geminiResponse;
            boolean isDemoMode = false;
            
            try {
                geminiResponse = callGeminiAPI(prompt);
            } catch (IOException e) {
                // Xử lý HTTP 429 - Rate Limit / Quota exceeded
                if (e.getMessage() != null && e.getMessage().contains("429")) {
                    LOGGER.log(Level.WARNING, "Gemini API quota exceeded (429) - Chuyển sang demo mode");
                    // Demo mode: Trả về dữ liệu mẫu thay vì lỗi
                    geminiResponse = generateDemoResponse(records);
                    isDemoMode = true;
                } else {
                    throw e; // Re-throw các lỗi khác
                }
            }
            
            // Bước 3: Trả về kết quả JSON cho frontend
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            
            // Thêm flag demo mode vào response nếu cần
            if (isDemoMode && geminiResponse.endsWith("}")) {
                geminiResponse = geminiResponse.substring(0, geminiResponse.length() - 1) + 
                    ", \"demo_mode\": true, \"message\": \"API quota exceeded - Hiển thị dữ liệu demo\"}";
            }
            
            response.getWriter().write(geminiResponse);
            
            LOGGER.log(Level.INFO, "Hoàn thành quét gian lận" + (isDemoMode ? " (DEMO MODE)" : ""));
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi database khi quét gian lận", e);
            sendJsonError(response, "Lỗi database: " + e.getMessage(), 500);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Lỗi API hoặc kết nối", e);
            sendJsonError(response, "Lỗi kết nối API: " + e.getMessage(), 503);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi xử lý quét gian lận", e);
            sendJsonError(response, "Lỗi hệ thống: " + e.getMessage(), 500);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("currentUser");
        
        // Kiểm tra quyền admin
        if (currentUser == null || !"Admin".equalsIgnoreCase(currentUser.getRole())) {
            sendJsonError(response, "Unauthorized access", 403);
            return;
        }
        
        String action = request.getParameter("action");
        LOGGER.log(Level.INFO, "doPost called - action: ''{0}'', patientId: ''{1}''", 
            new Object[]{action, request.getParameter("patientId")});

        if ("banPatient".equals(action)) {
            banPatient(request, response);
        } else {
            LOGGER.log(Level.WARNING, "Invalid action received: ''{0}''", action);
            sendJsonError(response, "Invalid action: " + action, 400);
        }
    }
    
    /**
     * Lấy TOP 20 bản ghi mới nhất từ Healthy_Record (PreparedStatement - không cộng chuỗi SQL)
     * Lọc bỏ patient đã bị ban (status = 'banned')
     */
    private List<HealthRecordData> getLatestRecords(Connection conn) throws SQLException {
        List<HealthRecordData> records = new ArrayList<>();
        
        // JOIN với Patient và Account để lọc bỏ patient bị banned
        String sql = "SELECT TOP 20 h.health_record_id, h.patient_id, h.other_information, h.created_at " +
                     "FROM Healthy_Record h " +
                     "JOIN Patient p ON h.patient_id = p.patient_id " +
                     "JOIN Account a ON p.account_id = a.account_id " +
                     "WHERE a.status != 'banned' " +
                     "ORDER BY h.created_at DESC";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                HealthRecordData record = new HealthRecordData();
                record.healthRecordId = rs.getInt("health_record_id");
                record.patientId = rs.getInt("patient_id");
                record.otherInformation = rs.getString("other_information");
                record.createdAt = rs.getTimestamp("created_at");
                records.add(record);
            }
        }
        
        return records;
    }
    
    /**
     * Tạo prompt cho Gemini AI để phát hiện gian lận/spam
     */
    private String createFraudDetectionPrompt(List<HealthRecordData> records) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append("Bạn là chuyên gia kiểm toán dữ liệu y tế. Hãy phân tích các bản ghi sau để phát hiện spam, ");
        prompt.append("dữ liệu rác, hoặc hành vi phá hoại (ví dụ: nhập 'asdasd', 'qwerty', ký tự vô nghĩa).\n\n");
        
        prompt.append("DANH SÁCH BẢN GHI CẦN PHÂN TÍCH:\n");
        for (HealthRecordData record : records) {
            prompt.append("- Record ID: ").append(record.healthRecordId)
                  .append(", Patient ID: ").append(record.patientId)
                  .append(", Nội dung: \"").append(escapeJson(record.otherInformation)).append("\"\n");
        }
        
        prompt.append("\nYÊU CẦU PHÂN TÍCH:\n");
        prompt.append("1. Phát hiện nội dung spam, vô nghĩa, hoặc đáng ngờ\n");
        prompt.append("2. Tìm pattern lạm dụng từ cùng một patient_id\n");
        prompt.append("3. Đánh dấu các bản ghi chứa ký tự ngẫu nhiên, không liên quan đến y tế\n\n");
        
        prompt.append("TRẢ VỀ KẾT QUẢ DẠNG JSON THUẦN (không dùng markdown code block):\n");
        prompt.append("{\n");
        prompt.append("  \"has_anomaly\": true/false,\n");
        prompt.append("  \"anomalies\": [\n");
        prompt.append("    {\n");
        prompt.append("      \"patient_id\": \"mã_bệnh_nhân\",\n");
        prompt.append("      \"record_id\": \"mã_hồ_sơ\",\n");
        prompt.append("      \"reason\": \"Lý do phát hiện bằng tiếng Việt\"\n");
        prompt.append("    }\n");
        prompt.append("  ]\n");
        prompt.append("}\n\n");
        prompt.append("Lưu ý: Chỉ trả về JSON thuần, không thêm text giải thích.");
        
        return prompt.toString();
    }
    
    /**
     * Gọi Gemini API để phân tích gian lận
     */
    private String callGeminiAPI(String prompt) throws IOException {
        // Kiểm tra API key
        if (GEMINI_API_KEY == null || GEMINI_API_KEY.isEmpty() || 
            GEMINI_API_KEY.equals("YOUR_GEMINI_API_KEY")) {
            
            LOGGER.log(Level.WARNING, "DEMO MODE - No valid Gemini API key configured");
            // Trả về kết quả demo để test UI
            return "{\"has_anomaly\": false, \"anomalies\": [], \"demo\": true, \"message\": \"Chế độ demo - chưa cấu hình API key\"}";
        }
        
        URL url = new URL(GEMINI_API_URL + "?key=" + GEMINI_API_KEY);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(30000); // 30 seconds timeout
        conn.setReadTimeout(30000);
        
        // Tạo request body
        String escapedPrompt = escapeJson(prompt);
        String requestBody = "{\"contents\": [{\"parts\": [{\"text\": \"" + escapedPrompt + "\"}]}]}";
        
        // Gửi request
        try (OutputStream os = conn.getOutputStream()) {
            byte[] input = requestBody.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);
        }
        
        // Đọc response
        int responseCode = conn.getResponseCode();
        if (responseCode == 200) {
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) {
                    response.append(line);
                }
                return extractJsonFromGeminiResponse(response.toString());
            }
        } else {
            // Đọc error message
            String errorBody = "";
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getErrorStream(), StandardCharsets.UTF_8))) {
                StringBuilder error = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) {
                    error.append(line);
                }
                errorBody = error.toString();
                LOGGER.log(Level.SEVERE, "Gemini API error: HTTP {0} - {1}", 
                        new Object[]{responseCode, errorBody});
            }
            // Throw rõ ràng HTTP status code để catch bên ngoài xử lý
            throw new IOException("Gemini API error: HTTP " + responseCode + " - " + errorBody);
        }
    }
    
    /**
     * Trích xuất JSON từ response của Gemini
     */
    private String extractJsonFromGeminiResponse(String geminiResponse) {
        try {
            // Tìm text trong response bằng regex
            java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"text\": \"([^\"]+)");
            java.util.regex.Matcher matcher = pattern.matcher(geminiResponse);
            if (matcher.find()) {
                String text = matcher.group(1)
                    .replace("\\n", "\n")
                    .replace("\\\"", "\"")
                    .replace("\\\\", "\\");
                // Tìm JSON trong text
                int start = text.indexOf("{");
                int end = text.lastIndexOf("}");
                if (start >= 0 && end > start) {
                    return text.substring(start, end + 1);
                }
            }
            
            // Nếu không tìm được theo pattern cũ, thử tìm JSON trực tiếp
            int start = geminiResponse.indexOf("{");
            int end = geminiResponse.lastIndexOf("}");
            if (start >= 0 && end > start) {
                String jsonCandidate = geminiResponse.substring(start, end + 1);
                // Kiểm tra xem có phải JSON hợp lệ không
                if (jsonCandidate.contains("has_anomaly")) {
                    return jsonCandidate;
                }
            }
            
            LOGGER.log(Level.WARNING, "Could not extract JSON from Gemini response");
            return "{\"has_anomaly\": false, \"anomalies\": [], \"error\": \"Không thể phân tích phản hồi từ AI\"}";
            
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error extracting JSON from Gemini response", e);
            return "{\"has_anomaly\": false, \"anomalies\": [], \"error\": \"Lỗi xử lý phản hồi\"}";
        }
    }
    
    /**
     * Ban patient bằng cách cập nhật status trong bảng Account (PreparedStatement)
     * Lấy account_id từ bảng Patient trước khi update
     */
    private void banPatient(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String patientIdStr = request.getParameter("patientId");
        LOGGER.log(Level.INFO, "Ban patient request received - raw patientId: ''{0}''", patientIdStr);

        if (patientIdStr == null || patientIdStr.isEmpty()) {
            LOGGER.log(Level.WARNING, "Missing patientId parameter");
            sendJsonError(response, "Missing patientId parameter", 400);
            return;
        }

        // Parse patient_id - loại bỏ # và các ký tự không phải số
        String cleanedId = patientIdStr.replaceAll("[^0-9]", "");
        LOGGER.log(Level.INFO, "Cleaned patientId: ''{0}'' (from raw: ''{1}'')", new Object[]{cleanedId, patientIdStr});

        if (cleanedId.isEmpty()) {
            LOGGER.log(Level.WARNING, "Invalid patientId format after cleaning: {0}", patientIdStr);
            sendJsonError(response, "Invalid patientId format: " + patientIdStr, 400);
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            int patientId = Integer.parseInt(cleanedId);
            LOGGER.log(Level.INFO, "Parsed patientId: {0}", patientId);

            // Step 1: Lấy account_id từ bảng Patient
            String selectSql = "SELECT account_id FROM Patient WHERE patient_id = ?";
            Integer accountId = null;

            try (PreparedStatement selectStmt = conn.prepareStatement(selectSql)) {
                selectStmt.setInt(1, patientId);
                try (ResultSet rs = selectStmt.executeQuery()) {
                    if (rs.next()) {
                        accountId = rs.getInt("account_id");
                    }
                }
            }

            LOGGER.log(Level.INFO, "Found account_id: {0} for patient_id: {1}", new Object[]{accountId, patientId});

            if (accountId == null || accountId == 0) {
                LOGGER.log(Level.WARNING, "Không tìm thấy patient_id: {0} trong bảng Patient", patientId);
                sendJsonError(response, "Không tìm thấy bệnh nhân với ID " + patientId, 404);
                return;
            }

            // Step 2: Update Account status
            String updateSql = "UPDATE Account SET status = 'banned' WHERE account_id = ?";

            try (PreparedStatement stmt = conn.prepareStatement(updateSql)) {
                stmt.setInt(1, accountId);
                int rowsAffected = stmt.executeUpdate();

                if (rowsAffected > 0) {
                    LOGGER.log(Level.INFO, "Đã ban patient_id: {0}, account_id: {1}", new Object[]{patientId, accountId});
                    sendJsonResponse(response, "{\"success\": true, \"message\": \"Đã ban bệnh nhân thành công\"}");
                } else {
                    LOGGER.log(Level.WARNING, "Không tìm thấy account_id: {0} trong bảng Account", accountId);
                    sendJsonError(response, "Không tìm thấy tài khoản bệnh nhân", 404);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Lỗi database khi ban patient", e);
            sendJsonError(response, "Lỗi database: " + e.getMessage(), 500);
        } catch (NumberFormatException e) {
            LOGGER.log(Level.SEVERE, "NumberFormatException for patientId: " + patientIdStr, e);
            sendJsonError(response, "Invalid patientId format: " + patientIdStr, 400);
        }
    }
    
    /**
     * Helper: Gửi JSON response
     */
    private void sendJsonResponse(HttpServletResponse response, String json) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json);
    }
    
    /**
     * Tạo dữ liệu demo khi Gemini API hết quota (HTTP 429)
     * Trả về JSON có cấu trúc giống response thật
     */
    private String generateDemoResponse(List<HealthRecordData> records) {
        StringBuilder json = new StringBuilder();
        json.append("{\"has_anomaly\": true, \"anomalies\": [");
        
        boolean first = true;
        int anomalyCount = 0;
        
        // Tìm các bản ghi có dấu hiệu đáng ngờ để demo
        for (HealthRecordData record : records) {
            if (record.otherInformation == null) continue;
            
            String content = record.otherInformation.toLowerCase();
            String originalContent = record.otherInformation;
            
            // Xác định loại spam và lý do cụ thể
            String spamType = "spam";
            String reason = "Nội dung đáng ngờ";
            
            if (content.contains("asdasd")) {
                spamType = "spam";
                reason = "Chứa ký tự vô nghĩa 'asdasd' - Dấu hiệu spam/test";
            } else if (content.contains("qwerty")) {
                spamType = "spam";
                reason = "Chứa ký tự bàn phím 'qwerty' - Dấu hiệu spam/test";
            } else if (content.contains("hack")) {
                spamType = "phá hoại";
                reason = "Chứa từ khóa 'hack' - Có thể là nội dung phá hoại";
            } else if (content.contains("spam")) {
                spamType = "spam";
                reason = "Chứa từ khóa 'spam' - Nội dung spam";
            } else if (content.length() < 5) {
                spamType = "dữ liệu rác";
                reason = "Nội dung quá ngắn (" + content.length() + " ký tự) - Dữ liệu không hợp lệ";
            }
            
            boolean isSuspicious = content.contains("asdasd") || 
                                  content.contains("spam") || 
                                  content.contains("hack") ||
                                  content.contains("qwerty") ||
                                  content.length() < 5;
            
            if (isSuspicious && anomalyCount < 5) { // Tăng lên 5 anomalies
                if (!first) json.append(", ");
                first = false;
                
                // Hiển thị 150 ký tự đầu tiên thay vì 50
                int previewLength = Math.min(150, originalContent.length());
                String contentPreview = originalContent.substring(0, previewLength);
                if (originalContent.length() > 150) {
                    contentPreview += "...";
                }
                
                // Escape nội dung để tránh lỗi JSON
                String escapedContent = escapeJson(contentPreview);
                // Escape lý do
                String escapedReason = escapeJson(reason);
                
                json.append("{\"record_id\": ").append(record.healthRecordId)
                    .append(", \"patient_id\": ").append(record.patientId)
                    .append(", \"type\": \"").append(spamType).append("\"")
                    .append(", \"content_preview\": \"").append(escapedContent).append("\"")
                    .append(", \"reason\": \"").append(escapedReason).append("\"")
                    .append(", \"full_content\": \"").append(escapeJson(originalContent)).append("\"")
                    .append(", \"confidence\": \"high\"}");
                
                anomalyCount++;
            }
        }
        
        // Nếu không có bản ghi đáng ngờ, tạo 1 demo anomaly từ bản ghi đầu tiên
        if (anomalyCount == 0 && !records.isEmpty()) {
            HealthRecordData firstRecord = records.get(0);
            String preview = firstRecord.otherInformation != null ? 
                firstRecord.otherInformation.substring(0, Math.min(150, firstRecord.otherInformation.length())) : 
                "Không có nội dung";
            
            json.append("{\"record_id\": ").append(firstRecord.healthRecordId)
                .append(", \"patient_id\": ").append(firstRecord.patientId)
                .append(", \"type\": \"demo\"")
                .append(", \"content_preview\": \"").append(escapeJson(preview)).append("\"")
                .append(", \"reason\": \"DEMO MODE - API quota exceeded. Đây là dữ liệu mẫu.\"")
                .append(", \"confidence\": \"demo\"}");
        }
        
        json.append("], \"message\": \"Phát hiện ").append(anomalyCount > 0 ? anomalyCount : 1)
            .append(" bản ghi bất thường (DEMO MODE - API quota exceeded)\", \"demo_mode\": true}");
        
        return json.toString();
    }
    
    /**
     * Helper: Gửi JSON error response - Luôn có has_anomaly để frontend xử lý
     */
    private void sendJsonError(HttpServletResponse response, String message, int statusCode) 
            throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        String jsonError = "{\"has_anomaly\": false, \"anomalies\": [], \"error\":\"" + escapeJson(message) + "\", \"success\": false}";
        response.getWriter().write(jsonError);
    }
    
    /**
     * Escape special characters for JSON string
     */
    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\b", "\\b")
                   .replace("\f", "\\f")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }
    
    /**
     * Inner class đại diện cho dữ liệu Health Record
     */
    public static class HealthRecordData {
        public int healthRecordId;
        public int patientId;
        public String otherInformation;
        public java.sql.Timestamp createdAt;
    }
}
