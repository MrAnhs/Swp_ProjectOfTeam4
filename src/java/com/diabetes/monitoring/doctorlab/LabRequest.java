package com.diabetes.monitoring.doctorlab;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class LabRequest {
    private int invoiceDetailId;
    private int invoiceId;
    private int healthRecordId;
    private int patientId;
    private String patientName;
    private String serviceName;
    private BigDecimal price;
    private String requestNote;
    private String labStatus;
    private String invoiceStatus;
    private String labResult;
    private Timestamp requestedAt;
    private Timestamp completedAt;
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

    public int getInvoiceDetailId() { return invoiceDetailId; }
    public void setInvoiceDetailId(int invoiceDetailId) { this.invoiceDetailId = invoiceDetailId; }
    public int getInvoiceId() { return invoiceId; }
    public void setInvoiceId(int invoiceId) { this.invoiceId = invoiceId; }
    public int getHealthRecordId() { return healthRecordId; }
    public void setHealthRecordId(int healthRecordId) { this.healthRecordId = healthRecordId; }
    public int getPatientId() { return patientId; }
    public void setPatientId(int patientId) { this.patientId = patientId; }
    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }
    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public String getRequestNote() { return requestNote; }
    public void setRequestNote(String requestNote) { this.requestNote = requestNote; }
    public String getLabStatus() { return labStatus; }
    public void setLabStatus(String labStatus) { this.labStatus = labStatus; }
    public String getInvoiceStatus() { return invoiceStatus; }
    public void setInvoiceStatus(String invoiceStatus) { this.invoiceStatus = invoiceStatus; }
    public String getLabResult() { return labResult; }
    public void setLabResult(String labResult) { this.labResult = labResult; }
    public Timestamp getRequestedAt() { return requestedAt; }
    public void setRequestedAt(Timestamp requestedAt) { this.requestedAt = requestedAt; }
    public Timestamp getCompletedAt() { return completedAt; }
    public void setCompletedAt(Timestamp completedAt) { this.completedAt = completedAt; }
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

    public String getStatusDisplay() {
        if (labStatus == null) return "";
        switch (labStatus) {
            case "Waiting_Payment": return "Chờ thanh toán";
            case "Requested": return "Chờ xét nghiệm";
            case "Processing": return "Đang xử lý";
            case "Completed": return "Hoàn thành";
            default: return labStatus;
        }
    }
}
