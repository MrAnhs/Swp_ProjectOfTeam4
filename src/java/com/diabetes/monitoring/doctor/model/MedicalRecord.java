package com.diabetes.monitoring.doctor.model;

import java.sql.Timestamp;
import java.math.BigDecimal;

public class MedicalRecord {

    private int recordId;
    private int healthRecordId;
    private int appointmentId;
    private int patientId;
    private int doctorId;
    private String patientName;
    private String doctorName;
    private String finalDiagnosis;
    private String doctorNote;
    private boolean resultVisibility;
    private Timestamp processedAt;
    private double urea;
    private double cr;
    private double hba1c;
    private double chol;
    private double tg;
    private double hdl;
    private double ldl;
    private double vldl;
    private double bmi;
    private String laboratoryTestTypes;
    private BigDecimal laboratoryTotalPrice;
    private Timestamp revisitDate;
    private double diabetesProbability;
    private double preDiabetesProbability;
    private double normalProbability;

    public int getRecordId() {
        return recordId;
    }

    public void setRecordId(int recordId) {
        this.recordId = recordId;
    }

    public int getHealthRecordId() {
        return healthRecordId;
    }

    public void setHealthRecordId(int healthRecordId) {
        this.healthRecordId = healthRecordId;
    }

    public int getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(int appointmentId) {
        this.appointmentId = appointmentId;
    }

    public int getPatientId() {
        return patientId;
    }

    public void setPatientId(int patientId) {
        this.patientId = patientId;
    }

    public int getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(int doctorId) {
        this.doctorId = doctorId;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName;
    }

    public String getFinalDiagnosis() {
        return finalDiagnosis;
    }

    public void setFinalDiagnosis(String finalDiagnosis) {
        this.finalDiagnosis = finalDiagnosis;
    }

    public String getDoctorNote() {
        return doctorNote;
    }

    public void setDoctorNote(String doctorNote) {
        this.doctorNote = doctorNote;
    }

    public boolean isResultVisibility() {
        return resultVisibility;
    }

    public void setResultVisibility(boolean resultVisibility) {
        this.resultVisibility = resultVisibility;
    }

    public Timestamp getProcessedAt() {
        return processedAt;
    }

    public void setProcessedAt(Timestamp processedAt) {
        this.processedAt = processedAt;
    }

    public double getUrea() { return urea; }
    public void setUrea(double urea) { this.urea = urea; }
    public double getCr() { return cr; }
    public void setCr(double cr) { this.cr = cr; }
    public double getHba1c() { return hba1c; }
    public void setHba1c(double hba1c) { this.hba1c = hba1c; }
    public double getChol() { return chol; }
    public void setChol(double chol) { this.chol = chol; }
    public double getTg() { return tg; }
    public void setTg(double tg) { this.tg = tg; }
    public double getHdl() { return hdl; }
    public void setHdl(double hdl) { this.hdl = hdl; }
    public double getLdl() { return ldl; }
    public void setLdl(double ldl) { this.ldl = ldl; }
    public double getVldl() { return vldl; }
    public void setVldl(double vldl) { this.vldl = vldl; }
    public double getBmi() { return bmi; }
    public void setBmi(double bmi) { this.bmi = bmi; }
    public String getLaboratoryTestTypes() { return laboratoryTestTypes; }
    public void setLaboratoryTestTypes(String laboratoryTestTypes) {
        this.laboratoryTestTypes = laboratoryTestTypes;
    }
    public BigDecimal getLaboratoryTotalPrice() { return laboratoryTotalPrice; }
    public void setLaboratoryTotalPrice(BigDecimal laboratoryTotalPrice) {
        this.laboratoryTotalPrice = laboratoryTotalPrice;
    }

    public Timestamp getRevisitDate() {
        return revisitDate;
    }

    public void setRevisitDate(Timestamp revisitDate) {
        this.revisitDate = revisitDate;
    }

    public double getDiabetesProbability() {
        return diabetesProbability;
    }

    public void setDiabetesProbability(double diabetesProbability) {
        this.diabetesProbability = diabetesProbability;
    }

    public double getPreDiabetesProbability() {
        return preDiabetesProbability;
    }

    public void setPreDiabetesProbability(double preDiabetesProbability) {
        this.preDiabetesProbability = preDiabetesProbability;
    }

    public double getNormalProbability() {
        return normalProbability;
    }

    public void setNormalProbability(double normalProbability) {
        this.normalProbability = normalProbability;
    }
}
