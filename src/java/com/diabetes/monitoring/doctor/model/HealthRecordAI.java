package com.diabetes.monitoring.doctor.model;

public class HealthRecordAI {

    private int record_id;
    private String patientName;
    private String status;
    private double diabetesProb;
    private double preDiabetesProb;
    private double normalProb;

    public HealthRecordAI(int record_id, String patientName, String status,
            double diabetesProb, double preDiabetesProb, double normalProb) {
        this.record_id = record_id;
        this.patientName = patientName;
        this.status = status;
        this.diabetesProb = diabetesProb;
        this.preDiabetesProb = preDiabetesProb;
        this.normalProb = normalProb;
    }

    public void setAiResults(double diabetesProb, double preDiabetesProb, double normalProb) {
        this.diabetesProb = diabetesProb;
        this.preDiabetesProb = preDiabetesProb;
        this.normalProb = normalProb;
    }

    public int getRecord_id() {
        return record_id;
    }

    public void setRecord_id(int record_id) {
        this.record_id = record_id;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public double getDiabetesProb() {
        return diabetesProb;
    }

    public void setDiabetesProb(double diabetesProb) {
        this.diabetesProb = diabetesProb;
    }

    public double getPreDiabetesProb() {
        return preDiabetesProb;
    }

    public void setPreDiabetesProb(double preDiabetesProb) {
        this.preDiabetesProb = preDiabetesProb;
    }

    public double getNormalProb() {
        return normalProb;
    }

    public void setNormalProb(double normalProb) {
        this.normalProb = normalProb;
    }
}
