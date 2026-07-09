package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class AcceptRecordServlet extends DoctorServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            int appointmentId =
                    Integer.parseInt(request.getParameter("appointment_id"));
            int healthRecordId =
                    dao.acceptAppointment(appointmentId, getDoctorId(currentUser));
            request.getSession().setAttribute(
                    "doctorMessage", "Đã tiếp nhận lịch hẹn #" + appointmentId);
            response.sendRedirect(recordUrl(
                    request, "DetailServlet", healthRecordId) + "#laboratoryOrder");
        } catch (Exception e) {
            request.getSession().setAttribute(
                    "doctorMessage", "Không thể tiếp nhận lịch hẹn: " + e.getMessage());
            response.sendRedirect(
                    request.getContextPath() + "/DashboardServlet");
        }
    }
}
