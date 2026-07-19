package com.diabetes.monitoring.doctor.model;

import java.sql.Timestamp;

public class TransferHistory {

    private int transferId;
    private int healthRecordId;
    private int fromDoctorId;
    private int toDoctorId;
    private String fromDoctorName;
    private String toDoctorName;
    private String patientName;
    private String reason;
    private Timestamp createdAt;

    public int getTransferId() {
        return transferId;
    }

    public void setTransferId(int transferId) {
        this.transferId = transferId;
    }

    public int getHealthRecordId() {
        return healthRecordId;
    }

    public void setHealthRecordId(int healthRecordId) {
        this.healthRecordId = healthRecordId;
    }

    public int getFromDoctorId() {
        return fromDoctorId;
    }

    public void setFromDoctorId(int fromDoctorId) {
        this.fromDoctorId = fromDoctorId;
    }

    public int getToDoctorId() {
        return toDoctorId;
    }

    public void setToDoctorId(int toDoctorId) {
        this.toDoctorId = toDoctorId;
    }

    public String getFromDoctorName() {
        return fromDoctorName;
    }

    public void setFromDoctorName(String fromDoctorName) {
        this.fromDoctorName = fromDoctorName;
    }

    public String getToDoctorName() {
        return toDoctorName;
    }

    public void setToDoctorName(String toDoctorName) {
        this.toDoctorName = toDoctorName;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
