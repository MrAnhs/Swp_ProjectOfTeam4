package com.diabetes.monitoring.doctor.servlet;

import com.diabetes.monitoring.doctor.dao.HealthRecordDAO;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Common authentication and request helpers for doctor-only servlets.
 */
public abstract class DoctorServlet extends HttpServlet {

    protected final HealthRecordDAO dao = new HealthRecordDAO();

    protected User requireDoctor(
            HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null
                || !(session.getAttribute("currentUser") instanceof User)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return null;
        }

        User currentUser = (User) session.getAttribute("currentUser");
        if (currentUser == null || currentUser.getRole() == null || !currentUser.getRole().toLowerCase().contains("doctor")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return null;
        }
        return currentUser;
    }

    protected int getDoctorId(User currentUser) throws SQLException {
        return dao.getOrCreateDoctorIdByAccountId(currentUser.getId());
    }

    protected int getRecordId(HttpServletRequest request) {
        return Integer.parseInt(request.getParameter("record_id"));
    }

    protected String recordUrl(HttpServletRequest request, String servlet, int recordId) {
        return request.getContextPath() + "/" + servlet + "?record_id=" + recordId;
    }
}
