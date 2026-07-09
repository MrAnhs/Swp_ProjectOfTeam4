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

public class PatientAuthorizationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            httpResponse.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        if (!"Patient".equalsIgnoreCase(currentUser.getRole())) {
            if (isPageRequest(httpRequest)) {
                httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN);
            } else {
                writeJsonError(httpResponse, HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập.");
            }
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isPageRequest(HttpServletRequest request) {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        return path.startsWith("/patient/") && !path.startsWith("/patient/api/");
    }

    private void writeJsonError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().print("{\"error\":\"" + message + "\"}");
    }
}
