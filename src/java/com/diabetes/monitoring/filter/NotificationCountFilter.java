package com.diabetes.monitoring.filter;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.notification.NotificationService;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class NotificationCountFilter implements Filter {
    private static final long REMINDER_CHECK_INTERVAL_MILLIS = 5 * 60 * 1000L;
    private static final String LAST_REMINDER_CHECK =
            NotificationCountFilter.class.getName() + ".lastReminderCheck";
    private final NotificationService notificationService = new NotificationService();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpSession session = httpRequest.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("currentUser");
        if (user != null) {
            try {
                if ("Patient".equalsIgnoreCase(user.getRole())) {
                    Long lastCheck = (Long) session.getAttribute(LAST_REMINDER_CHECK);
                    long now = System.currentTimeMillis();
                    if (lastCheck == null || now - lastCheck >= REMINDER_CHECK_INTERVAL_MILLIS) {
                        notificationService.createUpcomingAppointmentReminders(user.getId());
                        session.setAttribute(LAST_REMINDER_CHECK, now);
                    }
                }
                request.setAttribute("unreadNotificationCount", notificationService.countUnread(user.getId()));
            } catch (Exception e) {
                httpRequest.getServletContext().log("Không thể đếm thông báo chưa đọc", e);
                request.setAttribute("unreadNotificationCount", 0);
            }
        }
        chain.doFilter(request, response);
    }
}
