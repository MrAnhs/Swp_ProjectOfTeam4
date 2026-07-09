package com.diabetes.monitoring.util;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;

public class GeminiIntegration {
    private static final String API_URL_BASE =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";
    private static int activeKeyIndex = 0;

    private static final String SYSTEM_PROMPT = 
        "Bạn là một bác sĩ AI chuyên theo dõi và hỗ trợ bệnh nhân tiểu đường. "
  + "Bạn luôn nói chuyện nhẹ nhàng, quan tâm và giống như bác sĩ thật đang chăm sóc bệnh nhân hằng ngày.\n\n"

  + "MỤC TIÊU:\n"
  + "- Tập trung hoàn toàn vào bệnh tiểu đường.\n"
  + "- Hỗ trợ bệnh nhân theo dõi sức khỏe.\n"
  + "- Phát hiện dấu hiệu nguy hiểm liên quan đến tiểu đường.\n"
  + "- Đưa ra lời khuyên ăn uống, vận động và kiểm soát đường huyết.\n"
  + "- Làm cho bệnh nhân cảm thấy được quan tâm.\n\n"

  + "PHONG CÁCH TRÒ CHUYỆN:\n"
  + "- Trò chuyện tự nhiên như bác sĩ thật.\n"
  + "- Luôn thể hiện sự quan tâm và động viên.\n"
  + "- Trả lời đầy đủ nhưng súc tích, tránh lặp lại toàn bộ thông tin bệnh nhân vừa cung cấp.\n"
  + "- Luôn kết thúc bằng một câu hỏi quan tâm bệnh nhân.\n"
  + "- BẮT BUỘC KHÔNG hỏi bệnh nhân có lo lắng gì về việc đi khám không (tránh hỏi lạc đề). Khi khuyên bệnh nhân đi khám, hãy hỏi xem họ còn câu hỏi nào khác muốn đặt ra không.\n\n"

  + "CÁC TRIỆU CHỨNG TIỂU ĐƯỜNG CẦN QUAN TÂM:\n"
  + "1. Khát nước nhiều hơn bình thường.\n"
  + "2. Đi tiểu nhiều lần, đặc biệt vào ban đêm.\n"
  + "3. Cảm giác mệt mỏi kéo dài hoặc thiếu năng lượng.\n"
  + "4. Nhìn mờ hoặc thị lực giảm tạm thời.\n"
  + "5. Ăn nhiều nhưng vẫn nhanh đói.\n"
  + "6. Sụt cân bất thường dù không ăn kiêng.\n"
  + "7. Vết thương lâu lành hoặc dễ bị nhiễm trùng.\n"
  + "8. Tê bì hoặc cảm giác châm chích ở bàn tay, bàn chân.\n"
  + "9. Da khô, ngứa hoặc dễ bị nhiễm nấm tái phát.\n"
  + "10. Chóng mặt hoặc cảm giác cơ thể suy nhược.\n\n"

  + "KHI HỎI VỀ TRIỆU CHỨNG:\n"
  + "- Hỏi kỹ triệu chứng bắt đầu từ khi nào, xuất hiện thường xuyên không, mức độ nặng nhẹ ra sao.\n"
  + "- Hỏi triệu chứng xảy ra vào thời điểm nào trong ngày, có liên quan đến ăn uống, vận động hoặc dùng thuốc không.\n"
  + "- Nếu bệnh nhân có nhiều triệu chứng cùng lúc, hãy tóm tắt lại và hỏi thêm 1-2 câu quan trọng nhất thay vì hỏi quá nhiều một lần.\n\n"

  + "LUỒNG HỘI THOẠI BẮT BUỘC:\n"
  + "1. Khi bắt đầu hoặc khi chưa rõ thông tin xét nghiệm, trước tiên phải hỏi bệnh nhân: \"Bạn đã từng xét nghiệm đường huyết hoặc HbA1c chưa?\"\n"
  + "2. Sau khi bệnh nhân đã trả lời câu hỏi xét nghiệm (dù đã xét nghiệm hay chưa), tiếp tục hỏi về tiền sử bệnh lý. BẮT BUỘC trong câu hỏi tiền sử phải hỏi về tiền sử của bản thân bệnh nhân trước, sau đó mới hỏi đến tiền sử của gia đình (bố mẹ, anh chị em ruột) trong cùng câu đó. Ví dụ: 'Bản thân bạn hay gia đình đã từng mắc tiểu đường chưa?'. Nếu có, hãy tổng hợp thông tin tiền sử này vào phần triệu chứng (symptoms) trong healthData.\n"
  + "3. Nếu bệnh nhân trả lời CHƯA xét nghiệm:\n"
  + "   - Không yêu cầu nhập các chỉ số xét nghiệm.\n"
  + "   - Tiếp tục hỏi kỹ các triệu chứng hiện tại theo danh sách triệu chứng ở trên.\n"
  + "   - Khi đã khai thác đủ thông tin (triệu chứng và tiền sử bệnh lý), bắt buộc phải khuyên bệnh nhân nên đi khám bác sĩ hoặc đến cơ sở y tế gần nhất và hỏi xem họ còn câu hỏi nào khác cho bác sĩ không.\n"
  + "4. Nếu bệnh nhân trả lời ĐÃ xét nghiệm:\n"
  + "   - Hỏi các chỉ số cần thiết để nộp hồ sơ: đường huyết lúc đói hoặc sau ăn, HbA1c, urea, creatinine, cholesterol, triglyceride, HDL, LDL, VLDL, cân nặng, chiều cao và triệu chứng hiện tại.\n"
  + "   - Nếu bệnh nhân chưa nhớ hết chỉ số, hãy hỏi từng nhóm nhỏ, không hỏi quá nhiều một lần.\n"
  + "   - Khi đã khai thác đủ thông tin (bao gồm chỉ số xét nghiệm, triệu chứng và tiền sử), bắt buộc phải khuyên bệnh nhân nên đi khám bác sĩ hoặc đến cơ sở y tế gần nhất và hỏi xem họ còn câu hỏi nào khác cho bác sĩ không.\n\n"

  + "NHIỆM VỤ DỮ LIỆU:\n"
  + "1. Thu thập CHÍNH XÁC các chỉ số số từ tin nhắn bệnh nhân:\n"
  + "   - urea: mmol/L (chỉ số thận)\n"
  + "   - cr: μmol/L (creatinine - chỉ số thận)\n"
  + "   - hba1c: % (hemoglobin gắn glucose)\n"
  + "   - chol: mmol/L (cholesterol tổng)\n"
  + "   - tg: mmol/L (triglyceride)\n"
  + "   - hdl: mmol/L (cholesterol tốt)\n"
  + "   - ldl: mmol/L (LDL - cholesterol xấu)\n"
  + "   - vldl: mmol/L (VLDL cholesterol)\n"
  + "   - weight: kg (cân nặng)\n"
  + "   - height: cm (chiều cao)\n"
  + "   - bmi: tự tính từ weight và height\n"
  + "   - symptoms: triệu chứng hiện tại (khát nước, đi tiểu nhiều, mệt mỏi...)\n\n"

  + "2. CÁCH TRÍCH XUẤT DỮ LIỆU TỪ TIN NHẮN:\n"
  + "   - Khi bệnh nhân nói 'urea 5.0' → healthData.urea = 5.0\n"
  + "   - Khi bệnh nhân nói 'creatinine 80' hoặc 'cr 80' → healthData.cr = 80\n"
  + "   - Khi bệnh nhân nói 'hba1c 4.0' → healthData.hba1c = 4.0\n"
  + "   - Khi bệnh nhân nói 'cholesterol 5.0' hoặc 'chol 5.0' → healthData.chol = 5.0\n"
  + "   - Khi bệnh nhân nói 'tg 1.4' hoặc 'triglyceride 1.4' → healthData.tg = 1.4\n"
  + "   - Khi bệnh nhân nói 'hdl 2.4' → healthData.hdl = 2.4\n"
  + "   - Khi bệnh nhân nói 'ldl 3.0' → healthData.ldl = 3.0\n"
  + "   - Khi bệnh nhân nói 'vldl 0.5' → healthData.vldl = 0.5\n"
  + "   - Khi bệnh nhân nói 'cân nặng 44kg' hoặc 'nặng 44' → healthData.weight = 44\n"
  + "   - Khi bệnh nhân nói 'cao 163cm' hoặc 'chiều cao 1.63m' → healthData.height = 163\n"
  + "   - Triệu chứng như 'đi tiểu nhiều, khát nước' → healthData.symptoms\n\n"

  + "3. GIẢI THÍCH TỪ VIẾT TẮT KHI BỆNH NHÂN HỎI:\n"
  + "   - Urea: Chỉ số chức năng thận\n"
  + "   - Cr/Creatinine: Chỉ số chức năng thận\n"
  + "   - HbA1c: Hemoglobin gắn glucose - chỉ số đường huyết trung bình 3 tháng\n"
  + "   - Chol: Cholesterol tổng - mỡ trong máu\n"
  + "   - TG: Triglyceride - chất béo trung tính trong máu\n"
  + "   - HDL: High Density Lipoprotein - cholesterol tốt\n"
  + "   - LDL: Low Density Lipoprotein - cholesterol xấu\n"
  + "   - VLDL: Very Low Density Lipoprotein - cholesterol rất xấu\n"
  + "   - BMI: Body Mass Index - chỉ số khối cơ thể\n\n"

  + "4. CHỈ điền dữ liệu khi bệnh nhân thực sự cung cấp.\n"
  + "Nếu chưa có dữ liệu thì để 0.\n\n"

  + "5. Nếu bệnh nhân chưa có chỉ số xét nghiệm, hãy hỏi kỹ triệu chứng hiện tại.\n\n"

  + "6. Nếu đường huyết quá cao hoặc có dấu hiệu nguy hiểm:\n"
  + "- khó thở\n"
  + "- đau ngực\n"
  + "- ngất\n"
  + "- lơ mơ\n"
  + "thì khuyên bệnh nhân đến bệnh viện ngay.\n\n"

  + "7. Luôn ưu tiên tư vấn:\n"
  + "- kiểm soát đường huyết\n"
  + "- chế độ ăn cho người tiểu đường\n"
  + "- vận động nhẹ\n"
  + "- ngủ nghỉ hợp lý\n"
  + "- uống thuốc đúng giờ\n\n"

  + "ĐỊNH DẠNG PHẢN HỒI:\n"
  + "CHỈ trả về JSON.\n\n"

  + "{\n"
  + "  \"reply\": \"Lời tư vấn bằng tiếng Việt\",\n"
  + "  \"healthData\": {\n"
  + "    \"urea\": 0,\n"
  + "    \"cr\": 0,\n"
  + "    \"hba1c\": 0,\n"
  + "    \"chol\": 0,\n"
  + "    \"tg\": 0,\n"
  + "    \"hdl\": 0,\n"
  + "    \"ldl\": 0,\n"
  + "    \"vldl\": 0,\n"
  + "    \"weight\": 0,\n"
  + "    \"height\": 0,\n"
  + "    \"bmi\": 0,\n"
  + "    \"symptoms\": \"\"\n"
  + "  }\n"
  + "}";
    public String getChatResponse(String userPrompt) {
        List<String> apiKeys = getConfiguredApiKeys();
        if (apiKeys.isEmpty()) {
            return "{\"reply\": \"AI service is not configured.\", \"healthData\": {\"urea\":0,\"cr\":0,\"hba1c\":0,\"chol\":0,\"tg\":0,\"hdl\":0,\"ldl\":0,\"vldl\":0,\"weight\":0,\"height\":0,\"bmi\":0,\"symptoms\":\"\"}}";
        }

        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
        String jsonRequest = "{"
            + "\"contents\": [{\"parts\": [{\"text\": \"" + escapeJson(SYSTEM_PROMPT + "\nUser: " + userPrompt) + "\"}]}], "
            + "\"generationConfig\": {"
            + "  \"temperature\": 0.7, "
            + "  \"topP\": 0.95, "
            + "  \"maxOutputTokens\": 2048, "
            + "  \"responseMimeType\": \"application/json\""
            + "}"
            + "}";

        int startIndex = getActiveKeyIndex(apiKeys.size());
        for (int attempt = 0; attempt < apiKeys.size(); attempt++) {
            int keyIndex = (startIndex + attempt) % apiKeys.size();
            String apiKey = apiKeys.get(keyIndex);
            try {
                HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_URL_BASE + apiKey))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonRequest, StandardCharsets.UTF_8))
                    .timeout(Duration.ofSeconds(30))
                    .build();

                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() == 200) {
                    String responseBody = response.body();
                    System.out.println("Gemini Raw Response: " + responseBody);
                    String rawResult = parseGeminiResponse(responseBody);
                    String extracted = extractJson(rawResult);
                    
                    if (extracted.startsWith("{") && extracted.endsWith("}")) {
                        setActiveKeyIndex(keyIndex);
                        return extracted;
                    }
                    setActiveKeyIndex(keyIndex);
                    return "{\"reply\": \"" + escapeJson(rawResult) + "\", \"healthData\": {\"hba1c\":0, \"bmi\":0, \"tg\":0, \"hdl\":0, \"symptoms\":\"\"}}";
                } else if (shouldSwitchKey(response.statusCode())) {
                    System.err.println("Gemini key " + (keyIndex + 1) + " failed with status "
                            + response.statusCode() + ". Switching to next key.");
                    setActiveKeyIndex((keyIndex + 1) % apiKeys.size());
                    continue;
                } else {
                    String errorBody = response.body();
                    System.err.println("Gemini Error (" + response.statusCode() + "): " + errorBody);
                    return "{\"reply\": \"Lỗi dịch vụ AI (Status " + response.statusCode() + "). Vui lòng thử lại.\", \"healthData\": {\"hba1c\":0, \"bmi\":0, \"tg\":0, \"hdl\":0, \"symptoms\":\"\"}}";
                }
            } catch (Exception e) {
                if (attempt == apiKeys.size() - 1) {
                    return "{\"reply\": \"Lỗi kết nối: " + e.getMessage() + "\", \"healthData\": {\"hba1c\":0, \"bmi\":0, \"tg\":0, \"hdl\":0, \"symptoms\":\"\"}}";
                }
                setActiveKeyIndex((keyIndex + 1) % apiKeys.size());
            }
        }
        return "{\"reply\": \"Tất cả API key hiện đang hết hạn mức hoặc không khả dụng. Vui lòng thử lại sau.\", \"healthData\": {\"hba1c\":0, \"bmi\":0, \"tg\":0, \"hdl\":0, \"symptoms\":\"\"}}";
    }

    public String getSummaryResponse(String chatHistory) {
        List<String> apiKeys = getConfiguredApiKeys();
        if (apiKeys.isEmpty()) {
            return "Không thể kết nối dịch vụ AI để tạo tóm tắt.";
        }

        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
        String prompt = "Dưới đây là lịch sử cuộc trò chuyện giữa bệnh nhân tiểu đường và bác sĩ AI. " +
                        "Hãy tóm tắt ngắn gọn các ý quan trọng nhất (như triệu chứng nổi bật, chỉ số bất thường, " +
                        "và các lời khuyên ăn uống/vận động quan trọng) dưới dạng các gạch đầu dòng ngắn gọn bằng tiếng Việt:\n\n" +
                        chatHistory;
        String jsonRequest = "{"
            + "\"contents\": [{\"parts\": [{\"text\": \"" + escapeJson(prompt) + "\"}]}], "
            + "\"generationConfig\": {"
            + "  \"temperature\": 0.3, "
            + "  \"maxOutputTokens\": 1024"
            + "}"
            + "}";

        int startIndex = getActiveKeyIndex(apiKeys.size());
        for (int attempt = 0; attempt < apiKeys.size(); attempt++) {
            int keyIndex = (startIndex + attempt) % apiKeys.size();
            String apiKey = apiKeys.get(keyIndex);
            try {
                HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_URL_BASE + apiKey))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonRequest, StandardCharsets.UTF_8))
                    .timeout(Duration.ofSeconds(30))
                    .build();

                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() == 200) {
                    String responseBody = response.body();
                    String rawResult = parseGeminiResponse(responseBody);
                    setActiveKeyIndex(keyIndex);
                    return rawResult;
                } else if (shouldSwitchKey(response.statusCode())) {
                    setActiveKeyIndex((keyIndex + 1) % apiKeys.size());
                    continue;
                } else {
                    return "Không thể tạo tóm tắt AI (Status " + response.statusCode() + ").";
                }
            } catch (Exception e) {
                if (attempt == apiKeys.size() - 1) {
                    return "Lỗi kết nối tóm tắt AI: " + e.getMessage();
                }
                setActiveKeyIndex((keyIndex + 1) % apiKeys.size());
            }
        }
        return "Tất cả API key hiện tại không khả dụng để tạo tóm tắt.";
    }

    private List<String> getConfiguredApiKeys() {
        return GeminiConfigUtil.getRecommendationApiKeys();
    }

    private synchronized int getActiveKeyIndex(int keyCount) {
        if (keyCount <= 0) return 0;
        if (activeKeyIndex < 0 || activeKeyIndex >= keyCount) {
            activeKeyIndex = 0;
        }
        return activeKeyIndex;
    }

    private synchronized void setActiveKeyIndex(int keyIndex) {
        activeKeyIndex = Math.max(0, keyIndex);
    }

    private boolean shouldSwitchKey(int statusCode) {
        return statusCode == 401
                || statusCode == 403
                || statusCode == 429
                || statusCode == 500
                || statusCode == 502
                || statusCode == 503
                || statusCode == 504;
    }

    private String extractJson(String text) {
        try {
            int start = text.indexOf("{");
            int end = text.lastIndexOf("}");
            if (start != -1 && end != -1 && end > start) {
                return text.substring(start, end + 1);
            }
        } catch (Exception e) {}
        return text;
    }

    private String extractErrorMessage(String responseBody) {
        try {
            // Cố gắng tìm message trong lỗi JSON của Google
            String searchStr = "\"message\": \"";
            int start = responseBody.indexOf(searchStr);
            if (start != -1) {
                start += searchStr.length();
                int end = responseBody.indexOf("\"", start);
                if (end != -1) {
                    return responseBody.substring(start, end);
                }
            }
        } catch (Exception e) {}
        return "Unknown error";
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

    private String parseGeminiResponse(String responseBody) {
        try {
            // Cấu trúc phản hồi Gemini: candidates[0].content.parts[0].text
            String searchStr = "\"text\": \"";
            int start = responseBody.indexOf(searchStr);
            if (start != -1) {
                start += searchStr.length();
                
                // Tìm vị trí kết thúc của chuỗi text (dấu ngoặc kép không bị escape)
                int end = -1;
                for (int i = start; i < responseBody.length(); i++) {
                    if (responseBody.charAt(i) == '\"') {
                        // Kiểm tra xem dấu ngoặc kép này có bị escape bởi số lẻ dấu backslash không
                        int backslashCount = 0;
                        for (int j = i - 1; j >= start && responseBody.charAt(j) == '\\'; j--) {
                            backslashCount++;
                        }
                        if (backslashCount % 2 == 0) {
                            end = i;
                            break;
                        }
                    }
                }
                
                if (end != -1) {
                    String result = responseBody.substring(start, end);
                    
                    // Unescape các ký tự JSON cơ bản
                    result = result.replace("\\n", "\n")
                                   .replace("\\\"", "\"")
                                   .replace("\\\\", "\\")
                                   .replace("\\t", "\t");
                    
                    // Loại bỏ markdown tags
                    result = result.trim();
                    if (result.startsWith("```json")) {
                        result = result.substring(7);
                    } else if (result.startsWith("```")) {
                        result = result.substring(3);
                    }
                    if (result.endsWith("```")) {
                        result = result.substring(0, result.length() - 3);
                    }
                    return result.trim();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "Lỗi khi đọc phản hồi từ AI. Vui lòng thử lại.";
    }
}
