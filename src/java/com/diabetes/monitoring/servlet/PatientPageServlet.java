package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

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

        String servletPath = request.getServletPath();
        String view = resolveView(servletPath);
        if (view == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        if ("/patient/ai-chat".equals(servletPath)) {
            Integer patientId = findPatientId(currentUser);
            if (patientId != null) {
                String history = (String) session.getAttribute("chatHistory_" + patientId);
                int turnCount = 0;
                if (history != null) {
                    int idx = 0;
                    while ((idx = history.indexOf("Patient:", idx)) != -1) {
                        turnCount++;
                        idx += "Patient:".length();
                    }
                }
                request.setAttribute("reachedLimit", turnCount >= 10);
                request.setAttribute("turnCount", turnCount);
            }
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
        if ("/patient/health-records/new".equals(servletPath)) {
            return "health-record-form.jsp";
        }
        if ("/patient/health-records".equals(servletPath)) {
            return "health-record-list.jsp";
        }
        if ("/patient/health-records/detail".equals(servletPath)) {
            return "health-record-detail.jsp";
        }
        if ("/patient/profile".equals(servletPath)) {
            return "profile.jsp";
        }
        return null;
    }

    private Integer findPatientId(User user) {
        if (user == null || user.getEmail() == null) return null;
        String sql = "SELECT patient_id FROM Patient WHERE email = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, user.getEmail());
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("patient_id");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}
