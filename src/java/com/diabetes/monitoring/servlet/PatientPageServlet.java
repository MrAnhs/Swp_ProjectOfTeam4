package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class PatientPageServlet extends HttpServlet {

    private static final String PATIENT_VIEW_ROOT = "/WEB-INF/views/patient/";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!"Patient".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String view = resolveView(request.getServletPath());
        if (view == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        request.getRequestDispatcher(PATIENT_VIEW_ROOT + view).forward(request, response);
    }

    private String resolveView(String servletPath) {
        if ("/patient/dashboard".equals(servletPath)) {
            return "dashboard.jsp";
        }
        if ("/patient/ai-chat".equals(servletPath)) {
            return "ai-chat.jsp";
        }
        if ("/patient/appointments/new".equals(servletPath)) {
            return "appointment-booking.jsp";
        }
        if ("/patient/appointments".equals(servletPath)) {
            return "appointment-list.jsp";
        }
        if ("/patient/appointments/detail".equals(servletPath)) {
            return "appointment-detail.jsp";
        }
        if ("/patient/invoices".equals(servletPath)) {
            return "invoice-list.jsp";
        }
        if ("/patient/invoices/detail".equals(servletPath)) {
            return "invoice-detail.jsp";
        }
        if ("/patient/history".equals(servletPath)) {
            return "visit-history.jsp";
        }
        if ("/patient/history/detail".equals(servletPath)) {
            return "visit-detail.jsp";
        }
        if ("/patient/profile".equals(servletPath)) {
            return "profile.jsp";
        }
        return null;
    }
}
