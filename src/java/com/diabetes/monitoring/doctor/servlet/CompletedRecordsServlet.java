package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class CompletedRecordsServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = requireDoctor(request, response);
            if (currentUser == null) {
                return;
            }

            int doctorId = getDoctorId(currentUser);
            request.setAttribute("doctorId", doctorId);
            request.setAttribute("completedRecords", dao.getCompletedRecords(doctorId));
            request.setAttribute("completedLaboratoryRequests",
                    dao.getLaboratoryRequestsByDoctor(doctorId, "Completed"));
            request.getRequestDispatcher("/WEB-INF/views/doctor/completedRecords.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Khong the tai danh sach ho so da hoan thanh", e);
        }
    }
}
