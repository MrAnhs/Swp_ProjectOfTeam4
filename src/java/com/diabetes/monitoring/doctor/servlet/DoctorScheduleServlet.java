package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class DoctorScheduleServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = requireDoctor(request, response);
            if (currentUser == null) {
                return;
            }

            request.setAttribute("schedules", dao.getDoctorSchedulesByAccountId(currentUser.getId()));
            request.getRequestDispatcher("/WEB-INF/views/doctor/schedule.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Khong the tai lich truc bac si", e);
        }
    }
}
