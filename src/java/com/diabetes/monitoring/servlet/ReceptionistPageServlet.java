package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class ReceptionistPageServlet extends HttpServlet {

    private static final String VIEW_ROOT = "/WEB-INF/views/receptionist/";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!"Receptionist".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String view = resolveView(request.getServletPath());
        if (view == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        request.getRequestDispatcher(VIEW_ROOT + view).forward(request, response);
    }

    private String resolveView(String servletPath) {
        if ("/receptionist/dashboard".equals(servletPath)) {
            return "dashboard.jsp";
        }
        if ("/receptionist/patients/search".equals(servletPath)) {
            return "patient-search.jsp";
        }
        if ("/receptionist/appointments/new".equals(servletPath)) {
            return "appointment-registration.jsp";
        }
        if ("/receptionist/queue".equals(servletPath)) {
            return "queue-management.jsp";
        }
        if ("/receptionist/billing".equals(servletPath)) {
            return "billing-management.jsp";
        }
        return null;
    }
}
