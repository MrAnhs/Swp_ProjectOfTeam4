package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.notification.Notification;
import com.diabetes.monitoring.notification.NotificationService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.List;

public class NotificationServlet extends HttpServlet {
    private final NotificationService notificationService = new NotificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = currentUser(request.getSession(false));
        if (user == null) {
            writeError(response, 401, "Phiên đăng nhập đã hết hạn");
            return;
        }

        String path = request.getPathInfo();
        if ("/page".equals(path)) {
            request.getRequestDispatcher("/WEB-INF/views/notifications.jsp").forward(request, response);
            return;
        }

        try {
            if ("/unread-count".equals(path)) {
                writeJson(response, "{\"count\":" + notificationService.countUnread(user.getId()) + "}");
                return;
            }
            List<Notification> notifications = "/all".equals(path)
                    ? notificationService.findAll(user.getId())
                    : notificationService.findLatest(user.getId());
            writeJson(response, toJson(notifications));
        } catch (Exception e) {
            getServletContext().log("Kh\u00f4ng th\u1ec3 t\u1ea3i th\u00f4ng b\u00e1o", e);
            writeError(response, 500, "Kh\u00f4ng th\u1ec3 t\u1ea3i th\u00f4ng b\u00e1o");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = currentUser(request.getSession(false));
        if (user == null) {
            writeError(response, 401, "Phiên đăng nhập đã hết hạn");
            return;
        }
        String path = request.getPathInfo();
        if (path == null || !path.matches("/\\d+/read")) {
            writeError(response, 400, "Đường dẫn thông báo không hợp lệ");
            return;
        }
        try {
            int notificationId = Integer.parseInt(path.substring(1, path.length() - 5));
            boolean updated = notificationService.markRead(user.getId(), notificationId);
            writeJson(response, "{\"success\":true,\"updated\":" + updated + "}");
        } catch (NumberFormatException e) {
            writeError(response, 400, "Mã thông báo không hợp lệ");
        } catch (Exception e) {
            getServletContext().log("Kh\u00f4ng th\u1ec3 c\u1eadp nh\u1eadt th\u00f4ng b\u00e1o", e);
            writeError(response, 500, "Kh\u00f4ng th\u1ec3 c\u1eadp nh\u1eadt th\u00f4ng b\u00e1o");
        }
    }

    private String toJson(List<Notification> notifications) {
        StringBuilder json = new StringBuilder("{\"notifications\":[");
        for (int i = 0; i < notifications.size(); i++) {
            if (i > 0) json.append(',');
            appendJson(json, notifications.get(i));
        }
        return json.append("]}").toString();
    }

    private void appendJson(StringBuilder json, Notification notification) {
        json.append("{\"id\":").append(notification.getNotificationId())
                .append(",\"title\":\"").append(escape(notification.getTitle()))
                .append("\",\"content\":\"").append(escape(notification.getContent()))
                .append("\",\"type\":\"").append(escape(notification.getType()))
                .append("\",\"isRead\":").append(notification.isRead())
                .append(",\"createdAt\":\"").append(escape(format(notification.getCreatedAt())))
                .append("\",\"targetUrl\":");
        if (notification.getTargetUrl() == null || notification.getTargetUrl().isBlank()) {
            json.append("null");
        } else {
            json.append('"').append(escape(notification.getTargetUrl())).append('"');
        }
        json.append('}');
    }

    private String format(Timestamp timestamp) {
        return timestamp == null ? "" : timestamp.toLocalDateTime().toString();
    }

    private String escape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t");
    }

    private User currentUser(HttpSession session) {
        return session == null ? null : (User) session.getAttribute("currentUser");
    }

    private void writeJson(HttpServletResponse response, String body) throws IOException {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(body);
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        writeJson(response, "{\"error\":\"" + escape(message) + "\"}");
    }
}
