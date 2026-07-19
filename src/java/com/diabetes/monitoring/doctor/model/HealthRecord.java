package com.diabetes.monitoring.doctor.model;

import java.sql.Timestamp;

public class HealthRecord {

   
    private int healthRecordId;
    private Integer medicalRecordId;
    private Integer invoiceDetailId;
    private double urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi;
    private int patientId;
    private String patientName;
    private double weight, height;
    private String otherInformation;
    private String status;
    private Integer doctorId;
    private String doctorName;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private Timestamp processedAt;
    private boolean canPatientView;
    private String doctor_notes;
    private String finalDiagnosis;
    private int age;
    private String gender;
    private double diabetes_probability;
    private double pre_diabetes_probability;
    private double normal_probability;
    private int waitingDays;
    private int priorityLevel;
    private boolean syncedAutomatically;
    private Timestamp syncedAt;
    private Timestamp revisitDate;

    public HealthRecord() {
    }

    public HealthRecord(int healthRecordId, String status, String patientName, int age, String gender,
            double urea, double cr, double hba1c, double chol,
            double tg, double hdl, double ldl, double vldl, double bmi) {
        this.healthRecordId = healthRecordId;
        this.status = status;
        this.patientName = patientName;
        this.age = age;
        this.gender = gender;
        this.urea = urea;
        this.cr = cr;
        this.hba1c = hba1c;
        this.chol = chol;
        this.tg = tg;
        this.hdl = hdl;
        this.ldl = ldl;
        this.vldl = vldl;
        this.bmi = bmi;
    }

    public int getWaitingDays() {
        return waitingDays;
    }

    public Integer getMedicalRecordId() {
        return medicalRecordId;
    }

    public void setMedicalRecordId(Integer medicalRecordId) {
        this.medicalRecordId = medicalRecordId;
    }

    public Integer getInvoiceDetailId() {
        return invoiceDetailId;
    }

    public void setInvoiceDetailId(Integer invoiceDetailId) {
        this.invoiceDetailId = invoiceDetailId;
    }

    public boolean isSyncedAutomatically() {
        return syncedAutomatically;
    }

    public void setSyncedAutomatically(boolean syncedAutomatically) {
        this.syncedAutomatically = syncedAutomatically;
    }

    public Timestamp getSyncedAt() {
        return syncedAt;
    }

    public void setSyncedAt(Timestamp syncedAt) {
        this.syncedAt = syncedAt;
    }

    public void setWaitingDays(int waitingDays) {
        this.waitingDays = waitingDays;
    }

    public int getPriorityLevel() {
        return priorityLevel;
    }

    public void setPriorityLevel(int priorityLevel) {
        this.priorityLevel = priorityLevel;
    }

    public String getDoctor_notes() {
        return doctor_notes;
    }

    public void setDoctor_notes(String doctor_notes) {
        this.doctor_notes = doctor_notes;
    }

    public String getFinalDiagnosis() {
        return finalDiagnosis;
    }

    public void setFinalDiagnosis(String finalDiagnosis) {
        this.finalDiagnosis = finalDiagnosis;
    }

    public void setAiResults(double diabetes, double preDiabetes, double normal) {
        this.diabetes_probability = diabetes;
        this.pre_diabetes_probability = preDiabetes;
        this.normal_probability = normal;
    }

    public boolean isCanPatientView() {
        return canPatientView;
    }

    public void setCanPatientView(boolean canPatientView) {
        this.canPatientView = canPatientView;
    }

    public String getStatusDisplayText() {
        if (status == null || status.isEmpty()) {
            return "Chờ xử lý";
        }
        switch (status) {
            case "Assigned":
                return "Đã phân công";
            case "Accepted":
                return "Đã tiếp nhận";
            case "AI_Processed":
                return "AI đã phân tích";
            case "Completed":
                return "Đã hoàn thành";
            case "Editing":
                return "Được phép chỉnh sửa";
            case "pending":
            case "Pending":
                return "Chờ xử lý";
            case "processing":
            case "Processing":
                return "Đang xử lý";
            case "completed":
                return "Đã hoàn thành";
            default:
                return status;
        }
    }

    public String getStatusBadgeClass() {
        if (status == null || status.isEmpty()) {
            return "bg-warning text-dark";
        }
        switch (status) {
            case "Assigned":
            case "pending":
            case "Pending":
                return "bg-warning text-dark";
            case "Accepted":
            case "processing":
            case "Processing":
                return "bg-primary";
            case "AI_Processed":
                return "bg-info text-dark";
            case "Editing":
                return "bg-warning text-dark";
            case "Completed":
            case "completed":
                return "bg-success";
            default:
                return "bg-secondary";
        }
    }

    public boolean isAssigned() {
        return doctorId != null;
    }

    public double getUrea() {
        return urea;
    }

    public void setUrea(double urea) {
        this.urea = urea;
    }

    public double getCr() {
        return cr;
    }

    public void setCr(double cr) {
        this.cr = cr;
    }

    public double getHba1c() {
        return hba1c;
    }

    public void setHba1c(double hba1c) {
        this.hba1c = hba1c;
    }

    public double getChol() {
        return chol;
    }

    public void setChol(double chol) {
        this.chol = chol;
    }

    public double getTg() {
        return tg;
    }

    public void setTg(double tg) {
        this.tg = tg;
    }

    public double getHdl() {
        return hdl;
    }

    public void setHdl(double hdl) {
        this.hdl = hdl;
    }

    public double getLdl() {
        return ldl;
    }

    public void setLdl(double ldl) {
        this.ldl = ldl;
    }

    public double getVldl() {
        return vldl;
    }

    public void setVldl(double vldl) {
        this.vldl = vldl;
    }

    public double getBmi() {
        return bmi;
    }

    public void setBmi(double bmi) {
        this.bmi = bmi;
    }

    public int getPatientId() {
        return patientId;
    }

    public void setPatientId(int patientId) {
        this.patientId = patientId;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public double getWeight() {
        return weight;
    }

    public void setWeight(double weight) {
        this.weight = weight;
    }

    public double getHeight() {
        return height;
    }

    public void setHeight(double height) {
        this.height = height;
    }

    public String getOtherInformation() {
        return otherInformation;
    }

    public void setOtherInformation(String otherInformation) {
        this.otherInformation = otherInformation;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(Integer doctorId) {
        this.doctorId = doctorId;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Timestamp getProcessedAt() {
        return processedAt;
    }

    public void setProcessedAt(Timestamp processedAt) {
        this.processedAt = processedAt;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public double getDiabetes_probability() {
        return diabetes_probability;
    }

    public void setDiabetes_probability(double diabetes_probability) {
        this.diabetes_probability = diabetes_probability;
    }

    public double getPre_diabetes_probability() {
        return pre_diabetes_probability;
    }

    public void setPre_diabetes_probability(double pre_diabetes_probability) {
        this.pre_diabetes_probability = pre_diabetes_probability;
    }

    public double getNormal_probability() {
        return normal_probability;
    }

    public void setNormal_probability(double normal_probability) {
        this.normal_probability = normal_probability;
    }

    public int getHealthRecordId() {
        return healthRecordId;
    }

    public void setHealthRecordId(int healthRecordId) {
        this.healthRecordId = healthRecordId;
    }

    public int getRecord_id() {
        return this.healthRecordId;
    }

    public Timestamp getRevisitDate() {
        return revisitDate;
    }

    public void setRevisitDate(Timestamp revisitDate) {
        this.revisitDate = revisitDate;
    }

    public String getRevisitDateFormatted() {
        if (revisitDate == null) {
            return "";
        }
        return new java.text.SimpleDateFormat("yyyy-MM-dd").format(revisitDate);
    }
}
