package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

public class SaveVitalsServlet extends DoctorServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        try {
            User currentUser = requireDoctor(request, response);
            if (currentUser == null) {
                return;
            }

            String recordIdStr = request.getParameter("record_id");
            String weightStr = request.getParameter("weight");
            String heightStr = request.getParameter("height");

            if (recordIdStr == null || weightStr == null || heightStr == null) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Thiếu tham số yêu cầu.", 0);
                return;
            }

            int recordId = Integer.parseInt(recordIdStr.trim());
            double weight = Double.parseDouble(weightStr.trim());
            double height = Double.parseDouble(heightStr.trim());

            if (recordId <= 0 || weight <= 0 || height <= 0) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Chiều cao và cân nặng phải lớn hơn 0.", 0);
                return;
            }

            double heightInMeters = height / 100.0;
            double bmi = weight / (heightInMeters * heightInMeters);
            bmi = Math.round(bmi * 100.0) / 100.0; // Round to 2 decimal places

            int doctorId = getDoctorId(currentUser);

            boolean success = dao.updateVitals(recordId, doctorId, weight, height, bmi);
            if (success) {
                sendJson(response, HttpServletResponse.SC_OK, true, "Lưu chỉ số thể chất thành công.", bmi);
            } else {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Không thể lưu chỉ số thể chất. Hồ sơ đã hoàn thành hoặc không thuộc quyền quản lý của bạn.", 0);
            }

        } catch (NumberFormatException e) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "Định dạng số không hợp lệ.", 0);
        } catch (SQLException e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false, "Lỗi cơ sở dữ liệu: " + e.getMessage(), 0);
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false, "Lỗi máy chủ: " + e.getMessage(), 0);
        }
    }

    private void sendJson(HttpServletResponse response, int status, boolean success, String message, double bmi) throws IOException {
        response.setStatus(status);
        response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + escapeJson(message) + "\",\"bmi\":" + bmi + "}");
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
