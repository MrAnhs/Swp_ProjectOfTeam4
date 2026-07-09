package com.diabetes.monitoring.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PatientVisit {
    public int appointmentId;
    public String doctorName;
    public String department;
    public LocalDateTime appointmentTime;
    public String appointmentStatus;
    public Integer recordId;
    public boolean resultVisible;
    public String finalDiagnosis;
    public String doctorNote;
    public LocalDateTime processedAt;
    public Integer healthRecordId;
    public String healthRecordStatus;
    public BigDecimal urea, cr, hba1c, chol, tg, hdl, ldl, vldl, bmi, weight, height;
    public String otherInformation;
}
