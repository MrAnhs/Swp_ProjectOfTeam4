package com.diabetes.monitoring.doctor.dao;

import com.diabetes.monitoring.notification.NotificationService;
import com.diabetes.monitoring.doctor.model.HealthRecord;
import com.diabetes.monitoring.doctor.model.MedicalRecord;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

public class ClinicalWorkflowDAO {
    private final NotificationService notificationService = new NotificationService();

    public int createMedicalRecordForAppointment(int appointmentId) throws SQLException {
        String appointmentSql = "SELECT a.patient_id, ds.doctor_id, a.status "
                + "FROM Appointment a WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE a.appointment_id = ?";
        String existingSql = "SELECT record_id FROM Medical_record WHERE appointment_id = ?";
        String insertSql = "INSERT INTO Medical_record "
                + "(appointment_id, patient_id, doctor_id, final_diagnosis, doctor_note, "
                + "result_visibility, processed_at) "
                + "VALUES (?, ?, ?, NULL, NULL, 1, NULL)";
        String appointmentStatusSql = "UPDATE Appointment SET status = 'In_Progress' "
                + "WHERE appointment_id = ? AND status = 'Waiting'";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Integer existingRecordId = findExistingRecord(conn, existingSql, appointmentId);
                if (existingRecordId != null) {
                    conn.commit();
                    return existingRecordId;
                }

                int patientId;
                int doctorId;
                String appointmentStatus;
                try (PreparedStatement ps = conn.prepareStatement(appointmentSql)) {
                    ps.setInt(1, appointmentId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong tim thay lich hen");
                        }
                        patientId = rs.getInt("patient_id");
                        doctorId = rs.getInt("doctor_id");
                        appointmentStatus = rs.getString("status");
                    }
                }

                if ("Cancelled".equals(appointmentStatus)
                        || "Completed".equals(appointmentStatus)) {
                    throw new SQLException("Lich hen khong the tao benh an");
                }

                int recordId;
                try (PreparedStatement ps = conn.prepareStatement(
                        insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, appointmentId);
                    ps.setInt(2, patientId);
                    ps.setInt(3, doctorId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong lay duoc record_id");
                        }
                        recordId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(appointmentStatusSql)) {
                    ps.setInt(1, appointmentId);
                    ps.executeUpdate();
                }

                conn.commit();
                return recordId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public int activateHealthRecord(int recordId, int invoiceDetailId) throws SQLException {
        String validateSql = "SELECT mr.patient_id, mr.doctor_id, mr.appointment_id, "
                + "id.appointment_id AS billed_appointment_id, i.status AS invoice_status, "
                + "ms.service_type, id.invoice_id "
                + "FROM Medical_record mr "
                + "JOIN Invoice_Detail id ON id.invoice_detail_id = ? "
                + "JOIN Invoice i ON id.invoice_id = i.invoice_id "
                + "JOIN Medical_Service ms ON id.service_id = ms.service_id "
                + "WHERE mr.record_id = ?";
        String existingSql = "SELECT r.health_record_id FROM Healthy_Record r "
                + "JOIN Invoice_Detail id ON id.invoice_id = r.invoice_id "
                + "WHERE id.invoice_detail_id = ?";
        String insertSql = "INSERT INTO Healthy_Record "
                + "(record_id, invoice_id, patient_id, doctor_id, status, "
                + "is_synced_automatically, created_at) "
                + "VALUES (?, ?, ?, ?, 'Activated_Ready', 1, GETDATE())";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(existingSql)) {
                    ps.setInt(1, invoiceDetailId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            conn.commit();
                            return rs.getInt("health_record_id");
                        }
                    }
                }

                int patientId;
                int doctorId;
                int appointmentId;
                int billedAppointmentId;
                String invoiceStatus;
                String serviceType;
                int invoiceId;

                try (PreparedStatement ps = conn.prepareStatement(validateSql)) {
                    ps.setInt(1, invoiceDetailId);
                    ps.setInt(2, recordId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong tim thay benh an hoac chi tiet hoa don");
                        }
                        patientId = rs.getInt("patient_id");
                        doctorId = rs.getInt("doctor_id");
                        appointmentId = rs.getInt("appointment_id");
                        billedAppointmentId = rs.getInt("billed_appointment_id");
                        invoiceStatus = rs.getString("invoice_status");
                        serviceType = rs.getString("service_type");
                        invoiceId = rs.getInt("invoice_id");
                    }
                }

                if (appointmentId != billedAppointmentId) {
                    throw new SQLException("Dich vu khong thuoc lich hen cua benh an");
                }
                if (!"Paid".equals(invoiceStatus)) {
                    throw new SQLException("Hoa don chua duoc thanh toan");
                }
                if (!"Lab_Test".equals(serviceType)) {
                    throw new SQLException("Dich vu khong phai xet nghiem");
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, recordId);
                    ps.setInt(2, invoiceId);
                    ps.setInt(3, patientId);
                    ps.setInt(4, doctorId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong lay duoc health_record_id");
                        }
                        int healthRecordId = rs.getInt(1);
                        conn.commit();
                        return healthRecordId;
                    }
                }
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public boolean syncLabResult(HealthRecord record) throws SQLException {
        String sql = "UPDATE Healthy_Record SET "
                + "urea = ?, cr = ?, hba1c = ?, chol = ?, tg = ?, hdl = ?, "
                + "ldl = ?, vldl = ?, bmi = ?, weight = ?, height = ?, "
                + "other_information = ?, is_synced_automatically = ?, "
                + "synced_at = GETDATE(), status = 'Completed' "
                + "WHERE health_record_id = ? AND status = 'Activated_Ready'";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            setDecimal(ps, 1, record.getUrea());
            setDecimal(ps, 2, record.getCr());
            setDecimal(ps, 3, record.getHba1c());
            setDecimal(ps, 4, record.getChol());
            setDecimal(ps, 5, record.getTg());
            setDecimal(ps, 6, record.getHdl());
            setDecimal(ps, 7, record.getLdl());
            setDecimal(ps, 8, record.getVldl());
            setDecimal(ps, 9, record.getBmi());
            setDecimal(ps, 10, record.getWeight());
            setDecimal(ps, 11, record.getHeight());
            ps.setString(12, record.getOtherInformation());
            ps.setBoolean(13, record.isSyncedAutomatically());
            ps.setInt(14, record.getHealthRecordId());
            return ps.executeUpdate() == 1;
        }
    }

    public boolean completeMedicalRecord(
            int recordId,
            int doctorId,
            String diagnosis,
            String doctorNote,
            boolean resultVisibility) throws SQLException {
        String updateRecordSql = "UPDATE Medical_record SET final_diagnosis = ?, "
                + "doctor_note = ?, result_visibility = ?, processed_at = GETDATE() "
                + "WHERE record_id = ? AND doctor_id = ?";
        String updateAppointmentSql = "UPDATE a SET a.status = 'Completed' "
                + "FROM Appointment a "
                + "JOIN Medical_record mr ON a.appointment_id = mr.appointment_id "
                + "WHERE mr.record_id = ? AND mr.doctor_id = ?";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(updateRecordSql)) {
                    ps.setString(1, diagnosis);
                    ps.setString(2, doctorNote);
                    ps.setBoolean(3, resultVisibility);
                    ps.setInt(4, recordId);
                    ps.setInt(5, doctorId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the hoan thanh benh an");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(updateAppointmentSql)) {
                    ps.setInt(1, recordId);
                    ps.setInt(2, doctorId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the hoan thanh lich hen");
                    }
                }

                notificationService.notifyMedicalRecordCompletedByRecord(
                        conn, recordId, resultVisibility);
                conn.commit();
                return true;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public MedicalRecord getMedicalRecordByAppointment(int appointmentId) {
        String sql = "SELECT mr.*, p.full_name AS patient_name, d.full_name AS doctor_name "
                + "FROM Medical_record mr "
                + "JOIN Patient p ON mr.patient_id = p.patient_id "
                + "JOIN Doctor d ON mr.doctor_id = d.doctor_id "
                + "WHERE mr.appointment_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    MedicalRecord record = new MedicalRecord();
                    record.setRecordId(rs.getInt("record_id"));
                    record.setAppointmentId(rs.getInt("appointment_id"));
                    record.setPatientId(rs.getInt("patient_id"));
                    record.setPatientName(rs.getString("patient_name"));
                    record.setDoctorId(rs.getInt("doctor_id"));
                    record.setDoctorName(rs.getString("doctor_name"));
                    record.setFinalDiagnosis(rs.getString("final_diagnosis"));
                    record.setDoctorNote(rs.getString("doctor_note"));
                    record.setResultVisibility(rs.getBoolean("result_visibility"));
                    record.setProcessedAt(rs.getTimestamp("processed_at"));
                    return record;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Integer findExistingRecord(
            Connection conn,
            String sql,
            int appointmentId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("record_id") : null;
            }
        }
    }

    private void setDecimal(PreparedStatement ps, int index, double value)
            throws SQLException {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            ps.setNull(index, Types.DECIMAL);
        } else {
            ps.setBigDecimal(index, BigDecimal.valueOf(value));
        }
    }
}
