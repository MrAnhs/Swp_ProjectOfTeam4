package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.model.HealthRecord;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

public class ExaminationListServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }

        try {
            int doctorId = getDoctorId(currentUser);
            List<HealthRecord> records = dao.getDetailedExaminationRecords(doctorId);
            request.setAttribute("examinationRecords", records);
            request.getRequestDispatcher("/WEB-INF/views/doctor/examinationList.jsp")
                    .forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Khong the tai danh sach kham chi tiet", e);
        }
    }
}
