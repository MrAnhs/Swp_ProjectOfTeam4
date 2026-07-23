package com.diabetes.monitoring.filter;

import com.diabetes.monitoring.model.User;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class DoctorLabAuthorizationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/login.jsp");
            return;
        }

        if (!isDoctorLabRole(currentUser.getRole())) {
            httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isDoctorLabRole(String role) {
        if (role == null) {
            return false;
        }
        String normalized = role.trim().replace("-", "_").replace(" ", "_");
        return "doctor_lab".equalsIgnoreCase(normalized);
    }}
