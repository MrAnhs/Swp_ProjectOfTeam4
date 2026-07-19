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

public class AuthenticationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            if (isPageRequest(httpRequest)) {
                httpResponse.sendRedirect(httpRequest.getContextPath() + "/login.jsp");
            } else {
                writeJsonError(httpResponse, HttpServletResponse.SC_UNAUTHORIZED, "Not logged in");
            }
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isPageRequest(HttpServletRequest request) {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        return (path.startsWith("/patient/") && !path.startsWith("/patient/api/"))
                || "/admin".equals(path)
                || path.startsWith("/admin/")
                || (path.startsWith("/receptionist/") && !path.startsWith("/receptionist/api/"))
                || (path.startsWith("/doctor/") && !path.startsWith("/doctor/api/"))
                || (path.startsWith("/doctor-lab/") && !path.startsWith("/doctor-lab/api/"))
                || "/notifications/page".equals(path);
                
    }

    private void writeJsonError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().print("{\"error\":\"" + message + "\"}");
    }
}
