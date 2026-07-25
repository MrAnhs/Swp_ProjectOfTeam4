package com.diabetes.monitoring.model;

import java.time.LocalDate;

public class DoctorScheduleInfo {
    private int scheduleId;
    private LocalDate workDate;
    private String timeSlot;
    private int maxPatients;
    private Integer onlineQuota;
    private int bookedPatients;
    private int onlineBookedPatients;
    private String status;
    private String roomId;
    private String roomName;
    private String roomLocation;

    public int getScheduleId() {
        return scheduleId;
    }

    public void setScheduleId(int scheduleId) {
        this.scheduleId = scheduleId;
    }

    public LocalDate getWorkDate() {
        return workDate;
    }

    public void setWorkDate(LocalDate workDate) {
        this.workDate = workDate;
    }

    public String getTimeSlot() {
        return timeSlot;
    }

    public void setTimeSlot(String timeSlot) {
        this.timeSlot = timeSlot;
    }

    public int getMaxPatients() {
        return maxPatients;
    }

    public void setMaxPatients(int maxPatients) {
        this.maxPatients = maxPatients;
    }

    public Integer getOnlineQuota() {
        return onlineQuota;
    }

    public void setOnlineQuota(Integer onlineQuota) {
        this.onlineQuota = onlineQuota;
    }

    public int getEffectiveOnlineQuota() {
        if (onlineQuota != null && onlineQuota >= 0) {
            return Math.min(onlineQuota, Math.max(0, maxPatients));
        }
        if (maxPatients <= 1) {
            return Math.max(0, maxPatients);
        }
        int quota = (int) Math.ceil(maxPatients * 0.6);
        if (quota >= maxPatients) {
            quota = maxPatients - 1;
        }
        return Math.max(1, quota);
    }

    public int getBookedPatients() {
        return bookedPatients;
    }

    public void setBookedPatients(int bookedPatients) {
        this.bookedPatients = bookedPatients;
    }

    public int getOnlineBookedPatients() {
        return onlineBookedPatients;
    }

    public void setOnlineBookedPatients(int onlineBookedPatients) {
        this.onlineBookedPatients = onlineBookedPatients;
    }

    public int getAvailableSlots() {
        int remainingOnline = getEffectiveOnlineQuota() - onlineBookedPatients;
        int remainingTotal = maxPatients - bookedPatients;
        return Math.max(0, Math.min(remainingOnline, remainingTotal));
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRoomId() {
        return roomId;
    }

    public void setRoomId(String roomId) {
        this.roomId = roomId;
    }

    public String getRoomName() {
        return roomName;
    }

    public void setRoomName(String roomName) {
        this.roomName = roomName;
    }

    public String getRoomLocation() {
        return roomLocation;
    }

    public void setRoomLocation(String roomLocation) {
        this.roomLocation = roomLocation;
    }
}
