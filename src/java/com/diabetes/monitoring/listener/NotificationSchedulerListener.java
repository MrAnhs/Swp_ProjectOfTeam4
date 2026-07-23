package com.diabetes.monitoring.listener;

import com.diabetes.monitoring.dao.NotificationDAO;
import com.diabetes.monitoring.model.Notification;
import com.diabetes.monitoring.util.DatabaseConnection;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

public class NotificationSchedulerListener implements ServletContextListener {
    private static final Logger LOGGER = Logger.getLogger(NotificationSchedulerListener.class.getName());
    private ScheduledExecutorService scheduler;
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        LOGGER.info("Starting Notification Scheduler...");
        scheduler = Executors.newSingleThreadScheduledExecutor();
        
        // Chạy lần đầu sau 10 giây khi server chạy, sau đó lặp lại mỗi 24 giờ
        scheduler.scheduleAtFixedRate(new RevisitReminderTask(), 10, 24 * 60 * 60, TimeUnit.SECONDS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        LOGGER.info("Stopping Notification Scheduler...");
        if (scheduler != null) {
            scheduler.shutdownNow();
        }
    }

    private class RevisitReminderTask implements Runnable {
        @Override
        public void run() {
            LOGGER.info("Executing Revisit Reminder Task...");
            String sql = "SELECT mr.record_id, p.account_id, p.full_name, mr.revisit_date " +
                         "FROM Medical_record mr " +
                         "JOIN Patient p ON mr.patient_id = p.patient_id " +
                         "WHERE mr.revisit_date IS NOT NULL " +
                         "  AND DATEDIFF(day, GETDATE(), mr.revisit_date) = 2 " +
                         "  AND NOT EXISTS ( " +
                         "      SELECT 1 FROM Notification n " +
                         "      WHERE n.AccountID = p.account_id " +
                         "        AND n.Type = 'RevisitReminder' " +
                         "        AND CAST(n.CreatedAt AS DATE) = CAST(GETDATE() AS DATE) " +
                         "  )";

            try (Connection connection = DatabaseConnection.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql);
                 ResultSet resultSet = statement.executeQuery()) {

                int count = 0;
                while (resultSet.next()) {
                    int accountId = resultSet.getInt("account_id");
                    String fullName = resultSet.getString("full_name");
                    java.sql.Date revisitDate = resultSet.getDate("revisit_date");

                    String title = "Nhắc nhở lịch tái khám sau 2 ngày nữa";
                    String content = String.format("Chào bệnh nhân %s, bạn có lịch hẹn tái khám sau 2 ngày nữa (%s). Vui lòng chuẩn bị và sắp xếp thời gian đến khám.",
                            fullName, revisitDate.toString());

                    Notification notification = new Notification(accountId, title, content, "RevisitReminder");
                    if (notificationDAO.insertNotification(notification)) {
                        count++;
                    }
                }
                LOGGER.info("Revisit Reminder Task completed. Sent " + count + " notification(s).");
            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Error in RevisitReminderTask", e);
            }
        }
    }
}
