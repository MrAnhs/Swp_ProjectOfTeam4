package com.diabetes.monitoring.doctor.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class TransferRecordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getSession().setAttribute("doctorMessage", "Tính năng chuyển ca / chuyển hồ sơ đã được gỡ bỏ.");
        response.sendRedirect(request.getContextPath() + "/doctor/dashboard");
    }
}
