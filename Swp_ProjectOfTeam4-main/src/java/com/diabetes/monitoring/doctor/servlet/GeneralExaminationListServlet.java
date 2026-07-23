package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class GeneralExaminationListServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = requireDoctor(request, response);
        if (currentUser == null) {
            return;
        }
        try {
            int doctorId = getDoctorId(currentUser);
            request.setAttribute("generalExaminationRecords",
                    dao.getGeneralExaminationRecords(doctorId));
            request.getRequestDispatcher("/WEB-INF/views/doctor/generalExaminationList.jsp")
                    .forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Không thể tải danh sách khám tổng quát", e);
        }
    }
}
