package com.diabetes.monitoring.notification;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class NotificationDAO {
    public boolean create(Connection connection, int accountId, String title,
            String content, String type, String targetUrl, String eventKey)
            throws SQLException {
        String sql = "INSERT INTO Notification "
                + "(AccountID, Title, Content, Type, IsRead, CreatedAt, TargetUrl, EventKey) "
                + "SELECT ?, ?, ?, ?, 0, GETDATE(), ?, ? "
                + "WHERE NOT EXISTS (SELECT 1 FROM Notification WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE AccountID = ? AND EventKey = ?)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setString(2, title);
            statement.setString(3, content);
            statement.setString(4, type);
            statement.setString(5, targetUrl);
            statement.setString(6, eventKey);
            statement.setInt(7, accountId);
            statement.setString(8, eventKey);
            return statement.executeUpdate() == 1;
        }
    }

    public int countUnread(int accountId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Notification WHERE AccountID = ? AND ISNULL(IsRead, 0) = 0";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                return result.getInt(1);
            }
        }
    }

    public List<Notification> findLatest(int accountId, int limit) throws SQLException {
        String sql = "SELECT TOP (?) NotificationID, AccountID, Title, Content, Type, "
                + "ISNULL(IsRead, 0) AS IsRead, CreatedAt, TargetUrl "
                + "FROM Notification WHERE AccountID = ? ORDER BY CreatedAt DESC, NotificationID DESC";
        List<Notification> notifications = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            statement.setInt(2, accountId);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) notifications.add(map(result));
            }
        }
        return notifications;
    }

    public boolean markRead(int accountId, int notificationId) throws SQLException {
        String sql = "UPDATE Notification SET IsRead = 1 "
                + "WHERE NotificationID = ? AND AccountID = ? AND ISNULL(IsRead, 0) = 0";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, notificationId);
            statement.setInt(2, accountId);
            return statement.executeUpdate() > 0;
        }
    }

    private Notification map(ResultSet result) throws SQLException {
        Notification notification = new Notification();
        notification.setNotificationId(result.getInt("NotificationID"));
        notification.setAccountId(result.getInt("AccountID"));
        notification.setTitle(result.getString("Title"));
        notification.setContent(result.getString("Content"));
        notification.setType(result.getString("Type"));
        notification.setRead(result.getBoolean("IsRead"));
        notification.setCreatedAt(result.getTimestamp("CreatedAt"));
        notification.setTargetUrl(result.getString("TargetUrl"));
        return notification;
    }
}
