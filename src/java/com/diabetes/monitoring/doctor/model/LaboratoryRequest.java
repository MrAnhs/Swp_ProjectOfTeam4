package com.diabetes.monitoring.doctor.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class LaboratoryRequest {
    private int laboratoryRequestId;
    private int invoiceId;
    private String invoiceStatus;
    private int healthRecordId;
    private int patientId;
    private int doctorId;
    private Integer serviceId;
    private String testType;
    private BigDecimal testPrice;
    private String requestNote;
    private String status;
    private String result;
    private Timestamp requestedAt;
    private Timestamp completedAt;
    private String patientName;
    private Double urea;
    private Double cr;
    private Double hba1c;
    private Double chol;
    private Double tg;
    private Double hdl;
    private Double ldl;
    private Double vldl;
    private Double bmi;
    private Double weight;
    private Double height;
    private Integer labId;
    private String labDoctorName;
    private String labName;

    public int getLaboratoryRequestId() { return laboratoryRequestId; }
    public void setLaboratoryRequestId(int laboratoryRequestId) { this.laboratoryRequestId = laboratoryRequestId; }
    public int getInvoiceId() { return invoiceId; }
    public void setInvoiceId(int invoiceId) { this.invoiceId = invoiceId; }
    public String getInvoiceStatus() { return invoiceStatus; }
    public void setInvoiceStatus(String invoiceStatus) { this.invoiceStatus = invoiceStatus; }
    public String getPaymentStatusDisplay() {
        return "Paid".equalsIgnoreCase(invoiceStatus) ? "Đã thanh toán" : "Chờ thanh toán";
    }
    public int getHealthRecordId() { return healthRecordId; }
    public void setHealthRecordId(int healthRecordId) { this.healthRecordId = healthRecordId; }
    public int getPatientId() { return patientId; }
    public void setPatientId(int patientId) { this.patientId = patientId; }
    public int getDoctorId() { return doctorId; }
    public void setDoctorId(int doctorId) { this.doctorId = doctorId; }
    public Integer getServiceId() { return serviceId; }
    public void setServiceId(Integer serviceId) { this.serviceId = serviceId; }
    public String getTestType() { return testType; }
    public void setTestType(String testType) { this.testType = testType; }
    public BigDecimal getTestPrice() { return testPrice; }
    public void setTestPrice(BigDecimal testPrice) { this.testPrice = testPrice; }
    public String getTestTypeDisplay() {
        if (testType == null) return "";
        switch (testType) {
            case "Blood Test": return "Xét nghiệm máu";
            case "Urine Test": return "Xét nghiệm nước tiểu";
            case "HbA1c Test": return "Xét nghiệm đường huyết";
            case "Xét nghiệm HbA1c": return "Xét nghiệm đường huyết";
            case "Lipid Test": return "Xét nghiệm mỡ máu";
            case "Kidney Function Test": return "Xét nghiệm chức năng thận";
            case "Liver Function Test": return "Xét nghiệm chức năng gan";
            default: return testType;
        }
    }
    public String getRequestNote() { return requestNote; }
    public void setRequestNote(String requestNote) { this.requestNote = requestNote; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getStatusDisplay() {
        if (status == null) return "";
        switch (status) {
            case "Waiting_Payment": return "Chờ thanh toán";
            case "Requested": return "Chờ phòng xét nghiệm";
            case "Processing": return "Đang xử lý";
            case "Completed": return "Đã hoàn thành";
            default: return status;
        }
    }
    public boolean isHasMeasurements() {
        return urea != null || cr != null || hba1c != null || chol != null
                || tg != null || hdl != null || ldl != null || vldl != null
                || bmi != null || weight != null || height != null;
    }
    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }
    public Timestamp getRequestedAt() { return requestedAt; }
    public void setRequestedAt(Timestamp requestedAt) { this.requestedAt = requestedAt; }
    public Timestamp getCompletedAt() { return completedAt; }
    public void setCompletedAt(Timestamp completedAt) { this.completedAt = completedAt; }
    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }
    public Double getUrea() { return urea; }
    public void setUrea(Double urea) { this.urea = urea; }
    public Double getCr() { return cr; }
    public void setCr(Double cr) { this.cr = cr; }
    public Double getHba1c() { return hba1c; }
    public void setHba1c(Double hba1c) { this.hba1c = hba1c; }
    public Double getChol() { return chol; }
    public void setChol(Double chol) { this.chol = chol; }
    public Double getTg() { return tg; }
    public void setTg(Double tg) { this.tg = tg; }
    public Double getHdl() { return hdl; }
    public void setHdl(Double hdl) { this.hdl = hdl; }
    public Double getLdl() { return ldl; }
    public void setLdl(Double ldl) { this.ldl = ldl; }

    public Double getVldl() { return vldl; }
    public void setVldl(Double vldl) { this.vldl = vldl; }
    public Double getBmi() { return bmi; }
    public void setBmi(Double bmi) { this.bmi = bmi; }
    public Double getWeight() { return weight; }
    public void setWeight(Double weight) { this.weight = weight; }
    public Double getHeight() { return height; }
    public void setHeight(Double height) { this.height = height; }

<<<<<<< HEAD
    private Integer labId;
    private String labDoctorName;
    private String labName;

=======
>>>>>>> b6789e344b33b6da54a0d7ea8b6cd470f19497b2
    public Integer getLabId() { return labId; }
    public void setLabId(Integer labId) { this.labId = labId; }
    public String getLabDoctorName() { return labDoctorName; }
    public void setLabDoctorName(String labDoctorName) { this.labDoctorName = labDoctorName; }
    public String getLabName() { return labName; }
    public void setLabName(String labName) { this.labName = labName; }
}
