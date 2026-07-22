package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.Notification;
import com.diabetes.monitoring.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class NotificationDAO {

    public boolean insertNotification(Notification notification) {
        String sql = "INSERT INTO Notification (AccountID, Title, Content, Type, IsRead, CreatedAt) VALUES (?, ?, ?, ?, ?, GETDATE())";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (notification.getAccountId() != null) {
                statement.setInt(1, notification.getAccountId());
            } else {
                statement.setNull(1, java.sql.Types.INTEGER);
            }
            statement.setString(2, notification.getTitle());
            statement.setString(3, notification.getContent());
            statement.setString(4, notification.getType());
            statement.setBoolean(5, notification.isRead());
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Notification> getNotificationsByAccountId(int accountId) {
        List<Notification> notifications = new ArrayList<>();
        String sql = "SELECT NotificationID, AccountID, Title, Content, Type, IsRead, CreatedAt FROM Notification WHERE AccountID = ? ORDER BY CreatedAt DESC";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Notification notification = new Notification();
                    notification.setNotificationId(resultSet.getInt("NotificationID"));
                    notification.setAccountId(resultSet.getInt("AccountID"));
                    notification.setTitle(resultSet.getString("Title"));
                    notification.setContent(resultSet.getString("Content"));
                    notification.setType(resultSet.getString("Type"));
                    notification.setRead(resultSet.getBoolean("IsRead"));
                    notification.setCreatedAt(resultSet.getTimestamp("CreatedAt"));
                    notifications.add(notification);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return notifications;
    }

    public boolean markAsRead(int notificationId) {
        String sql = "UPDATE Notification SET IsRead = 1 WHERE NotificationID = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, notificationId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean markAllAsRead(int accountId) {
        String sql = "UPDATE Notification SET IsRead = 1 WHERE AccountID = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public int getUnreadCount(int accountId) {
        String sql = "SELECT COUNT(*) AS unread_count FROM Notification WHERE AccountID = ? AND IsRead = 0";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("unread_count");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}
