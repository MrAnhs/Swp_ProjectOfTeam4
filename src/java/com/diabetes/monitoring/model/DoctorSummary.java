package com.diabetes.monitoring.model;

public class DoctorSummary {

    private int doctorId;
    private String fullName;
    private String email;
    private String department;

    public DoctorSummary() {
    }

    public DoctorSummary(int doctorId, String fullName, String email, String department) {
        this.doctorId = doctorId;
        this.fullName = fullName;
        this.email = email;
        this.department = department;
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
}
