package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class TransferRecordServlet extends DoctorServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            int healthRecordId = Integer.parseInt(request.getParameter("record_id"));
            int toDoctorId = Integer.parseInt(request.getParameter("to_doctor_id"));
            String reason = request.getParameter("reason");
            if (reason == null || reason.isBlank()) {
                reason = "Chuyển giao ca khám tự động / Hết ca làm việc";
            }

            int fromDoctorId = getDoctorId(currentUser);
            boolean success = dao.transferRecord(healthRecordId, fromDoctorId, toDoctorId, reason);

            if (success) {
                request.getSession().setAttribute("doctorMessage",
                        "Đã chuyển giao hồ sơ #" + healthRecordId + " sang Bác sĩ ca tiếp theo thành công.");
            } else {
                request.getSession().setAttribute("doctorMessage",
                        "Không thể chuyển giao hồ sơ #" + healthRecordId + ".");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("doctorMessage",
                    "Lỗi khi chuyển giao hồ sơ: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/doctor/dashboard");
    }
}
