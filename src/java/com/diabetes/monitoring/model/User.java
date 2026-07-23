package com.diabetes.monitoring.model;

public class User {
    private int id;
    private String fullName;
    private String email;
    private String password;
    private String role;
    private String gender;
    private String dob;
    private String phone;
    private String address;
    private String emergencyContact;
    private String bloodType;
    private String status;
    private java.sql.Timestamp createdAt;

    public User() {
    }

    public User(String fullName, String email, String password, String role, String gender, String dob, String phone) {
        this.fullName = fullName;
        this.email = email;
        this.password = password;
        this.role = role;
        this.gender = gender;
        this.dob = dob;
        this.phone = phone;
    }

    public User(String fullName, String email, String password, String role, String gender, String dob, String phone, String address, String emergencyContact, String bloodType) {
        this.fullName = fullName;
        this.email = email;
        this.password = password;
        this.role = role;
        this.gender = gender;
        this.dob = dob;
        this.phone = phone;
        this.address = address;
        this.emergencyContact = emergencyContact;
        this.bloodType = bloodType;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
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

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getDob() {
        return dob;
    }

    public void setDob(String dob) {
        this.dob = dob;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public void setEmergencyContact(String emergencyContact) {
        this.emergencyContact = emergencyContact;
    }

    public String getBloodType() {
        return bloodType;
    }

    public void setBloodType(String bloodType) {
        this.bloodType = bloodType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public java.sql.Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(java.sql.Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
