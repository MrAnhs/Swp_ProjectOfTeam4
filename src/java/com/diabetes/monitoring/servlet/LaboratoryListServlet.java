package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class LaboratoryListServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            String status = request.getParameter("status");
            int doctorId = getDoctorId(currentUser);
            request.setAttribute("selectedStatus",
                    status == null || status.trim().isEmpty() ? "All" : status);
            request.setAttribute("laboratoryRequests",
                    dao.getLaboratoryRequestsByDoctor(doctorId, status));
            request.getRequestDispatcher("/doctor/laboratoryRequests.jsp")
                    .forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Khong the tai danh sach xet nghiem", e);
        }
    }
}
