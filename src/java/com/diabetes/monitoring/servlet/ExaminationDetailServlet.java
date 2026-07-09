package com.diabetes.monitoring.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Compatibility endpoint. All record stages now use DetailServlet and one JSP.
 */
public class ExaminationDetailServlet extends DoctorServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String recordId = request.getParameter("record_id");
        response.sendRedirect(request.getContextPath()
                + "/DetailServlet?record_id=" + recordId);
    }
}
