package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.UserDAO;
import com.diabetes.monitoring.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class AuthServlet extends HttpServlet {
    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        User user = userDAO.validateLogin(email, password);
        if (user != null) {
            HttpSession session = request.getSession();
            session.setAttribute("currentUser", user);
            if ("Patient".equalsIgnoreCase(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/patient/dashboard");
            } else if ("Admin".equalsIgnoreCase(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/admin");
            } else if ("Receptionist".equalsIgnoreCase(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/receptionist/dashboard");
            } else if ("Doctor".equalsIgnoreCase(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/doctor/dashboard");
            } else if (isDoctorLabRole(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            } else {
                response.sendRedirect(request.getContextPath() + "/index.jsp");
            }
        } else {
            request.setAttribute("typedEmail", email != null ? email.trim() : "");
            request.setAttribute("loginError", "Email hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }

    private boolean isDoctorLabRole(String role) {
        if (role == null) {
            return false;
        }
        String normalized = role.trim().replace("-", "_").replace(" ", "_");
        return "doctor_lab".equalsIgnoreCase(normalized);
    }}
