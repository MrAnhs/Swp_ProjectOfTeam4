package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.dao.AppointmentDAO;
import com.diabetes.monitoring.model.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class DashboardServlet extends DoctorServlet {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            int doctorId = getDoctorId(currentUser);
            request.setAttribute("doctorId", doctorId);
            request.setAttribute("appointmentQueue",
                    appointmentDAO.getWaitingAppointmentsByDoctor(doctorId));
            request.setAttribute("completedRecords", dao.getCompletedRecords(doctorId));
            request.setAttribute("transferHistory", java.util.Collections.emptyList());
            request.getRequestDispatcher("/WEB-INF/views/doctor/doctor.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Khong the tai dashboard bac si", e);
        }
    }
}
