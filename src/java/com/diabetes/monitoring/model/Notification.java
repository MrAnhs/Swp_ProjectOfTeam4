package com.diabetes.monitoring.model;

import java.sql.Timestamp;

public class Notification {
    private int notificationId;
    private Integer accountId;
    private String title;
    private String content;
    private String type;
    private boolean isRead;
    private Timestamp createdAt;

    public Notification() {
    }

    public Notification(Integer accountId, String title, String content, String type) {
        this.accountId = accountId;
        this.title = title;
        this.content = content;
        this.type = type;
        this.isRead = false;
    }

    public int getNotificationId() {
        return notificationId;
    }

    public void setNotificationId(int notificationId) {
        this.notificationId = notificationId;
    }

    public Integer getAccountId() {
        return accountId;
    }

    public void setAccountId(Integer accountId) {
        this.accountId = accountId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean read) {
        isRead = read;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
