package com.diabetes.monitoring.model;

import java.sql.Timestamp;

public class RecordSharing {
    private int sharingId;
    private int ownerAccountId;
    private int viewerAccountId;
    private int initiatorAccountId;
    private boolean canViewAppointments;
    private boolean canViewInvoices;
    private boolean canViewRecords;
    private String status;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // Display fields for UI joins
    private String ownerName;
    private String ownerEmail;
    private String viewerName;
    private String viewerEmail;
    private String initiatorName;
    private String initiatorEmail;
    private Integer ownerPatientId;

    public RecordSharing() {}

    public int getSharingId() { return sharingId; }
    public void setSharingId(int sharingId) { this.sharingId = sharingId; }

    public int getOwnerAccountId() { return ownerAccountId; }
    public void setOwnerAccountId(int ownerAccountId) { this.ownerAccountId = ownerAccountId; }

    public int getViewerAccountId() { return viewerAccountId; }
    public void setViewerAccountId(int viewerAccountId) { this.viewerAccountId = viewerAccountId; }

    public int getInitiatorAccountId() { return initiatorAccountId; }
    public void setInitiatorAccountId(int initiatorAccountId) { this.initiatorAccountId = initiatorAccountId; }

    public boolean isCanViewAppointments() { return canViewAppointments; }
    public void setCanViewAppointments(boolean canViewAppointments) { this.canViewAppointments = canViewAppointments; }

    public boolean isCanViewInvoices() { return canViewInvoices; }
    public void setCanViewInvoices(boolean canViewInvoices) { this.canViewInvoices = canViewInvoices; }

    public boolean isCanViewRecords() { return canViewRecords; }
    public void setCanViewRecords(boolean canViewRecords) { this.canViewRecords = canViewRecords; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getOwnerEmail() { return ownerEmail; }
    public void setOwnerEmail(String ownerEmail) { this.ownerEmail = ownerEmail; }

    public String getViewerName() { return viewerName; }
    public void setViewerName(String viewerName) { this.viewerName = viewerName; }

    public String getViewerEmail() { return viewerEmail; }
    public void setViewerEmail(String viewerEmail) { this.viewerEmail = viewerEmail; }

    public String getInitiatorName() { return initiatorName; }
    public void setInitiatorName(String initiatorName) { this.initiatorName = initiatorName; }

    public String getInitiatorEmail() { return initiatorEmail; }
    public void setInitiatorEmail(String initiatorEmail) { this.initiatorEmail = initiatorEmail; }

    public Integer getOwnerPatientId() { return ownerPatientId; }
    public void setOwnerPatientId(Integer ownerPatientId) { this.ownerPatientId = ownerPatientId; }
}
