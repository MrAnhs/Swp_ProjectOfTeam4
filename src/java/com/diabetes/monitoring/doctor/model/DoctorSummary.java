package com.diabetes.monitoring.doctor.model;

public class DoctorSummary {

    private int doctorId;
    private String fullName;
    private String email;
    private String department;

    private int waitingPatients;
    private int maxPatients;

    public DoctorSummary() {
    }

    public DoctorSummary(int doctorId, String fullName, String email, String department) {
        this.doctorId = doctorId;
        this.fullName = fullName;
        this.email = email;
        this.department = department;
    }

    public DoctorSummary(int doctorId, String fullName, String email, String department, int waitingPatients, int maxPatients) {
        this.doctorId = doctorId;
        this.fullName = fullName;
        this.email = email;
        this.department = department;
        this.waitingPatients = waitingPatients;
        this.maxPatients = maxPatients;
    }

    public int getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(int doctorId) {
        this.doctorId = doctorId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public int getWaitingPatients() {
        return waitingPatients;
    }

    public void setWaitingPatients(int waitingPatients) {
        this.waitingPatients = waitingPatients;
    }

    public int getMaxPatients() {
        return maxPatients;
    }

    public void setMaxPatients(int maxPatients) {
        this.maxPatients = maxPatients;
    }

    public String getQueueStatus() {
        if (maxPatients <= 0) {
            return "Không có lịch trực";
        }
        if (waitingPatients < maxPatients) {
            return "Đang khám/chờ: " + waitingPatients + "/" + maxPatients;
        } else {
            int queue = waitingPatients - maxPatients;
            return "Đầy - Hàng đợi: " + queue + " BN";
        }
    }
}
