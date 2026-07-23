package com.diabetes.monitoring.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class GeminiSchedulingService {
    private static final Logger LOGGER = Logger.getLogger(GeminiSchedulingService.class.getName());
    private static final int TIMEOUT_MS = 10000;
    private static final DateTimeFormatter DISPLAY_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public SchedulingResult generate(Date startDate,
                                     Date endDate,
                                     List<Map<String, String>> shiftsPerDay,
                                     List<Map<String, Object>> doctors) {
        return generate(buildTargetDates(startDate, endDate), shiftsPerDay, doctors);
    }

    public SchedulingResult generate(List<Date> targetDates,
                                     List<Map<String, String>> shiftsPerDay,
                                     List<Map<String, Object>> doctors) {
        if (targetDates == null || targetDates.isEmpty()
                || shiftsPerDay == null || shiftsPerDay.isEmpty()
                || doctors == null || doctors.isEmpty()) {
            return SchedulingResult.failure("Thiếu target_dates, shifts_per_day hoặc doctors_list.");
        }

        List<String> keys = GeminiConfigUtil.getSchedulingApiKeys();
        List<String> models = GeminiConfigUtil.getSchedulingModelCandidates();
        if (keys.isEmpty() || models.isEmpty()) {
            return SchedulingResult.failure("Chưa cấu hình Gemini cho AI lập lịch.");
        }

        String prompt = buildPrompt(targetDates, shiftsPerDay, doctors);
        String lastError = "";

        for (String model : models) {
            String requestBody = buildRequestBody(
                    prompt, model, expectedCount(targetDates, shiftsPerDay));
            for (int keyIndex = 0; keyIndex < keys.size(); keyIndex++) {
                HttpURLConnection connection = null;
                try {
                    URL url = new URL("https://generativelanguage.googleapis.com/v1beta/models/"
                            + model + ":generateContent");
                    connection = (HttpURLConnection) url.openConnection();
                    connection.setRequestMethod("POST");
                    connection.setRequestProperty("Content-Type", "application/json;charset=UTF-8");
                    connection.setRequestProperty("Accept", "application/json");
                    connection.setRequestProperty("x-goog-api-key", keys.get(keyIndex));
                    connection.setConnectTimeout(TIMEOUT_MS);
                    connection.setReadTimeout(TIMEOUT_MS);
                    connection.setDoOutput(true);
                    try (OutputStream output = connection.getOutputStream()) {
                        output.write(requestBody.getBytes(StandardCharsets.UTF_8));
                    }

                    int status = connection.getResponseCode();
                    String body = readBody(connection, status >= 200 && status < 300);
                    if (status != 200) {
                        lastError = "HTTP " + status + " với model " + model + ", key #" + (keyIndex + 1)
                                + " | " + compact(body);
                        LOGGER.log(Level.WARNING, "Gemini scheduling {0}; trying next candidate", lastError);
                        continue;
                    }

                    String modelText = extractModelText(body);
                    List<Map<String, Object>> assignments = parseAssignments(modelText);
                    String validationError = validate(assignments, targetDates, shiftsPerDay, doctors);
                    if (validationError == null) {
                        return SchedulingResult.success(assignments, model, keyIndex + 1);
                    }
                    lastError = "Gemini trả lịch không hợp lệ: " + validationError
                            + " | output=" + compact(modelText);
                    LOGGER.log(Level.WARNING, lastError);
                } catch (SocketTimeoutException e) {
                    lastError = "Gemini timeout với key #" + (keyIndex + 1);
                    LOGGER.log(Level.WARNING, lastError);
                } catch (IOException | RuntimeException e) {
                    lastError = "Lỗi Gemini scheduling: " + compact(e.getMessage());
                    LOGGER.log(Level.WARNING, lastError);
                } finally {
                    if (connection != null) {
                        connection.disconnect();
                    }
                }
            }
        }
        return SchedulingResult.failure(lastError.isBlank()
                ? "Tất cả model/API key Gemini lập lịch đều không khả dụng."
                : lastError);
    }

    private String buildRequestBody(String prompt, String model, int expectedCount) {
        String thinkingConfig = model != null && model.startsWith("gemini-2.5")
                ? "\"thinkingConfig\":{\"thinkingBudget\":0},"
                : "\"thinkingConfig\":{\"thinkingLevel\":\"minimal\"},";
        int maxOutputTokens = Math.min(8192, Math.max(2048, expectedCount * 180));
        return "{\"contents\":[{\"parts\":[{\"text\":\"" + escapeJson(prompt) + "\"}]}],"
                + "\"generationConfig\":{"
                + "\"temperature\":0.0,"
                + "\"maxOutputTokens\":" + maxOutputTokens + ","
                + thinkingConfig
                + "\"responseMimeType\":\"application/json\","
                + "\"responseSchema\":{"
                + "\"type\":\"array\",\"items\":{\"type\":\"object\",\"properties\":{"
                + "\"doctor_id\":{\"type\":\"string\"},"
                + "\"date\":{\"type\":\"string\"},"
                + "\"time_slot\":{\"type\":\"string\"},"
                + "\"department\":{\"type\":\"string\"}"
                + "},\"required\":[\"doctor_id\",\"date\",\"time_slot\",\"department\"]}"
                + "}}}";
    }

    private String buildPrompt(List<Date> targetDates,
                               List<Map<String, String>> shifts,
                               List<Map<String, Object>> doctors) {
        StringBuilder prompt = new StringBuilder(4096);
        prompt.append("Bạn là AI Engine lập lịch nhân sự cao cấp, hoạt động như thuật toán tối ưu hóa tuyến tính cho S-COMS. ")
                .append("Bạn nhận khung ca trực rỗng và danh sách ")
                .append(doctors.size())
                .append(" bác sĩ active. Nhiệm vụ duy nhất là điền doctor_id vào các vị trí NULL. ")
                .append("Mục tiêu cao nhất là tổng số ca của mỗi bác sĩ phải đều nhau tuyệt đối, chênh lệch tối đa 1 ca. ")
                .append("Chỉ trả về một mảng JSON thuần.\n");
        prompt.append("target_dates=[");
        for (int i = 0; i < targetDates.size(); i++) {
            if (i > 0) {
                prompt.append(',');
            }
            prompt.append('"').append(targetDates.get(i).toLocalDate().format(DISPLAY_DATE)).append('"');
        }
        prompt.append("]\nempty_schedules=[");
        boolean firstSlot = true;
        for (Date targetDate : targetDates) {
            for (Map<String, String> shift : shifts) {
                if (!firstSlot) {
                    prompt.append(',');
                }
                firstSlot = false;
                prompt.append("{\"doctor_id\":null,\"date\":\"")
                        .append(targetDate.toLocalDate().format(DISPLAY_DATE))
                        .append("\",\"time_slot\":\"").append(escapeJson(shift.get("timeSlot")))
                        .append("\",\"department\":\"")
                        .append(escapeJson(shift.get("department"))).append("\"}");
            }
        }
        prompt.append("]\nshifts_per_day=[");
        for (int i = 0; i < shifts.size(); i++) {
            if (i > 0) {
                prompt.append(',');
            }
            prompt.append("{\"time_slot\":\"").append(escapeJson(shifts.get(i).get("timeSlot")))
                    .append("\",\"department\":\"").append(escapeJson(shifts.get(i).get("department"))).append("\"}");
        }
        prompt.append("]\ndoctors_list=[");
        for (int i = 0; i < doctors.size(); i++) {
            if (i > 0) {
                prompt.append(',');
            }
            Map<String, Object> doctor = doctors.get(i);
            prompt.append("{\"doctor_id\":\"").append(doctor.get("doctorId"))
                    .append("\",\"doctor_name\":\"").append(escapeJson(String.valueOf(doctor.get("doctorName"))))
                    .append("\",\"department\":\"").append(escapeJson(String.valueOf(doctor.get("department"))))
                    .append("\",\"status\":\"").append(escapeJson(String.valueOf(doctor.get("status"))))
                    .append("\",\"current_load\":").append(number(doctor.get("currentLoad"))).append('}');
        }
        prompt.append("]\nRÀNG BUỘC TOÁN HỌC - CÂN BẰNG CA TUYỆT ĐỐI:\n")
                .append("1. Đếm tổng số ca trống N và tổng số bác sĩ hợp lệ M. Mỗi bác sĩ phải nhận số ca bằng nhau hoặc chỉ chênh lệch tối đa 1 ca. Đây là ưu tiên cao nhất.\n")
                .append("2. Duyệt empty_schedules đúng thứ tự. Khởi tạo assigned_count của mỗi bác sĩ bằng 0 và simulated_load bằng current_load.\n")
                .append("3. Mỗi khi gán một ca, tăng assigned_count và simulated_load của bác sĩ đó trước khi chọn ca kế tiếp.\n")
                .append("4. Ưu tiên bác sĩ đúng department trước, nhưng nếu nhóm đúng khoa đã đạt định mức hoặc gây lệch tải, phải chọn bác sĩ khoa 'General' (Tổng quát) hoặc chuyên khoa khác có assigned_count thấp hơn.\n")
                .append("5. Cân bằng số ca giữa bác sĩ quan trọng hơn đúng khoa tuyệt đối. Không để một người nhận nhiều ca trong khi người khác còn 0 hoặc ít hơn quá 1 ca.\n")
                .append("6. Một bác sĩ không được trực quá 2 ca trong cùng một ngày và không được trực 2 ca liên tiếp trong ngày.\n")
                .append("7. Giữ nguyên số lượng, thứ tự, date, time_slot và department của empty_schedules; chỉ thay doctor_id null. Nếu một date/time_slot/department xuất hiện nhiều lần thì đó là nhiều bác sĩ cùng trực một ca, phải trả đủ số object tương ứng.\n")
                .append("8. QUAN TRỌNG: Department 'General' là khoa dự phòng có thể xử lý các ca từ bất kỳ khoa nào. Nếu một khoa chuyên biệt đã đủ bác sĩ, HÃY phân bổ ca cho bác sĩ 'General' để cân bằng tải.\n")
                .append("9. Chỉ trả JSON: [{\"doctor_id\":\"1\",\"date\":\"dd/MM/yyyy\",")
                .append("\"time_slot\":\"HH:mm-HH:mm\",\"department\":\"Endocrinology|General|...\"}]. ")
                .append("Không markdown, không giải thích, không dấu ba chấm.");
        return prompt.toString();
    }

    private List<Map<String, Object>> parseAssignments(String raw) {
        String json = raw == null ? "" : raw.trim()
                .replaceFirst("^```(?:json)?\\s*", "")
                .replaceFirst("\\s*```$", "");
        List<Map<String, Object>> rows = new ArrayList<>();
        for (String objectJson : extractTopLevelObjects(json)) {
            String doctorId = extractJsonStringOrPrimitive(objectJson, "doctor_id");
            String date = extractJsonStringOrPrimitive(objectJson, "date");
            String timeSlot = extractJsonStringOrPrimitive(objectJson, "time_slot");
            String department = extractJsonStringOrPrimitive(objectJson, "department");
            if (doctorId == null || date == null || timeSlot == null || department == null) {
                continue;
            }
            Map<String, Object> row = new LinkedHashMap<>();
            String numericDoctorId = doctorId.replaceAll("[^0-9-]", "");
            if (numericDoctorId.isEmpty() || "-".equals(numericDoctorId)) {
                continue;
            }
            row.put("doctorId", Integer.parseInt(numericDoctorId));
            row.put("workDate", normalizeDate(date));
            row.put("timeSlot", timeSlot.trim());
            row.put("department", normalizeDepartment(department));
            rows.add(row);
        }
        return rows;
    }

    private String validate(List<Map<String, Object>> rows,
                            List<Date> targetDates,
                            List<Map<String, String>> shifts,
                            List<Map<String, Object>> doctors) {
        int expected = expectedCount(targetDates, shifts);
        if (rows.size() != expected) {
            return "số ca " + rows.size() + "/" + expected;
        }
        rows.sort((left, right) -> {
            int dateCompare = String.valueOf(left.get("workDate"))
                    .compareTo(String.valueOf(right.get("workDate")));
            if (dateCompare != 0) {
                return dateCompare;
            }
            return Integer.compare(
                    shiftIndex(shifts, String.valueOf(left.get("timeSlot"))),
                    shiftIndex(shifts, String.valueOf(right.get("timeSlot"))));
        });

        Map<Integer, Map<String, Object>> doctorById = new HashMap<>();
        for (Map<String, Object> doctor : doctors) {
            doctorById.put(number(doctor.get("doctorId")), doctor);
        }
        Map<String, Integer> expectedSlots = new HashMap<>();
        for (Date targetDate : targetDates) {
            LocalDate day = targetDate.toLocalDate();
            for (Map<String, String> shift : shifts) {
                incrementCount(expectedSlots, day + "|" + shift.get("timeSlot") + "|" + normalizeDepartment(shift.get("department")));
            }
        }

        Map<String, Integer> actualSlots = new HashMap<>();
        Map<String, Integer> previousDoctorByDate = new HashMap<>();
        Map<String, Integer> dailyShiftCount = new HashMap<>();
        Map<Integer, Integer> simulatedLoad = new HashMap<>();
        Map<Integer, Integer> totalAssignedCount = new HashMap<>();
        for (Map.Entry<Integer, Map<String, Object>> entry : doctorById.entrySet()) {
            simulatedLoad.put(entry.getKey(), number(entry.getValue().get("currentLoad")));
            totalAssignedCount.put(entry.getKey(), 0);
        }
        for (Map<String, Object> row : rows) {
            int doctorId = number(row.get("doctorId"));
            Map<String, Object> doctor = doctorById.get(doctorId);
            if (doctor == null || !"active".equalsIgnoreCase(String.valueOf(doctor.get("status")))) {
                return "doctor_id không active hoặc không tồn tại: " + doctorId;
            }
            if (number(doctor.get("currentLoad")) >= 90) {
                return "bác sĩ " + doctorId + " có tải từ 90%";
            }
            String rowDepartment = normalizeDepartment(String.valueOf(row.get("department")));
            String doctorDepartment = normalizeDepartment(String.valueOf(doctor.get("department")));
            String workDate = String.valueOf(row.get("workDate"));
            String slotKey = workDate + "|" + row.get("timeSlot") + "|" + rowDepartment;
            int expectedSlotCount = expectedSlots.getOrDefault(slotKey, 0);
            int actualSlotCount = actualSlots.getOrDefault(slotKey, 0) + 1;
            if (expectedSlotCount == 0 || actualSlotCount > expectedSlotCount) {
                return "ca không thuộc mẫu hoặc vượt số lượng bác sĩ/ca: " + slotKey;
            }
            actualSlots.put(slotKey, actualSlotCount);

            String dailyKey = workDate + "|" + doctorId;
            int shiftsToday = dailyShiftCount.getOrDefault(dailyKey, 0);
            if (shiftsToday >= 2) {
                return "bác sĩ " + doctorId + " vượt quá 2 ca trong ngày " + workDate;
            }

            int selectedLoad = simulatedLoad.getOrDefault(doctorId, number(doctor.get("currentLoad")));
            int selectedAssigned = totalAssignedCount.getOrDefault(doctorId, 0);
            for (Map.Entry<Integer, Map<String, Object>> candidateEntry : doctorById.entrySet()) {
                int candidateId = candidateEntry.getKey();
                Map<String, Object> candidate = candidateEntry.getValue();
                Integer candidatePreviousDoctor = previousDoctorByDate.get(workDate);
                if (candidateId == doctorId
                        || (candidatePreviousDoctor != null && candidatePreviousDoctor == candidateId)
                        || !"active".equalsIgnoreCase(String.valueOf(candidate.get("status")))
                        || number(candidate.get("currentLoad")) >= 90
                        || dailyShiftCount.getOrDefault(workDate + "|" + candidateId, 0) >= 2) {
                    continue;
                }
                int candidateLoad = simulatedLoad.getOrDefault(
                        candidateId, number(candidate.get("currentLoad")));
                int candidateAssigned = totalAssignedCount.getOrDefault(candidateId, 0);
                if (candidateLoad < selectedLoad
                        || (candidateLoad == selectedLoad && candidateAssigned < selectedAssigned)) {
                    return "phân bổ chưa cân bằng: bác sĩ " + candidateId
                            + " có tải mô phỏng thấp hơn bác sĩ " + doctorId
                            + " tại ca " + slotKey;
                }
            }

            Integer previousDoctor = previousDoctorByDate.put(workDate, doctorId);
            if (previousDoctor != null && previousDoctor == doctorId) {
                return "bác sĩ " + doctorId + " bị xếp hai ca liên tiếp ngày " + workDate;
            }
            dailyShiftCount.put(dailyKey, shiftsToday + 1);
            simulatedLoad.put(doctorId, selectedLoad + 1);
            totalAssignedCount.put(doctorId, selectedAssigned + 1);
        }
        if (!actualSlots.equals(expectedSlots)) {
            return "thiếu tổ hợp ngày-ca hoặc chưa đủ số bác sĩ/ca bắt buộc";
        }
        int minAssigned = Integer.MAX_VALUE;
        int maxAssigned = Integer.MIN_VALUE;
        for (Map.Entry<Integer, Map<String, Object>> entry : doctorById.entrySet()) {
            Map<String, Object> doctor = entry.getValue();
            if (!"active".equalsIgnoreCase(String.valueOf(doctor.get("status")))
                    || number(doctor.get("currentLoad")) >= 90) {
                continue;
            }
            int count = totalAssignedCount.getOrDefault(entry.getKey(), 0);
            minAssigned = Math.min(minAssigned, count);
            maxAssigned = Math.max(maxAssigned, count);
        }
        if (minAssigned != Integer.MAX_VALUE && maxAssigned - minAssigned > 1) {
            return "tổng số ca giữa bác sĩ chưa đều: min=" + minAssigned + ", max=" + maxAssigned;
        }
        return null;
    }

    private void incrementCount(Map<String, Integer> counts, String key) {
        counts.put(key, counts.getOrDefault(key, 0) + 1);
    }

    private int shiftIndex(List<Map<String, String>> shifts, String timeSlot) {
        for (int i = 0; i < shifts.size(); i++) {
            if (timeSlot.equals(shifts.get(i).get("timeSlot"))) {
                return i;
            }
        }
        return Integer.MAX_VALUE;
    }

    private int expectedCount(Date startDate, Date endDate, List<Map<String, String>> shifts) {
        long days = java.time.temporal.ChronoUnit.DAYS.between(startDate.toLocalDate(), endDate.toLocalDate()) + 1;
        return Math.toIntExact(days * shifts.size());
    }

    private int expectedCount(List<Date> targetDates, List<Map<String, String>> shifts) {
        return Math.multiplyExact(targetDates.size(), shifts.size());
    }

    private List<Date> buildTargetDates(Date startDate, Date endDate) {
        List<Date> dates = new ArrayList<>();
        if (startDate == null || endDate == null || startDate.after(endDate)) {
            return dates;
        }
        LocalDate cursor = startDate.toLocalDate();
        while (!cursor.isAfter(endDate.toLocalDate())) {
            dates.add(Date.valueOf(cursor));
            cursor = cursor.plusDays(1);
        }
        return dates;
    }

    private String extractModelText(String response) throws IOException {
        StringBuilder text = new StringBuilder();
        int cursor = 0;
        while (cursor < response.length()) {
            int keyStart = findJsonKey(response, "text", cursor);
            if (keyStart < 0) {
                break;
            }
            int valueStart = skipWhitespace(response, keyStart);
            if (valueStart >= response.length() || response.charAt(valueStart) != '"') {
                cursor = Math.max(valueStart + 1, cursor + 1);
                continue;
            }
            ParsedJsonString parsed = readJsonString(response, valueStart);
            text.append(parsed.value);
            cursor = parsed.nextIndex;
        }
        if (text.length() == 0) {
            throw new IOException("Gemini response không chứa text");
        }
        return text.toString();
    }

    private List<String> extractTopLevelObjects(String json) {
        List<String> objects = new ArrayList<>();
        int arrayStart = json.indexOf('[');
        if (arrayStart < 0) {
            return objects;
        }
        boolean inString = false;
        boolean escaped = false;
        int objectDepth = 0;
        int objectStart = -1;
        for (int i = arrayStart + 1; i < json.length(); i++) {
            char ch = json.charAt(i);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (ch == '\\') {
                    escaped = true;
                } else if (ch == '"') {
                    inString = false;
                }
                continue;
            }
            if (ch == '"') {
                inString = true;
            } else if (ch == '{') {
                if (objectDepth++ == 0) {
                    objectStart = i;
                }
            } else if (ch == '}' && objectDepth > 0) {
                if (--objectDepth == 0 && objectStart >= 0) {
                    objects.add(json.substring(objectStart, i + 1));
                    objectStart = -1;
                }
            } else if (ch == ']' && objectDepth == 0) {
                break;
            }
        }
        return objects;
    }

    private String extractJsonStringOrPrimitive(String objectJson, String key) {
        int valueStart = findJsonKey(objectJson, key, 0);
        if (valueStart < 0 || valueStart >= objectJson.length()) {
            return null;
        }
        valueStart = skipWhitespace(objectJson, valueStart);
        if (valueStart >= objectJson.length()) {
            return null;
        }
        if (objectJson.charAt(valueStart) == '"') {
            return readJsonString(objectJson, valueStart).value;
        }
        int end = valueStart;
        while (end < objectJson.length()
                && objectJson.charAt(end) != ','
                && objectJson.charAt(end) != '}') {
            end++;
        }
        String value = objectJson.substring(valueStart, end).trim();
        return value.isEmpty() || "null".equals(value) ? null : value;
    }

    private int findJsonKey(String json, String key, int fromIndex) {
        String token = "\"" + key + "\"";
        int cursor = Math.max(0, fromIndex);
        while (cursor < json.length()) {
            int keyIndex = json.indexOf(token, cursor);
            if (keyIndex < 0) {
                return -1;
            }
            int colon = skipWhitespace(json, keyIndex + token.length());
            if (colon < json.length() && json.charAt(colon) == ':') {
                return skipWhitespace(json, colon + 1);
            }
            cursor = keyIndex + token.length();
        }
        return -1;
    }

    private int skipWhitespace(String value, int index) {
        int cursor = Math.max(0, index);
        while (cursor < value.length() && Character.isWhitespace(value.charAt(cursor))) {
            cursor++;
        }
        return cursor;
    }

    private ParsedJsonString readJsonString(String json, int quoteIndex) {
        StringBuilder value = new StringBuilder();
        int cursor = quoteIndex + 1;
        while (cursor < json.length()) {
            char ch = json.charAt(cursor++);
            if (ch == '"') {
                return new ParsedJsonString(value.toString(), cursor);
            }
            if (ch != '\\' || cursor >= json.length()) {
                value.append(ch);
                continue;
            }
            char escaped = json.charAt(cursor++);
            switch (escaped) {
                case '"':
                case '\\':
                case '/':
                    value.append(escaped);
                    break;
                case 'b':
                    value.append('\b');
                    break;
                case 'f':
                    value.append('\f');
                    break;
                case 'n':
                    value.append('\n');
                    break;
                case 'r':
                    value.append('\r');
                    break;
                case 't':
                    value.append('\t');
                    break;
                case 'u':
                    if (cursor + 4 <= json.length()) {
                        try {
                            value.append((char) Integer.parseInt(json.substring(cursor, cursor + 4), 16));
                            cursor += 4;
                        } catch (NumberFormatException e) {
                            value.append("\\u");
                        }
                    } else {
                        value.append("\\u");
                    }
                    break;
                default:
                    value.append(escaped);
                    break;
            }
        }
        return new ParsedJsonString(value.toString(), cursor);
    }

    private static final class ParsedJsonString {
        private final String value;
        private final int nextIndex;

        private ParsedJsonString(String value, int nextIndex) {
            this.value = value;
            this.nextIndex = nextIndex;
        }
    }

    private String normalizeDate(String raw) {
        String value = raw == null ? "" : raw.trim();
        if (value.matches("\\d{2}/\\d{2}/\\d{4}")) {
            return LocalDate.parse(value, DISPLAY_DATE).toString();
        }
        return LocalDate.parse(value).toString();
    }

    private String normalizeDepartment(String raw) {
        String value = raw == null ? "" : raw.trim();
        if (value.isEmpty()) {
            return "General";
        }
        String lower = value.toLowerCase();
        if (lower.contains("nội tiết") || lower.contains("tiểu đường") || lower.contains("endocrin")) {
            return "Endocrinology";
        }
        if (lower.contains("tim mạch") || lower.contains("cardio")) {
            return "Cardiology";
        }
        if (lower.contains("thận") || lower.contains("nephro")) {
            return "Nephrology";
        }
        if (lower.contains("tổng quát") || lower.contains("general")) {
            return "General";
        }
        return value;
    }

    private String readBody(HttpURLConnection connection, boolean success) throws IOException {
        InputStream stream = success ? connection.getInputStream() : connection.getErrorStream();
        if (stream == null) {
            return "";
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            StringBuilder body = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
            return body.toString();
        }
    }

    private String decodeJson(String value) {
        return value.replace("\\\"", "\"")
                .replace("\\\\", "\\")
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("\\t", "\t");
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n")
                .replace("\t", "\\t");
    }

    private int number(Object value) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        return Integer.parseInt(String.valueOf(value));
    }

    private String compact(String value) {
        String normalized = value == null ? "" : value.replaceAll("\\s+", " ").trim();
        return normalized.length() <= 180 ? normalized : normalized.substring(0, 177) + "...";
    }

    public static final class SchedulingResult {
        public final boolean success;
        public final List<Map<String, Object>> assignments;
        public final String model;
        public final int keyIndex;
        public final String error;

        private SchedulingResult(boolean success,
                                 List<Map<String, Object>> assignments,
                                 String model,
                                 int keyIndex,
                                 String error) {
            this.success = success;
            this.assignments = assignments;
            this.model = model;
            this.keyIndex = keyIndex;
            this.error = error;
        }

        public static SchedulingResult success(List<Map<String, Object>> assignments, String model, int keyIndex) {
            return new SchedulingResult(true, assignments, model, keyIndex, "");
        }

        public static SchedulingResult failure(String error) {
            return new SchedulingResult(false, new ArrayList<>(), "", 0, error);
        }
    }
}


