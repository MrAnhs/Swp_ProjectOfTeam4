package com.diabetes.monitoring.model;

import java.time.LocalDate;

public class DoctorScheduleInfo {
    private int scheduleId;
    private LocalDate workDate;
    private String timeSlot;
    private int maxPatients;
    private int bookedPatients;
    private String status;

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

    public int getBookedPatients() {
        return bookedPatients;
    }

    public void setBookedPatients(int bookedPatients) {
        this.bookedPatients = bookedPatients;
    }

    public int getAvailableSlots() {
        return Math.max(0, maxPatients - bookedPatients);
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
