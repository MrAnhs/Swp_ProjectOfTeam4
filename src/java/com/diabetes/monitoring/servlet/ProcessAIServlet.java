package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.HealthRecordDAO;
import com.diabetes.monitoring.model.HealthRecord;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

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

public class ProcessAIServlet extends HttpServlet {

    private final Gson gson = new Gson();
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
                        + "/DetailServlet?record_id=" + recordId);
                return;
            }

            if (!dao.hasRequiredAIData(recordId, doctorId)) {
                session.setAttribute("doctorMessage",
                        "Chưa đủ chỉ số xét nghiệm để chạy AI. "
                        + "Vui lòng tạo yêu cầu và chờ phòng xét nghiệm trả kết quả.");
                response.sendRedirect(request.getContextPath()
                        + "/DetailServlet?record_id=" + recordId);
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
            String payload =
                    gson.toJson(record);

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

            /*
             * Parse JSON trả về
             */
            JsonObject aiResult =
                    gson.fromJson(
                            apiResponse,
                            JsonObject.class
                    );

            if (aiResult.has("status")
                    && "error".equalsIgnoreCase(aiResult.get("status").getAsString())) {
                String message = aiResult.has("message")
                        ? aiResult.get("message").getAsString()
                        : "AI không thể xử lý dữ liệu";
                throw new Exception(message);
            }

            if (!aiResult.has("probabilities")) {
                throw new Exception(
                        "AI không trả về probabilities"
                );
            }

            JsonObject probabilities =
                    aiResult.getAsJsonObject(
                            "probabilities"
                    );

            double diabetes =
                    probabilities.get(
                            "Diabetes"
                    ).getAsDouble();

            double pre =
                    probabilities.get(
                            "Pre-Diabetes"
                    ).getAsDouble();

            double normal =
                    probabilities.get(
                            "Normal"
                    ).getAsDouble();

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
                    request.getContextPath() + "/DetailServlet?record_id="
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
                    + "/DetailServlet?record_id=" + recordId);
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
}
