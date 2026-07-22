package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.NotificationDAO;
import com.diabetes.monitoring.model.Notification;
import com.diabetes.monitoring.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

public class PatientNotificationServlet extends HttpServlet {
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"success\":false,\"message\":\"Bạn chưa đăng nhập.\"}");
            return;
        }

        int accountId = currentUser.getId();
        int unreadCount = notificationDAO.getUnreadCount(accountId);
        List<Notification> notifications = notificationDAO.getNotificationsByAccountId(accountId);

        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"unreadCount\":").append(unreadCount).append(",");
        json.append("\"notifications\":[");
        for (int i = 0; i < notifications.size(); i++) {
            Notification n = notifications.get(i);
            if (i > 0) json.append(",");
            json.append("{");
            json.append("\"notificationId\":").append(n.getNotificationId()).append(",");
            json.append("\"title\":\"").append(escape(n.getTitle())).append("\",");
            json.append("\"content\":\"").append(escape(n.getContent())).append("\",");
            json.append("\"type\":\"").append(escape(n.getType())).append("\",");
            json.append("\"isRead\":").append(n.isRead()).append(",");
            json.append("\"createdAt\":\"").append(n.getCreatedAt() != null ? n.getCreatedAt().toString() : "").append("\"");
            json.append("}");
        }
        json.append("]");
        json.append("}");

        response.getWriter().print(json.toString());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"success\":false,\"message\":\"Bạn chưa đăng nhập.\"}");
            return;
        }

        String action = request.getParameter("action");
        if ("markRead".equals(action)) {
            try {
                int notificationId = Integer.parseInt(request.getParameter("notificationId"));
                boolean success = notificationDAO.markAsRead(notificationId);
                response.getWriter().print("{\"success\":" + success + "}");
            } catch (NumberFormatException e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().print("{\"success\":false,\"message\":\"Mã thông báo không hợp lệ.\"}");
            }
        } else if ("markAllRead".equals(action)) {
            boolean success = notificationDAO.markAllAsRead(currentUser.getId());
            response.getWriter().print("{\"success\":" + success + "}");
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"success\":false,\"message\":\"Hành động không được hỗ trợ.\"}");
        }
    }

    private String escape(String raw) {
        if (raw == null) return "";
        return raw.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\b", "\\b")
                  .replace("\f", "\\f")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t");
    }
}
