package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.dao.HealthRecordDAO;
import com.diabetes.monitoring.doctor.model.HealthRecord;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import com.diabetes.monitoring.model.User;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ProcessAIServlet extends HttpServlet {

    private final HealthRecordDAO dao = new HealthRecordDAO();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        try {

            int recordId =
                    Integer.parseInt(
                            request.getParameter("record_id")
                    );

            HttpSession session = request.getSession(false);
            if (session == null || !(session.getAttribute("currentUser") instanceof User)) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            User currentUser = (User) session.getAttribute("currentUser");
            if (!"doctor".equalsIgnoreCase(currentUser.getRole())) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            int doctorId = dao.getOrCreateDoctorIdByAccountId(currentUser.getId());
            if (!dao.isRecordAssignedToDoctor(recordId, doctorId)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Ban khong co quyen chay AI cho ho so nay");
                return;
            }

            if (!dao.canRunAI(recordId, doctorId)) {
                session.setAttribute("doctorMessage",
                        "Hồ sơ phải được nhận ca trước khi chạy AI.");
                response.sendRedirect(request.getContextPath()
                        + "/doctor/records/detail?record_id=" + recordId);
                return;
            }

            if (!dao.hasRequiredAIData(recordId, doctorId)) {
                session.setAttribute("doctorMessage",
                        "Chưa đủ chỉ số xét nghiệm để chạy AI. "
                        + "Vui lòng tạo yêu cầu và chờ phòng xét nghiệm trả kết quả.");
                response.sendRedirect(request.getContextPath()
                        + "/doctor/records/detail?record_id=" + recordId);
                return;
            }

            /*
             * Lấy hồ sơ
             */
            HealthRecord record =
                    dao.getHealthRecordById(recordId);

            if (record == null) {
                throw new Exception(
                        "Không tìm thấy hồ sơ ID = "
                                + recordId
                );
            }

            /*
             * Gửi dữ liệu sang AI
             */
            String payload = buildAiPayload(record);

            System.out.println(
                    "SEND TO AI = "
                            + payload
            );

            String apiResponse =
                    callPythonApi(
                            "http://127.0.0.1:5000/predict",
                            payload
                    );

            System.out.println(
                    "AI RESPONSE = "
                            + apiResponse
            );

            if (apiResponse.contains("\"status\"")
                    && apiResponse.toLowerCase().contains("\"error\"")) {
                String message = extractString(apiResponse, "message");
                if (message == null || message.trim().isEmpty()) {
                    message = "AI không thể xử lý dữ liệu";
                }
                throw new Exception(message);
            }

            if (!apiResponse.contains("\"probabilities\"")) {
                throw new Exception(
                        "AI không trả về probabilities"
                );
            }

            double diabetes = extractNumber(apiResponse, "Diabetes");
            double pre = extractNumber(apiResponse, "Pre-Diabetes");
            double normal = extractNumber(apiResponse, "Normal");

            System.out.println(
                    "SAVE AI => "
                            + diabetes + " | "
                            + pre + " | "
                            + normal
            );

            /*
             * Lưu vào bảng Doctor_AI
             */
            boolean saved = dao.saveAiResults(
                    recordId,
                    diabetes,
                    pre,
                    normal
            );

            /*
             * Chỉ chuyển sang trạng thái
             * AI đã xử lý
             */
            if (!saved) {
                throw new Exception("Khong the luu ket qua AI vao database");
            }

            if (!dao.updateRecordStatusForDoctor(recordId, doctorId, "AI_Processed")) {
                throw new Exception("Khong the cap nhat trang thai AI_Processed");
            }

            response.sendRedirect(
                    request.getContextPath() + "/doctor/records/detail?record_id="
                            + recordId
            );

        } catch (Exception e) {

            e.printStackTrace();
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.setAttribute("doctorMessage",
                        "Không thể chạy AI: "
                        + (e.getMessage() == null ? "dịch vụ không phản hồi" : e.getMessage()));
            }
            String recordId = request.getParameter("record_id");
            response.sendRedirect(request.getContextPath()
                    + "/doctor/records/detail?record_id=" + recordId);
        }
    }

    private String callPythonApi(
            String targetUrl,
            String json
    ) throws IOException {

        HttpURLConnection conn =
                (HttpURLConnection)
                        new URL(targetUrl)
                                .openConnection();

        conn.setRequestMethod("POST");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(30000);

        conn.setRequestProperty(
                "Content-Type",
                "application/json"
        );

        conn.setDoOutput(true);

        try (OutputStream os =
                     conn.getOutputStream()) {

            os.write(
                    json.getBytes(
                            StandardCharsets.UTF_8
                    )
            );
        }

        int responseCode =
                conn.getResponseCode();

        boolean success = responseCode >= 200 && responseCode < 300;
        InputStream responseStream = success
                ? conn.getInputStream()
                : conn.getErrorStream();

        if (responseStream == null) {
            conn.disconnect();
            throw new IOException("AI API tra ve HTTP " + responseCode + " khong co noi dung");
        }

        StringBuilder result = new StringBuilder();
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(responseStream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) {
                result.append(line);
            }
        } finally {
            conn.disconnect();
        }

        if (!success) {
            throw new IOException(
                    "AI API tra ve HTTP " + responseCode + ": " + result
            );
        }

        return result.toString();
    }

    private String buildAiPayload(HealthRecord record) {
        return "{"
                + "\"urea\":" + record.getUrea()
                + ",\"cr\":" + record.getCr()
                + ",\"hba1c\":" + record.getHba1c()
                + ",\"chol\":" + record.getChol()
                + ",\"tg\":" + record.getTg()
                + ",\"hdl\":" + record.getHdl()
                + ",\"ldl\":" + record.getLdl()
                + ",\"vldl\":" + record.getVldl()
                + ",\"bmi\":" + record.getBmi()
                + "}";
    }

    private double extractNumber(String json, String key) throws Exception {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key)
                + "\"\\s*:\\s*(-?\\d+(?:\\.\\d+)?)");
        Matcher matcher = pattern.matcher(json);
        if (!matcher.find()) {
            throw new Exception("AI không trả về giá trị " + key);
        }
        return Double.parseDouble(matcher.group(1));
    }

    private String extractString(String json, String key) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key)
                + "\"\\s*:\\s*\"([^\"]*)\"");
        Matcher matcher = pattern.matcher(json);
        return matcher.find() ? matcher.group(1) : null;
    }
}
