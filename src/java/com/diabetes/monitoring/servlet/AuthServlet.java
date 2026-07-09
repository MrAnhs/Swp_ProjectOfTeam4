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
                response.sendRedirect(request.getContextPath() + "/DashboardServlet");
            } else if ("doctor_lab".equalsIgnoreCase(user.getRole())
                    || "Laboratory".equalsIgnoreCase(user.getRole())) {
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            } else {
                response.sendRedirect(request.getContextPath() + "/index.jsp");
            }
        } else {
            request.setAttribute("loginError", "Email hoặc mật khẩu không đúng. Vui lòng thử lại.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }
}
