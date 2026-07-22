package com.diabetes.monitoring.doctor.dao;

import com.diabetes.monitoring.doctor.model.HealthRecord;
import com.diabetes.monitoring.doctor.model.HealthRecordAI;
import com.diabetes.monitoring.doctor.model.DoctorSummary;
import com.diabetes.monitoring.doctor.model.Patient;
import com.diabetes.monitoring.doctor.model.TransferHistory;
import com.diabetes.monitoring.doctor.model.MedicalRecord;
import com.diabetes.monitoring.doctor.model.LaboratoryRequest;
import com.diabetes.monitoring.doctor.model.MedicalService;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class HealthRecordDAO {

    public enum LaboratoryStage {
        NONE,
        WAITING_PAYMENT,
        LABORATORY,
        COMPLETED
    }

    public List<HealthRecordAI> getRecordsByStatus(String status) {
        List<HealthRecordAI> list = new ArrayList<>();
        // Use case-insensitive comparison for status to avoid mismatch between DB value casing and code
        String sql = "SELECT r.health_record_id, r.status, p.full_name, "
                + "ai.diabetes_probability, ai.pre_diabetes_probability, ai.normal_probability "
                + "FROM [dbo].[Healthy_Record] r "
                + "LEFT JOIN [dbo].[Patient] p ON r.patient_id = p.patient_id "
                + "LEFT JOIN [dbo].[Doctor_AI] ai ON r.health_record_id = ai.health_record_id "
                + "WHERE LOWER(r.status) = LOWER(?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, status == null ? "" : status.trim());

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt("health_record_id");
                    String patientName = rs.getString("full_name");
                    String dbStatus = rs.getString("status");
                    double dia = rs.getDouble("diabetes_probability");
                    if (rs.wasNull()) dia = 0.0;
                    double pre = rs.getDouble("pre_diabetes_probability");
                    if (rs.wasNull()) pre = 0.0;
                    double nor = rs.getDouble("normal_probability");
                    if (rs.wasNull()) nor = 0.0;

                    list.add(new HealthRecordAI(
                            id,
                            patientName,
                            dbStatus,
                            dia,
                            pre,
                            nor
                    ));
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<HealthRecordAI> getActionableRecords() {
        List<HealthRecordAI> list = new ArrayList<>();
        String sql = "SELECT r.health_record_id, r.status, p.full_name, "
                + "ai.diabetes_probability, ai.pre_diabetes_probability, ai.normal_probability "
                + "FROM [dbo].[Healthy_Record] r "
                + "LEFT JOIN [dbo].[Patient] p ON r.patient_id = p.patient_id "
                + "LEFT JOIN [dbo].[Doctor_AI] ai ON r.health_record_id = ai.health_record_id "
                + "WHERE r.patient_id IS NOT NULL AND (r.status IS NULL "
                + "OR LOWER(r.status) IN ('pending', 'processing', 'ai_processed')) "
                + "ORDER BY r.health_record_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new HealthRecordAI(
                        rs.getInt("health_record_id"),
                        rs.getString("full_name"),
                        rs.getString("status"),
                        rs.getDouble("diabetes_probability"),
                        rs.getDouble("pre_diabetes_probability"),
                        rs.getDouble("normal_probability")
                ));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getOrCreateDoctorIdByAccountId(int accountId) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return resolveDoctorId(conn, accountId, 0);
        }
    }

    public List<HealthRecord> getRecordsByDoctorAndGroup(int doctorId, String group) {
        List<HealthRecord> list = new ArrayList<>();
        String statusFilter;

        if ("assigned".equalsIgnoreCase(group)) {
            statusFilter = "LOWER(ISNULL(r.status, '')) = 'assigned'";
        } else if ("processing".equalsIgnoreCase(group)) {
            statusFilter = "LOWER(ISNULL(r.status, '')) IN ('accepted', 'ai_processed')";
        } else if ("completed".equalsIgnoreCase(group)) {
            statusFilter = "LOWER(ISNULL(r.status, '')) = 'completed'";
        } else {
            statusFilter = "1 = 0";
        }

        String sql = "SELECT r.health_record_id, r.patient_id, r.status, r.created_at, "
                + "r.urea, r.cr, r.hba1c, r.chol, r.tg, r.hdl, "
                + "r.ldl AS ldl_value, r.vldl, r.bmi, "
                + "p.full_name AS patient_name "
                + "FROM Healthy_Record r "
                + "LEFT JOIN Patient p ON r.patient_id = p.patient_id "
                + "WHERE r.doctor_id = ? AND " + statusFilter + " "
                + "ORDER BY r.created_at DESC, r.health_record_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapDashboardRecord(rs, doctorId));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<HealthRecord> getPriorityRecords(int doctorId) {
        List<HealthRecord> list = new ArrayList<>();
        String sql = "SELECT r.health_record_id, r.patient_id, r.status, r.created_at, "
                + "r.urea, r.cr, r.hba1c, r.chol, r.tg, r.hdl, "
                + "r.ldl AS ldl_value, r.vldl, r.bmi, "
                + "p.full_name AS patient_name, "
                + "DATEDIFF(DAY, r.created_at, GETDATE()) AS waiting_days, "
                + "CASE r.status "
                + "WHEN 'Assigned' THEN 1 "
                + "WHEN 'Accepted' THEN 2 "
                + "WHEN 'AI_Processed' THEN 3 "
                + "WHEN 'Completed' THEN 4 "
                + "ELSE 5 END AS priority_level "
                + "FROM Healthy_Record r "
                + "LEFT JOIN Patient p ON r.patient_id = p.patient_id "
                + "WHERE r.doctor_id = ? "
                + "ORDER BY "
                + "CASE r.status "
                + "WHEN 'Assigned' THEN 1 "
                + "WHEN 'Accepted' THEN 2 "
                + "WHEN 'AI_Processed' THEN 3 "
                + "WHEN 'Completed' THEN 4 "
                + "ELSE 5 END, "
                + "r.created_at ASC, r.health_record_id ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    HealthRecord record = mapDashboardRecord(rs, doctorId);
                    record.setWaitingDays(rs.getInt("waiting_days"));
                    record.setPriorityLevel(rs.getInt("priority_level"));
                    list.add(record);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<HealthRecord> getGeneralExaminationRecords(int doctorId) {
        return getDoctorWorkflowRecords(doctorId,
                "(r.status IS NULL OR r.status != 'Completed') AND NOT EXISTS ("
                + "SELECT 1 FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "LEFT JOIN Medical_record mr2 ON mr2.health_record_id = r.health_record_id "
                + "WHERE (id.health_record_id = r.health_record_id "
                + "OR (mr2.appointment_id IS NOT NULL AND id.appointment_id = mr2.appointment_id) "
                + "OR (i.patient_id = r.patient_id)) "
                + "AND (i.status = 'Paid' OR id.lab_status IN ('Requested', 'Processing', 'Completed')))");
    }

    public List<HealthRecord> getDetailedExaminationRecords(int doctorId) {
        return getDoctorWorkflowRecords(doctorId,
                "(r.status IS NULL OR r.status != 'Completed') AND EXISTS ("
                + "SELECT 1 FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "LEFT JOIN Medical_record mr2 ON mr2.health_record_id = r.health_record_id "
                + "WHERE (id.health_record_id = r.health_record_id "
                + "OR (mr2.appointment_id IS NOT NULL AND id.appointment_id = mr2.appointment_id) "
                + "OR (i.patient_id = r.patient_id)) "
                + "AND (i.status = 'Paid' OR id.lab_status IN ('Requested', 'Processing', 'Completed')))");
    }

    private List<HealthRecord> getDoctorWorkflowRecords(
            int doctorId, String workflowCondition) {
        List<HealthRecord> list = new ArrayList<>();
        String sql = "SELECT r.health_record_id, r.patient_id, r.status, r.created_at, "
                + "r.urea, r.cr, r.hba1c, r.chol, r.tg, r.hdl, "
                + "r.ldl AS ldl_value, r.vldl, r.bmi, "
                + "p.full_name AS patient_name, mr.final_diagnosis, "
                + "DATEDIFF(DAY, r.created_at, GETDATE()) AS waiting_days "
                + "FROM Healthy_Record r "
                + "LEFT JOIN Patient p ON p.patient_id = r.patient_id "
                + "LEFT JOIN Medical_record mr ON mr.health_record_id = r.health_record_id "
                + "WHERE r.doctor_id = ? AND " + workflowCondition + " "
                + "ORDER BY r.created_at ASC, r.health_record_id ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    HealthRecord record = mapDashboardRecord(rs, doctorId);
                    record.setWaitingDays(rs.getInt("waiting_days"));
                    record.setFinalDiagnosis(rs.getString("final_diagnosis"));
                    list.add(record);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<HealthRecord> getCompletedRecords(int doctorId) {
        List<HealthRecord> list = new ArrayList<>();
        String sql = "SELECT r.health_record_id, r.patient_id, r.status, r.created_at, "
                + "r.urea, r.cr, r.hba1c, r.chol, r.tg, r.hdl, "
                + "r.ldl AS ldl_value, r.vldl, r.bmi, "
                + "p.full_name AS patient_name, mr.processed_at, mr.final_diagnosis, "
                + "ai.diabetes_probability, ai.pre_diabetes_probability, ai.normal_probability "
                + "FROM Healthy_Record r "
                + "LEFT JOIN Patient p ON r.patient_id = p.patient_id "
                + "LEFT JOIN Medical_record mr ON r.health_record_id = mr.health_record_id "
                + "LEFT JOIN Doctor_AI ai ON r.health_record_id = ai.health_record_id "
                + "WHERE r.doctor_id = ? AND r.status = 'Completed' "
                + "ORDER BY mr.processed_at DESC, r.health_record_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    HealthRecord record = mapDashboardRecord(rs, doctorId);
                    record.setProcessedAt(rs.getTimestamp("processed_at"));
                    record.setFinalDiagnosis(rs.getString("final_diagnosis"));
                    record.setAiResults(
                            rs.getDouble("diabetes_probability"),
                            rs.getDouble("pre_diabetes_probability"),
                            rs.getDouble("normal_probability")
                    );
                    list.add(record);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean canModifyDiagnosis(int recordId, int doctorId) {
        String sql = "SELECT COUNT(*) FROM Healthy_Record "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status IN ('Accepted', 'AI_Processed', 'Editing', 'Completed')";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean canRunAI(int recordId, int doctorId) {
        String sql = "SELECT COUNT(*) FROM Healthy_Record "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status IN ('Accepted', 'AI_Processed', 'Editing', 'Completed')";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean hasRequiredAIData(int recordId, int doctorId) {
        String sql = "SELECT COUNT(*) FROM Healthy_Record "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND hba1c IS NOT NULL AND bmi IS NOT NULL AND urea IS NOT NULL";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) == 1;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateHealthMetricsForDoctor(
            int recordId,
            int doctorId,
            Double urea,
            Double cr,
            Double hba1c,
            Double chol,
            Double tg,
            Double hdl,
            Double ldl,
            Double vldl,
            Double bmi) throws SQLException {
        String sql = "UPDATE Healthy_Record SET "
                + "urea = ?, cr = ?, hba1c = ?, chol = ?, tg = ?, hdl = ?, "
                + "ldl = ?, vldl = ?, bmi = ? "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status IN ('AI_Processed', 'Editing', 'Completed')";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            setNullableDecimal(ps, 1, urea);
            setNullableDecimal(ps, 2, cr);
            setNullableDecimal(ps, 3, hba1c);
            setNullableDecimal(ps, 4, chol);
            setNullableDecimal(ps, 5, tg);
            setNullableDecimal(ps, 6, hdl);
            setNullableDecimal(ps, 7, ldl);
            setNullableDecimal(ps, 8, vldl);
            setNullableDecimal(ps, 9, bmi);
            ps.setInt(10, recordId);
            ps.setInt(11, doctorId);
            return ps.executeUpdate() == 1;
        }
    }

    private void setNullableDecimal(PreparedStatement ps, int index, Double value)
            throws SQLException {
        if (value == null || value.isNaN() || value.isInfinite()) {
            ps.setNull(index, Types.DECIMAL);
        } else {
            ps.setBigDecimal(index, BigDecimal.valueOf(value));
        }
    }

    private boolean updateRecordStatusBySql(String sql, int recordId) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private HealthRecord mapDashboardRecord(ResultSet rs, int doctorId) throws SQLException {
        HealthRecord record = new HealthRecord();
        record.setHealthRecordId(rs.getInt("health_record_id"));
        record.setPatientId(rs.getInt("patient_id"));
        record.setPatientName(rs.getString("patient_name"));
        record.setDoctorId(doctorId);
        record.setStatus(rs.getString("status"));
        record.setCreatedAt(rs.getTimestamp("created_at"));
        record.setUrea(rs.getDouble("urea"));
        record.setCr(rs.getDouble("cr"));
        record.setHba1c(rs.getDouble("hba1c"));
        record.setChol(rs.getDouble("chol"));
        record.setTg(rs.getDouble("tg"));
        record.setHdl(rs.getDouble("hdl"));
        record.setLdl(rs.getDouble("ldl_value"));
        record.setVldl(rs.getDouble("vldl"));
        record.setBmi(rs.getDouble("bmi"));
        return record;
    }

    public boolean isRecordAssignedToDoctor(int healthRecordId, int doctorId) {
        String sql = "SELECT COUNT(*) FROM Healthy_Record r "
                + "LEFT JOIN Medical_record mr ON mr.health_record_id = r.health_record_id "
                + "LEFT JOIN Appointment a ON a.appointment_id = mr.appointment_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE r.health_record_id = ? AND ("
                + "r.doctor_id = ? "
                + "OR mr.doctor_id = ? "
                + "OR ds.doctor_id = ? "
                + "OR EXISTS (SELECT 1 FROM Invoice_Detail id WHERE id.doctor_id = ? AND (id.health_record_id = r.health_record_id OR id.appointment_id = mr.appointment_id)) "
                + "OR EXISTS (SELECT 1 FROM Medical_record mr2 WHERE mr2.patient_id = r.patient_id AND mr2.doctor_id = ?)"
                + ")";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, healthRecordId);
            ps.setInt(2, doctorId);
            ps.setInt(3, doctorId);
            ps.setInt(4, doctorId);
            ps.setInt(5, doctorId);
            ps.setInt(6, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public HealthRecord getHealthRecordByIdForDoctor(int recordId, int doctorId) {
        if (!isRecordAssignedToDoctor(recordId, doctorId)) {
            return null;
        }
        return getHealthRecordById(recordId);
    }

    public int acceptAppointment(int appointmentId, int doctorId)
            throws SQLException {
        String appointmentSql = "SELECT a.patient_id, a.status "
                + "FROM Appointment a WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE a.appointment_id = ? AND ds.doctor_id = ?";
        String medicalSql = "SELECT record_id, health_record_id "
                + "FROM Medical_record WHERE appointment_id = ?";
        String insertMedicalSql = "INSERT INTO Medical_record "
                + "(appointment_id, patient_id, doctor_id, result_visibility) "
                + "VALUES (?, ?, ?, 0)";
        String healthByRecordSql = "SELECT health_record_id "
                + "FROM Healthy_Record WHERE record_id = ?";
        String insertHealthSql = "INSERT INTO Healthy_Record "
                + "(record_id, patient_id, doctor_id, status, "
                + "is_synced_automatically, created_at) "
                + "VALUES (?, ?, ?, 'Accepted', 0, GETDATE())";
        String linkMedicalSql = "UPDATE Medical_record SET health_record_id = ? "
                + "WHERE record_id = ?";
        String acceptSql = "UPDATE a SET a.status = 'In_Progress' "
                + "FROM Appointment a "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE a.appointment_id = ? AND ds.doctor_id = ? "
                + "AND a.status IN ('Waiting', 'Checked_In')";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int patientId;
                String appointmentStatus;
                try (PreparedStatement ps = conn.prepareStatement(appointmentSql)) {
                    ps.setInt(1, appointmentId);
                    ps.setInt(2, doctorId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                    "Lịch hẹn không thuộc bác sĩ hiện tại");
                        }
                        patientId = rs.getInt("patient_id");
                        appointmentStatus = rs.getString("status");
                    }
                }
                if (!"Waiting".equals(appointmentStatus)
                        && !"Checked_In".equals(appointmentStatus)
                        && !"In_Progress".equals(appointmentStatus)) {
                    throw new SQLException("Lịch hẹn không thể tiếp nhận");
                }

                Integer medicalRecordId = null;
                Integer healthRecordId = null;
                try (PreparedStatement ps = conn.prepareStatement(medicalSql)) {
                    ps.setInt(1, appointmentId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            medicalRecordId = rs.getInt("record_id");
                            int linkedId = rs.getInt("health_record_id");
                            healthRecordId = rs.wasNull() ? null : linkedId;
                        }
                    }
                }

                if (medicalRecordId == null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            insertMedicalSql, Statement.RETURN_GENERATED_KEYS)) {
                        ps.setInt(1, appointmentId);
                        ps.setInt(2, patientId);
                        ps.setInt(3, doctorId);
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) {
                            if (!rs.next()) {
                                throw new SQLException(
                                        "Không thể tạo bệnh án cho lịch hẹn");
                            }
                            medicalRecordId = rs.getInt(1);
                        }
                    }
                }

                if (healthRecordId == null) {
                    try (PreparedStatement ps =
                            conn.prepareStatement(healthByRecordSql)) {
                        ps.setInt(1, medicalRecordId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                healthRecordId = rs.getInt("health_record_id");
                            }
                        }
                    }
                }

                if (healthRecordId == null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            insertHealthSql, Statement.RETURN_GENERATED_KEYS)) {
                        ps.setInt(1, medicalRecordId);
                        ps.setInt(2, patientId);
                        ps.setInt(3, doctorId);
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) {
                            if (!rs.next()) {
                                throw new SQLException(
                                        "Không thể tạo hồ sơ sức khỏe");
                            }
                            healthRecordId = rs.getInt(1);
                        }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(linkMedicalSql)) {
                    ps.setInt(1, healthRecordId);
                    ps.setInt(2, medicalRecordId);
                    ps.executeUpdate();
                }
                if ("Waiting".equals(appointmentStatus) || "Checked_In".equals(appointmentStatus)) {
                    try (PreparedStatement ps = conn.prepareStatement(acceptSql)) {
                        ps.setInt(1, appointmentId);
                        ps.setInt(2, doctorId);
                        if (ps.executeUpdate() != 1) {
                            throw new SQLException("Không thể tiếp nhận lịch hẹn");
                        }
                    }
                }

                conn.commit();
                return healthRecordId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public boolean updateRecordStatusForDoctor(int healthRecordId, int doctorId, String status) {
        if (!"AI_Processed".equals(status)) {
            return false;
        }
        String sql = "UPDATE Healthy_Record SET status = 'AI_Processed' "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status IN ('Accepted', 'AI_Processed', 'Editing')";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, healthRecordId);
            ps.setInt(2, doctorId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean transferRecord(int healthRecordId, int fromDoctorId, int toDoctorId, String reason)
            throws SQLException {
        String updateSql = "UPDATE Healthy_Record SET doctor_id = ?, status = 'Assigned' "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status <> 'Completed'";
        String historySql = "INSERT INTO Record_Transfer_History "
                + "(health_record_id, from_doctor_id, to_doctor_id, reason, created_at) "
                + "VALUES (?, ?, ?, ?, GETDATE())";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setInt(1, toDoctorId);
                    ps.setInt(2, healthRecordId);
                    ps.setInt(3, fromDoctorId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the chuyen ho so nay");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(historySql)) {
                    ps.setInt(1, healthRecordId);
                    ps.setInt(2, fromDoctorId);
                    ps.setInt(3, toDoctorId);
                    ps.setString(4, reason);
                    ps.executeUpdate();
                }

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

    public List<DoctorSummary> getAvailableDoctors(int excludeDoctorId) {
        List<DoctorSummary> list = new ArrayList<>();
        String sql = "SELECT doctor_id, full_name, email, department "
                + "FROM Doctor WHERE doctor_id <> ? ORDER BY full_name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, excludeDoctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new DoctorSummary(
                            rs.getInt("doctor_id"),
                            rs.getString("full_name"),
                            rs.getString("email"),
                            rs.getString("department")
                    ));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<TransferHistory> getTransferHistoryForDoctor(int doctorId) {
        List<TransferHistory> list = new ArrayList<>();
        String sql = "SELECT h.transfer_id, h.health_record_id, h.from_doctor_id, h.to_doctor_id, "
                + "fd.full_name AS from_doctor_name, td.full_name AS to_doctor_name, "
                + "p.full_name AS patient_name, h.reason, h.created_at "
                + "FROM Record_Transfer_History h "
                + "LEFT JOIN Doctor fd ON h.from_doctor_id = fd.doctor_id "
                + "LEFT JOIN Doctor td ON h.to_doctor_id = td.doctor_id "
                + "LEFT JOIN Healthy_Record r ON h.health_record_id = r.health_record_id "
                + "LEFT JOIN Patient p ON r.patient_id = p.patient_id "
                + "WHERE h.from_doctor_id = ? OR h.to_doctor_id = ? "
                + "ORDER BY h.created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TransferHistory history = new TransferHistory();
                    history.setTransferId(rs.getInt("transfer_id"));
                    history.setHealthRecordId(rs.getInt("health_record_id"));
                    history.setFromDoctorId(rs.getInt("from_doctor_id"));
                    history.setToDoctorId(rs.getInt("to_doctor_id"));
                    history.setFromDoctorName(rs.getString("from_doctor_name"));
                    history.setToDoctorName(rs.getString("to_doctor_name"));
                    history.setPatientName(rs.getString("patient_name"));
                    history.setReason(rs.getString("reason"));
                    history.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(history);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getPatientIdByRecordId(int recordId) {

        String sql
                = "SELECT patient_id "
                + "FROM Healthy_Record "
                + "WHERE health_record_id = ?";

        try (
                Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, recordId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("patient_id");
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return 0;
    }

    public HealthRecord getHealthRecordById(int recordId) {
        String sql
                = "SELECT r.health_record_id, r.status, r.patient_id, r.doctor_id, r.created_at, "
                + "p.full_name, p.gender, "
                + "mr.doctor_note, "
                + "mr.final_diagnosis, "
                + "mr.result_visibility, "
                + "mr.processed_at, "
                + "mr.revisit_date, "
                + "DATEDIFF(YEAR, p.date_of_birth, GETDATE()) - "
                + "CASE WHEN (MONTH(p.date_of_birth) > MONTH(GETDATE())) OR "
                + "(MONTH(p.date_of_birth) = MONTH(GETDATE()) AND DAY(p.date_of_birth) > DAY(GETDATE())) "
                + "THEN 1 ELSE 0 END as calculated_age, "
                + "r.urea, r.cr, r.hba1c, r.chol, r.tg, r.hdl, "
                + "r.ldl AS ldl_value, r.vldl, r.bmi, "
                + "ai.diabetes_probability, "
                + "ai.pre_diabetes_probability, "
                + "ai.normal_probability "
                + "FROM Healthy_Record r "
                + "LEFT JOIN Patient p "
                + "ON r.patient_id = p.patient_id "
                + "LEFT JOIN Doctor_AI ai "
                + "ON r.health_record_id = ai.health_record_id "
                + "LEFT JOIN Medical_record mr "
                + "ON r.health_record_id = mr.health_record_id "
                + "WHERE r.health_record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, recordId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {

                HealthRecord hr = new HealthRecord(
                        rs.getInt("health_record_id"),
                        rs.getString("status"),
                        rs.getString("full_name"),
                        rs.getInt("calculated_age"),
                        rs.getString("gender"),
                        rs.getDouble("urea"),
                        rs.getDouble("cr"),
                        rs.getDouble("hba1c"),
                        rs.getDouble("chol"),
                        rs.getDouble("tg"),
                        rs.getDouble("hdl"),
                        rs.getDouble("ldl_value"),
                        rs.getDouble("vldl"),
                        rs.getDouble("bmi")
                );

                hr.setPatientId(rs.getInt("patient_id"));
                hr.setDoctorId(rs.getInt("doctor_id"));
                hr.setCreatedAt(rs.getTimestamp("created_at"));
                hr.setProcessedAt(rs.getTimestamp("processed_at"));

                hr.setAiResults(
                        rs.getDouble("diabetes_probability"),
                        rs.getDouble("pre_diabetes_probability"),
                        rs.getDouble("normal_probability")
                );

                // MEDICAL RECORD
                hr.setDoctor_notes(
                        rs.getString("doctor_note")
                );

                hr.setFinalDiagnosis(
                        rs.getString("final_diagnosis")
                );

                hr.setCanPatientView(rs.getBoolean("result_visibility"));
                hr.setRevisitDate(rs.getTimestamp("revisit_date"));

                return hr;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateRecordStatus(int recordId, String status) {
        String sql = "UPDATE [dbo].[Healthy_Record] SET status = ? WHERE health_record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, recordId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public void updateRecordComplete(int recordId, String status, String result) {
        String sql = "UPDATE [dbo].[Healthy_Record] SET status = ?, result = ? WHERE health_record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, status);
            ps.setString(2, result);
            ps.setInt(3, recordId);

            ps.executeUpdate();

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public boolean saveAiResults(int recordId, double dia, double pre, double nor) {
        String sql = "MERGE Doctor_AI AS target "
                + "USING (SELECT ? AS id) AS source "
                + "ON target.health_record_id = source.id "
                + "WHEN MATCHED THEN "
                + "UPDATE SET diabetes_probability = ?, pre_diabetes_probability = ?, normal_probability = ? "
                + "WHEN NOT MATCHED THEN "
                + "INSERT (health_record_id, diabetes_probability, pre_diabetes_probability, normal_probability) "
                + "VALUES (?, ?, ?, ?);";

        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            // Cấu hình tham số cho mệnh đề UPDATE (Match)
            ps.setInt(1, recordId);    // source id
            ps.setDouble(2, dia);      // diabetes
            ps.setDouble(3, pre);      // pre
            ps.setDouble(4, nor);      // normal

            // Cấu hình tham số cho mệnh đề INSERT (Not Match)
            ps.setInt(5, recordId);    // health_record_id
            ps.setDouble(6, dia);      // diabetes
            ps.setDouble(7, pre);      // pre
            ps.setDouble(8, nor);      // normal

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace(); // Lỗi sẽ hiện ở Console NetBeans
            return false;
        }
    }

    public void updateDoctorNotes(int recordId, String notes) {

        String sql = "UPDATE [dbo].[Healthy_Record] SET result = ? WHERE health_record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, notes);
            ps.setInt(2, recordId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public List<HealthRecord> getRecordsByPatientId(int patientId) {
        List<HealthRecord> list = new ArrayList<>();
        // Truy vấn lấy dữ liệu hồ sơ cùng tên bệnh nhân (JOIN)
        String sql = "SELECT r.*, p.full_name, mr.result_visibility "
                + "FROM [dbo].[Healthy_Record] r "
                + "LEFT JOIN [dbo].[Patient] p ON r.patient_id = p.patient_id "
                + "LEFT JOIN [dbo].[Medical_record] mr ON r.health_record_id = mr.health_record_id "
                + "WHERE r.patient_id = ?";

        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                HealthRecord hr = new HealthRecord();
                hr.setHealthRecordId(rs.getInt("health_record_id"));
                hr.setPatientId(rs.getInt("patient_id"));
                hr.setPatientName(rs.getString("full_name"));
                hr.setStatus(rs.getString("status"));
                hr.setUrea(rs.getDouble("urea"));
                hr.setCr(rs.getDouble("cr"));
                hr.setHba1c(rs.getDouble("hba1c"));
                hr.setChol(rs.getDouble("chol"));
                hr.setTg(rs.getDouble("tg"));
                hr.setHdl(rs.getDouble("hdl"));
                hr.setLdl(rs.getDouble("ldl"));
                hr.setVldl(rs.getDouble("vldl"));
                hr.setBmi(rs.getDouble("bmi"));
                hr.setCreatedAt(rs.getTimestamp("created_at"));
                hr.setCanPatientView(rs.getBoolean("result_visibility"));

                list.add(hr);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // Cập nhật quyền xem
    public List<HealthRecord> getRecordsByPatientIdAndDoctorId(int patientId, int doctorId) {
        List<HealthRecord> list = new ArrayList<>();
        String sql = "SELECT r.*, p.full_name, mr.result_visibility "
                + "FROM [dbo].[Healthy_Record] r "
                + "LEFT JOIN [dbo].[Patient] p ON r.patient_id = p.patient_id "
                + "LEFT JOIN [dbo].[Medical_record] mr ON r.health_record_id = mr.health_record_id "
                + "WHERE r.patient_id = ? AND r.doctor_id = ? "
                + "ORDER BY r.created_at DESC, r.health_record_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, patientId);
            ps.setInt(2, doctorId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    HealthRecord hr = new HealthRecord();
                    hr.setHealthRecordId(rs.getInt("health_record_id"));
                    hr.setPatientId(rs.getInt("patient_id"));
                    hr.setPatientName(rs.getString("full_name"));
                    hr.setStatus(rs.getString("status"));
                    hr.setUrea(rs.getDouble("urea"));
                    hr.setCr(rs.getDouble("cr"));
                    hr.setHba1c(rs.getDouble("hba1c"));
                    hr.setChol(rs.getDouble("chol"));
                    hr.setTg(rs.getDouble("tg"));
                    hr.setHdl(rs.getDouble("hdl"));
                    hr.setLdl(rs.getDouble("ldl"));
                    hr.setVldl(rs.getDouble("vldl"));
                    hr.setBmi(rs.getDouble("bmi"));
                    hr.setCreatedAt(rs.getTimestamp("created_at"));
                    hr.setCanPatientView(rs.getBoolean("result_visibility"));

                    list.add(hr);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public void updatePatientViewPermission(int recordId, boolean canView) {
        String sql = "UPDATE [dbo].[Medical_record] SET result_visibility = ? WHERE health_record_id = ?";
        try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, canView);
            ps.setInt(2, recordId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public boolean medicalRecordExists(int healthRecordId) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM Medical_record "
                + "WHERE health_record_id=?";

        try (
                Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, healthRecordId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt(1) > 0;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean insertMedicalRecord(
            int healthRecordId,
            int doctorId,
            int patientId,
            String notes,
            String diagnosis,
            boolean canView) {

        String sql
                = "INSERT INTO Medical_record "
                + "(patient_id,doctor_id,final_diagnosis,"
                + "doctor_note,health_record_id,"
                + "result_visibility,processed_at) "
                + "VALUES(?,?,?,?,?,?,GETDATE())";

        try (
                Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, patientId);
            ps.setInt(2, doctorId);
            ps.setString(3, diagnosis);
            ps.setString(4, notes);
            ps.setInt(5, healthRecordId);
            ps.setBoolean(6, canView);

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateMedicalRecord(
            int healthRecordId,
            int doctorId,
            int patientId,
            String notes,
            String diagnosis,
            boolean canView) {

        String sql
                = "UPDATE Medical_record "
                + "SET doctor_id=?, "
                + "patient_id=?, "
                + "doctor_note=?, "
                + "final_diagnosis=?, "
                + "result_visibility=?, "
                + "processed_at=GETDATE() "
                + "WHERE health_record_id=?";

        try (
                Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, doctorId);
            ps.setInt(2, patientId);
            ps.setString(3, notes);
            ps.setString(4, diagnosis);
            ps.setBoolean(5, canView);
            ps.setInt(6, healthRecordId);

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public int getDoctorIdByAccountId(int accountId) {
        String sql = "SELECT doctor_id FROM Doctor WHERE account_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("doctor_id");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    public boolean saveMedicalRecordAndComplete(
            int healthRecordId,
            int accountId,
            String notes,
            String diagnosis,
            boolean canView) throws SQLException {

        String patientSql = "SELECT patient_id FROM Healthy_Record WHERE health_record_id = ?";
        String existsSql = "SELECT COUNT(*) FROM Medical_record WHERE health_record_id = ?";
        String insertSql = "INSERT INTO Medical_record "
                + "(patient_id, doctor_id, final_diagnosis, doctor_note, health_record_id, "
                + "result_visibility, processed_at) VALUES (?, ?, ?, ?, ?, ?, GETDATE())";
        String updateSql = "UPDATE Medical_record SET doctor_id = ?, patient_id = ?, "
                + "doctor_note = ?, final_diagnosis = ?, result_visibility = ?, "
                + "processed_at = GETDATE() WHERE health_record_id = ?";
        String statusSql = "UPDATE Healthy_Record SET status = 'Completed' WHERE health_record_id = ?";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int doctorId = resolveDoctorId(conn, accountId, healthRecordId);
                int patientId = queryRequiredId(conn, patientSql, healthRecordId, "patient_id");
                boolean exists;

                try (PreparedStatement ps = conn.prepareStatement(existsSql)) {
                    ps.setInt(1, healthRecordId);
                    try (ResultSet rs = ps.executeQuery()) {
                        exists = rs.next() && rs.getInt(1) > 0;
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(exists ? updateSql : insertSql)) {
                    if (exists) {
                        ps.setInt(1, doctorId);
                        ps.setInt(2, patientId);
                        ps.setString(3, notes);
                        ps.setString(4, diagnosis);
                        ps.setBoolean(5, canView);
                        ps.setInt(6, healthRecordId);
                    } else {
                        ps.setInt(1, patientId);
                        ps.setInt(2, doctorId);
                        ps.setString(3, diagnosis);
                        ps.setString(4, notes);
                        ps.setInt(5, healthRecordId);
                        ps.setBoolean(6, canView);
                    }
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the luu Medical_record");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                    ps.setInt(1, healthRecordId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the cap nhat trang thai ho so");
                    }
                }

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

    private int resolveDoctorId(
            Connection conn,
            int accountId,
            int healthRecordId) throws SQLException {
        String findSql = "SELECT doctor_id FROM Doctor WHERE account_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(findSql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("doctor_id");
                }
            }
        }

        String createSql = "INSERT INTO Doctor (full_name, email, account_id) "
                + "SELECT full_name, email, account_id FROM Account "
                + "WHERE account_id = ? AND LOWER(role) = 'doctor'";
        try (PreparedStatement ps = conn.prepareStatement(
                createSql,
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, accountId);
            if (ps.executeUpdate() == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
        }

        String assignedSql = "SELECT doctor_id FROM Healthy_Record WHERE health_record_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(assignedSql)) {
            ps.setInt(1, healthRecordId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getObject("doctor_id") != null) {
                    return rs.getInt("doctor_id");
                }
            }
        }

        throw new SQLException("Khong tim thay ho so bac si hop le");
    }

    private int queryRequiredId(
            Connection conn,
            String sql,
            int parameter,
            String column) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, parameter);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int value = rs.getInt(column);
                    if (!rs.wasNull() && value > 0) {
                        return value;
                    }
                }
            }
        }
        throw new SQLException("Khong tim thay " + column);
    }
       public Patient getPatientById(int patientId) {

    String sql =
            "SELECT patient_id, full_name, date_of_birth, gender, phone, email, address, "
            + "CAST(NULL AS VARCHAR(100)) AS emergency_contact, CAST(NULL AS VARCHAR(20)) AS blood_type, "
            + "DATEDIFF(YEAR, date_of_birth, GETDATE()) - "
            + "CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE() "
            + "THEN 1 ELSE 0 END AS age " +
            "FROM dbo.Patient " +
            "WHERE patient_id = ?";

    try (
            Connection conn = DatabaseConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
    ) {

        System.out.println("Đang tìm patient_id = " + patientId);

        ps.setInt(1, patientId);

        ResultSet rs = ps.executeQuery();

        if (rs.next()) {

            System.out.println("Đã tìm thấy bệnh nhân trong DB");

            Patient p = new Patient();

            p.setPatientId(rs.getInt("patient_id"));
            p.setFullName(rs.getString("full_name"));
            p.setGender(rs.getString("gender"));
            p.setPhone(rs.getString("phone"));
            p.setEmail(rs.getString("email"));
            p.setAddress(rs.getString("address"));
            p.setDateOfBirth(rs.getDate("date_of_birth"));
            p.setEmergencyContact(rs.getString("emergency_contact"));
            p.setBloodType(rs.getString("blood_type"));
            p.setAge(rs.getInt("age"));

            return p;

        } else {
            System.out.println("Không có dòng nào với patient_id = " + patientId);
        }

    } catch (Exception e) {
        System.out.println("DAO bị lỗi:");
        e.printStackTrace();
    }

    return null;
}

    public List<MedicalRecord> getMedicalHistory(int patientId, int doctorId) {
        List<MedicalRecord> history = new ArrayList<>();
        String sql = "SELECT mr.record_id, mr.health_record_id, mr.patient_id, mr.doctor_id, "
                + "mr.doctor_note, mr.final_diagnosis, mr.result_visibility, mr.processed_at, mr.revisit_date, "
                + "d.full_name AS doctor_name, hr.urea, hr.cr, hr.hba1c, hr.chol, hr.tg, "
                + "hr.hdl, hr.ldl AS ldl, hr.vldl, hr.bmi, "
                + "ai.diabetes_probability, ai.pre_diabetes_probability, ai.normal_probability "
                + "FROM Medical_record mr "
                + "LEFT JOIN Healthy_Record hr ON hr.health_record_id = mr.health_record_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = mr.doctor_id "
                + "LEFT JOIN Doctor_AI ai ON ai.health_record_id = mr.health_record_id "
                + "WHERE mr.patient_id = ? "
                + "AND EXISTS (SELECT 1 FROM Healthy_Record permitted "
                + "WHERE permitted.patient_id = mr.patient_id AND permitted.doctor_id = ?) "
                + "AND mr.processed_at IS NOT NULL "
                + "ORDER BY mr.processed_at DESC, mr.record_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MedicalRecord item = new MedicalRecord();
                    item.setRecordId(rs.getInt("record_id"));
                    item.setHealthRecordId(rs.getInt("health_record_id"));
                    item.setPatientId(rs.getInt("patient_id"));
                    item.setDoctorId(rs.getInt("doctor_id"));
                    item.setDoctorName(rs.getString("doctor_name"));
                    item.setDoctorNote(rs.getString("doctor_note"));
                    item.setFinalDiagnosis(rs.getString("final_diagnosis"));
                    item.setResultVisibility(rs.getBoolean("result_visibility"));
                    item.setProcessedAt(rs.getTimestamp("processed_at"));
                    item.setRevisitDate(rs.getTimestamp("revisit_date"));
                    item.setUrea(rs.getDouble("urea"));
                    item.setCr(rs.getDouble("cr"));
                    item.setHba1c(rs.getDouble("hba1c"));
                    item.setChol(rs.getDouble("chol"));
                    item.setTg(rs.getDouble("tg"));
                    item.setHdl(rs.getDouble("hdl"));
                    item.setLdl(rs.getDouble("ldl"));
                    item.setVldl(rs.getDouble("vldl"));
                    item.setBmi(rs.getDouble("bmi"));
                    
                    item.setDiabetesProbability(rs.getDouble("diabetes_probability"));
                    item.setPreDiabetesProbability(rs.getDouble("pre_diabetes_probability"));
                    item.setNormalProbability(rs.getDouble("normal_probability"));
                    
                    history.add(item);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return history;
    }

    public List<Map<String, Object>> getActiveLabDoctors() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT lab_id, full_name, lab_name FROM Doctor_Lab ORDER BY full_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> map = new LinkedHashMap<>();
                map.put("labId", rs.getInt("lab_id"));
                map.put("fullName", rs.getString("full_name"));
                map.put("labName", rs.getString("lab_name"));
                list.add(map);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<LaboratoryRequest> getLaboratoryRequests(int recordId, int doctorId) {
        List<LaboratoryRequest> requests = new ArrayList<>();
        String sql = "SELECT id.invoice_detail_id, id.invoice_id, id.health_record_id, "
                + "i.patient_id, id.doctor_id, id.service_id, ms.service_name, id.price, "
                + "id.request_note, id.lab_status, id.lab_result, i.status AS invoice_status, "
                + "id.requested_at, id.completed_at, hr.urea, hr.cr, hr.hba1c, "
                + "hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl, hr.bmi, hr.weight, hr.height, "
                + "id.lab_id, dl.full_name AS lab_doctor_name, "
                + "COALESCE((SELECT TOP 1 r.room_name + ' - ' + r.room_id FROM Lab_Schedule ls "
                + "JOIN Room r ON ls.room_id = r.room_id "
                + "WHERE ls.lab_id = id.lab_id AND ls.work_date = CAST(GETDATE() AS date) "
                + "AND LOWER(ls.status) = 'scheduled' ORDER BY ls.lab_sched_id DESC), dl.lab_name) AS lab_room_name "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "JOIN Healthy_Record hr ON hr.health_record_id = id.health_record_id "
                + "LEFT JOIN Doctor_Lab dl ON dl.lab_id = id.lab_id "
                + "WHERE id.health_record_id = ? AND hr.doctor_id = ? "
                + "AND id.lab_status IS NOT NULL "
                + "ORDER BY id.requested_at DESC, id.invoice_detail_id DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            ps.setInt(2, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LaboratoryRequest item = new LaboratoryRequest();
                    item.setLaboratoryRequestId(rs.getInt("invoice_detail_id"));
                    item.setInvoiceId(rs.getInt("invoice_id"));
                    item.setInvoiceStatus(rs.getString("invoice_status"));
                    item.setHealthRecordId(rs.getInt("health_record_id"));
                    item.setPatientId(rs.getInt("patient_id"));
                    item.setDoctorId(rs.getInt("doctor_id"));
                    item.setServiceId((Integer) rs.getObject("service_id"));
                    item.setTestType(rs.getString("service_name"));
                    item.setTestPrice(rs.getBigDecimal("price"));
                    item.setRequestNote(rs.getString("request_note"));
                    item.setStatus(rs.getString("lab_status"));
                    item.setResult(rs.getString("lab_result"));
                    item.setRequestedAt(rs.getTimestamp("requested_at"));
                    item.setCompletedAt(rs.getTimestamp("completed_at"));
                    int labIdVal = rs.getInt("lab_id");
                    item.setLabId(rs.wasNull() ? null : labIdVal);
                    item.setLabDoctorName(rs.getString("lab_doctor_name"));
                    item.setLabName(rs.getString("lab_room_name"));
                    mapLaboratoryValues(rs, item);
                    requests.add(item);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return requests;
    }

    public boolean hasCompletedLaboratoryRequest(int recordId, int doctorId) {
        return getLaboratoryStage(recordId, doctorId) == LaboratoryStage.COMPLETED;
    }

    public boolean hasLaboratoryRequest(int recordId, int doctorId) {
        return getLaboratoryStage(recordId, doctorId) != LaboratoryStage.NONE;
    }

    public boolean hasPaidLaboratoryRequest(int recordId, int doctorId) {
        LaboratoryStage stage = getLaboratoryStage(recordId, doctorId);
        return stage == LaboratoryStage.LABORATORY
                || stage == LaboratoryStage.COMPLETED;
    }

    public LaboratoryStage getLaboratoryStage(int recordId, int doctorId) {
        String sql = "SELECT "
                + "COUNT(*) AS request_count, "
                + "SUM(CASE WHEN i.status = 'Paid' OR id.lab_status IN ('Requested', 'Processing', 'Completed') THEN 1 ELSE 0 END) AS paid_count, "
                + "SUM(CASE WHEN id.lab_status = 'Completed' THEN 1 ELSE 0 END) AS completed_count "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "LEFT JOIN Medical_record mr ON mr.health_record_id = ? "
                + "WHERE (id.health_record_id = ? OR (mr.appointment_id IS NOT NULL AND id.appointment_id = mr.appointment_id) OR i.patient_id = (SELECT patient_id FROM Healthy_Record WHERE health_record_id = ?)) "
                + "AND id.lab_status IS NOT NULL";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recordId);
            ps.setInt(2, recordId);
            ps.setInt(3, recordId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getInt("request_count") == 0) {
                    return LaboratoryStage.NONE;
                }
                if (rs.getInt("completed_count") > 0) {
                    return LaboratoryStage.COMPLETED;
                }
                if (rs.getInt("paid_count") > 0) {
                    return LaboratoryStage.LABORATORY;
                }
                return LaboratoryStage.WAITING_PAYMENT;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return LaboratoryStage.NONE;
        }
    }

    public List<LaboratoryRequest> getLaboratoryRequestsByDoctor(int doctorId, String status) {
        List<LaboratoryRequest> requests = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT id.invoice_detail_id, id.invoice_id, id.health_record_id, "
                + "i.patient_id, id.doctor_id, id.service_id, ms.service_name, id.price, "
                + "id.request_note, id.lab_status, id.lab_result, "
                + "i.status AS invoice_status, id.requested_at, id.completed_at, "
                + "hr.urea, hr.cr, hr.hba1c, "
                + "hr.chol, hr.tg, hr.hdl, hr.ldl, hr.vldl, hr.bmi, hr.weight, hr.height, "
                + "id.lab_id, dl.full_name AS lab_doctor_name, "
                + "COALESCE((SELECT TOP 1 r.room_name + ' - ' + r.room_id FROM Lab_Schedule ls "
                + "JOIN Room r ON ls.room_id = r.room_id "
                + "WHERE ls.lab_id = id.lab_id AND ls.work_date = CAST(GETDATE() AS date) "
                + "AND LOWER(ls.status) = 'scheduled' ORDER BY ls.lab_sched_id DESC), dl.lab_name) AS lab_room_name "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "JOIN Healthy_Record hr ON hr.health_record_id = id.health_record_id "
                + "LEFT JOIN Doctor_Lab dl ON dl.lab_id = id.lab_id "
                + "WHERE id.doctor_id = ? AND id.lab_status IS NOT NULL ");
        boolean hasStatus = status != null && !status.trim().isEmpty()
                && !"All".equalsIgnoreCase(status);
        if (hasStatus) {
            sql.append("AND id.lab_status = ? ");
        }
        sql.append("ORDER BY CASE id.lab_status WHEN 'Waiting_Payment' THEN 1 "
                + "WHEN 'Requested' THEN 2 WHEN 'Processing' THEN 3 ELSE 4 END, "
                + "id.requested_at DESC, id.invoice_detail_id DESC");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setInt(1, doctorId);
            if (hasStatus) {
                ps.setString(2, status);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LaboratoryRequest item = new LaboratoryRequest();
                    item.setLaboratoryRequestId(rs.getInt("invoice_detail_id"));
                    item.setInvoiceId(rs.getInt("invoice_id"));
                    item.setInvoiceStatus(rs.getString("invoice_status"));
                    item.setHealthRecordId(rs.getInt("health_record_id"));
                    item.setPatientId(rs.getInt("patient_id"));
                    item.setDoctorId(rs.getInt("doctor_id"));
                    item.setServiceId((Integer) rs.getObject("service_id"));
                    item.setTestType(rs.getString("service_name"));
                    item.setTestPrice(rs.getBigDecimal("price"));
                    item.setRequestNote(rs.getString("request_note"));
                    item.setStatus(rs.getString("lab_status"));
                    item.setResult(rs.getString("lab_result"));
                    item.setRequestedAt(rs.getTimestamp("requested_at"));
                    item.setCompletedAt(rs.getTimestamp("completed_at"));
                    int labIdVal = rs.getInt("lab_id");
                    item.setLabId(rs.wasNull() ? null : labIdVal);
                    item.setLabDoctorName(rs.getString("lab_doctor_name"));
                    item.setLabName(rs.getString("lab_room_name"));
                    mapLaboratoryValues(rs, item);
                    requests.add(item);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return requests;
    }

    private void mapLaboratoryValues(ResultSet rs, LaboratoryRequest item)
            throws SQLException {
        item.setUrea(nullableDouble(rs, "urea"));
        item.setCr(nullableDouble(rs, "cr"));
        item.setHba1c(nullableDouble(rs, "hba1c"));
        item.setChol(nullableDouble(rs, "chol"));
        item.setTg(nullableDouble(rs, "tg"));
        item.setHdl(nullableDouble(rs, "hdl"));
        item.setLdl(nullableDouble(rs, "ldl"));
        item.setVldl(nullableDouble(rs, "vldl"));
        item.setBmi(nullableDouble(rs, "bmi"));
        item.setWeight(nullableDouble(rs, "weight"));
        item.setHeight(nullableDouble(rs, "height"));
    }

    private Double nullableDouble(ResultSet rs, String column) throws SQLException {
        double value = rs.getDouble(column);
        return rs.wasNull() ? null : value;
    }

    public List<MedicalService> getActiveLaboratoryServices() {
        List<MedicalService> services = new ArrayList<>();
        String sql = "SELECT service_id, service_name, price, service_type, status "
                + "FROM Medical_Service WHERE service_type = 'Lab_Test' "
                + "AND status = 'Active' ORDER BY service_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MedicalService service = new MedicalService();
                service.setServiceId(rs.getInt("service_id"));
                service.setServiceName(rs.getString("service_name"));
                service.setPrice(rs.getBigDecimal("price"));
                service.setServiceType(rs.getString("service_type"));
                service.setStatus(rs.getString("status"));
                services.add(service);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return services;
    }

    public List<Map<String, Object>> getScheduledLabDoctors() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT DISTINCT dl.lab_id, dl.full_name, r.room_id, r.room_name "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "JOIN Room r ON ls.room_id = r.room_id "
                + "WHERE ls.work_date = CAST(GETDATE() AS date) "
                + "AND LOWER(ls.status) = 'scheduled' "
                + "ORDER BY dl.full_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> map = new LinkedHashMap<>();
                map.put("labId", rs.getInt("lab_id"));
                map.put("fullName", rs.getString("full_name"));
                String roomDetail = rs.getString("room_name") + " - " + rs.getString("room_id");
                map.put("labName", roomDetail);
                list.add(map);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Fallback: if no schedules today, return all active lab doctors
        if (list.isEmpty()) {
            return getActiveLabDoctors();
        }
        return list;
    }

    public boolean createLaboratoryRequest(
            int recordId, int doctorId, int[] selectedServiceIds,
            String requestNote, int labId) throws SQLException {
        if (selectedServiceIds == null || selectedServiceIds.length == 0) {
            throw new SQLException("Vui l\u00f2ng ch\u1ecdn \u00edt nh\u1ea5t m\u1ed9t lo\u1ea1i x\u00e9t nghi\u1ec7m");
        }

        Set<Integer> serviceIds = new LinkedHashSet<>();
        for (int serviceId : selectedServiceIds) {
            if (serviceId > 0) {
                serviceIds.add(serviceId);
            }
        }
        if (serviceIds.isEmpty()) {
            throw new SQLException("Danh s\u00e1ch x\u00e9t nghi\u1ec7m kh\u00f4ng h\u1ee3p l\u1ec7");
        }

        String recordSql = "SELECT hr.patient_id, mr.appointment_id "
                + "FROM Healthy_Record hr WITH (UPDLOCK, ROWLOCK) "
                + "LEFT JOIN Medical_record mr "
                + "ON mr.health_record_id = hr.health_record_id "
                + "WHERE hr.health_record_id = ? AND hr.doctor_id = ? "
                + "AND hr.status IN ('Accepted', 'AI_Processed', 'Editing')";
        String placeholders = String.join(",",
                java.util.Collections.nCopies(serviceIds.size(), "?"));
        String serviceSql = "SELECT service_id, price FROM Medical_Service "
                + "WHERE service_id IN (" + placeholders + ") "
                + "AND service_type = 'Lab_Test' AND status = 'Active'";
        String duplicateSql = "SELECT COUNT(*) FROM Invoice_Detail "
                + "WHERE health_record_id = ? AND service_id = ? "
                + "AND lab_status IN ('Waiting_Payment', 'Requested', 'Processing')";
        String invoiceSql = "INSERT INTO Invoice "
                + "(patient_id, receptionist_id, total_amount, insurance_deduction, "
                + "final_amount, payment_method, status, created_at) "
                + "VALUES (?, NULL, ?, 0, ?, NULL, 'Pending', GETDATE())";
        String detailSql = "INSERT INTO Invoice_Detail "
                + "(invoice_id, service_id, appointment_id, quantity, price, "
                + "health_record_id, doctor_id, request_note, lab_status, requested_at, lab_id) "
                + "VALUES (?, ?, ?, 1, ?, ?, ?, ?, 'Waiting_Payment', GETDATE(), ?)";
        String ensureMedicalSql = "IF NOT EXISTS (SELECT 1 FROM Medical_record WHERE health_record_id = ?) "
                + "INSERT INTO Medical_record (patient_id, doctor_id, health_record_id, "
                + "result_visibility, processed_at) VALUES (?, ?, ?, 0, NULL)";
        String syncMedicalSql = "UPDATE mr SET "
                + "laboratory_test_types = x.test_types, laboratory_total_price = x.total_price "
                + "FROM Medical_record mr CROSS APPLY ("
                + "SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), ms.service_name), N', ') AS test_types, "
                + "SUM(COALESCE(id.price, 0) * id.quantity) AS total_price "
                + "FROM Invoice_Detail id JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.health_record_id = mr.health_record_id AND id.lab_status IS NOT NULL"
                + ") x WHERE mr.health_record_id = ?";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int patientId;
                Integer appointmentId;
                try (PreparedStatement ps = conn.prepareStatement(recordSql)) {
                    ps.setInt(1, recordId);
                    ps.setInt(2, doctorId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("H\u1ed3 s\u01a1 kh\u00f4ng thu\u1ed9c b\u00e1c s\u0129 ho\u1eb7c ch\u01b0a \u1edf tr\u1ea1ng th\u00e1i cho ph\u00e9p");
                        }
                        patientId = rs.getInt("patient_id");
                        int linkedAppointmentId = rs.getInt("appointment_id");
                        appointmentId = rs.wasNull() ? null : linkedAppointmentId;
                    }
                }

                Map<Integer, BigDecimal> prices = new LinkedHashMap<>();
                try (PreparedStatement ps = conn.prepareStatement(serviceSql)) {
                    int index = 1;
                    for (Integer serviceId : serviceIds) {
                        ps.setInt(index++, serviceId);
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            prices.put(rs.getInt("service_id"),
                                    rs.getBigDecimal("price"));
                        }
                    }
                }
                if (prices.size() != serviceIds.size()) {
                    throw new SQLException(
                            "C\u00f3 lo\u1ea1i x\u00e9t nghi\u1ec7m kh\u00f4ng h\u1ee3p l\u1ec7 ho\u1eb7c \u0111\u00e3 ng\u1eebng \u00e1p d\u1ee5ng");
                }

                try (PreparedStatement ps = conn.prepareStatement(duplicateSql)) {
                    for (Integer serviceId : serviceIds) {
                        ps.setInt(1, recordId);
                        ps.setInt(2, serviceId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next() && rs.getInt(1) > 0) {
                                throw new SQLException(
                                        "X\u00e9t nghi\u1ec7m \u0111\u00e3 \u0111\u01b0\u1ee3c ch\u1ec9 \u0111\u1ecbnh tr\u01b0\u1edbc \u0111\u00f3");
                            }
                        }
                    }
                }

                BigDecimal totalPrice = BigDecimal.ZERO;
                for (BigDecimal price : prices.values()) {
                    totalPrice = totalPrice.add(price);
                }

                int invoiceId;
                try (PreparedStatement ps = conn.prepareStatement(
                        invoiceSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, patientId);
                    ps.setBigDecimal(2, totalPrice);
                    ps.setBigDecimal(3, totalPrice);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Kh\u00f4ng th\u1ec3 t\u1ea1o h\u00f3a \u0111\u01a1n x\u00e9t nghi\u1ec7m");
                    }
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Kh\u00f4ng l\u1ea5y \u0111\u01b0\u1ee3c m\u00e3 h\u00f3a \u0111\u01a1n x\u00e9t nghi\u1ec7m");
                        }
                        invoiceId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(detailSql)) {
                    for (Map.Entry<Integer, BigDecimal> entry : prices.entrySet()) {
                        int serviceId = entry.getKey();

                        ps.setInt(1, invoiceId);
                        ps.setInt(2, serviceId);
                        if (appointmentId == null) {
                            ps.setNull(3, java.sql.Types.INTEGER);
                        } else {
                            ps.setInt(3, appointmentId);
                        }
                        ps.setBigDecimal(4, entry.getValue());
                        ps.setInt(5, recordId);
                        ps.setInt(6, doctorId);
                        ps.setString(7, requestNote);
                        if (labId <= 0) {
                            ps.setNull(8, java.sql.Types.INTEGER);
                        } else {
                            ps.setInt(8, labId);
                        }
                        ps.addBatch();
                    }
                    int[] insertedRows = ps.executeBatch();
                    if (insertedRows.length != prices.size()) {
                        throw new SQLException("Kh\u00f4ng th\u1ec3 t\u1ea1o chi ti\u1ebft ch\u1ec9 \u0111\u1ecbnh x\u00e9t nghi\u1ec7m");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(ensureMedicalSql)) {
                    ps.setInt(1, recordId);
                    ps.setInt(2, patientId);
                    ps.setInt(3, doctorId);
                    ps.setInt(4, recordId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(syncMedicalSql)) {
                    ps.setInt(1, recordId);
                    ps.executeUpdate();
                }
                String updateHealthyRecordSql = "UPDATE Healthy_Record SET invoice_id = ? WHERE health_record_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateHealthyRecordSql)) {
                    ps.setInt(1, invoiceId);
                    ps.setInt(2, recordId);
                    ps.executeUpdate();
                }
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

    public boolean saveMedicalRecordAndCompleteForDoctor(
            int healthRecordId,
            int doctorId,
            String notes,
            String diagnosis,
            boolean canView,
            Timestamp revisitDate) throws SQLException {

        String lockSql = "SELECT patient_id, status FROM Healthy_Record WITH (UPDLOCK, ROWLOCK) "
                + "WHERE health_record_id = ? AND doctor_id = ?";
        String existsSql = "SELECT COUNT(*) FROM Medical_record WHERE health_record_id = ?";
        String insertSql = "INSERT INTO Medical_record "
                + "(patient_id, doctor_id, final_diagnosis, doctor_note, health_record_id, "
                + "result_visibility, processed_at, revisit_date) VALUES (?, ?, ?, ?, ?, ?, GETDATE(), ?)";
        String updateSql = "UPDATE Medical_record SET doctor_id = ?, patient_id = ?, "
                + "doctor_note = ?, final_diagnosis = ?, result_visibility = ?, "
                + "revisit_date = ?, processed_at = GETDATE() WHERE health_record_id = ?";
        String statusSql = "UPDATE Healthy_Record SET status = 'Completed' "
                + "WHERE health_record_id = ? AND doctor_id = ? "
                + "AND status IN ('Accepted', 'AI_Processed', 'Editing', 'Completed')";
        String appointmentStatusSql = "UPDATE a SET a.status = 'Completed' "
                + "FROM Appointment a "
                + "JOIN Medical_record mr ON mr.appointment_id = a.appointment_id "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE mr.health_record_id = ? AND ds.doctor_id = ? "
                + "AND a.status = 'In_Progress'";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int patientId;
                String currentStatus;
                try (PreparedStatement ps = conn.prepareStatement(lockSql)) {
                    ps.setInt(1, healthRecordId);
                    ps.setInt(2, doctorId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Ho so khong thuoc bac si hien tai");
                        }
                        patientId = rs.getInt("patient_id");
                        currentStatus = rs.getString("status");
                    }
                }

                if (!"Accepted".equals(currentStatus)
                        && !"AI_Processed".equals(currentStatus)
                        && !"Editing".equals(currentStatus)
                        && !"Completed".equals(currentStatus)) {
                    throw new SQLException("Ho so khong o trang thai cho phep chinh sua");
                }

                boolean exists;
                try (PreparedStatement ps = conn.prepareStatement(existsSql)) {
                    ps.setInt(1, healthRecordId);
                    try (ResultSet rs = ps.executeQuery()) {
                        exists = rs.next() && rs.getInt(1) > 0;
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(exists ? updateSql : insertSql)) {
                    if (exists) {
                        ps.setInt(1, doctorId);
                        ps.setInt(2, patientId);
                        ps.setString(3, notes);
                        ps.setString(4, diagnosis);
                        ps.setBoolean(5, canView);
                        if (revisitDate != null) {
                            ps.setTimestamp(6, revisitDate);
                        } else {
                            ps.setNull(6, java.sql.Types.TIMESTAMP);
                        }
                        ps.setInt(7, healthRecordId);
                    } else {
                        ps.setInt(1, patientId);
                        ps.setInt(2, doctorId);
                        ps.setString(3, diagnosis);
                        ps.setString(4, notes);
                        ps.setInt(5, healthRecordId);
                        ps.setBoolean(6, canView);
                        if (revisitDate != null) {
                            ps.setTimestamp(7, revisitDate);
                        } else {
                            ps.setNull(7, java.sql.Types.TIMESTAMP);
                        }
                    }
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Khong the luu Medical_record");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                    ps.setInt(1, healthRecordId);
                    ps.setInt(2, doctorId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Trang thai ho so da thay doi");
                    }
                }

                try (PreparedStatement ps =
                        conn.prepareStatement(appointmentStatusSql)) {
                    ps.setInt(1, healthRecordId);
                    ps.setInt(2, doctorId);
                    ps.executeUpdate();
                }

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

    public List<Map<String, Object>> getDoctorSchedulesByAccountId(int accountId) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, ds.status, r.room_id, r.room_name, "
                + "(SELECT COUNT(*) FROM Appointment a WHERE a.schedule_id = ds.schedule_id AND a.status <> 'Cancelled') AS booked_patients "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                + "WHERE d.account_id = ? "
                + "ORDER BY ds.work_date DESC, ds.time_slot ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("scheduleId", rs.getInt("schedule_id"));
                    map.put("workDate", rs.getDate("work_date"));
                    map.put("timeSlot", rs.getString("time_slot"));
                    map.put("maxPatients", rs.getInt("max_patients"));
                    map.put("status", rs.getString("status"));
                    map.put("roomId", rs.getString("room_id"));
                    map.put("roomName", rs.getString("room_name"));
                    map.put("bookedPatients", rs.getInt("booked_patients"));
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Map<String, Object>> getLabSchedulesByAccountId(int accountId) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT ls.lab_sched_id, ls.work_date, ls.time_slot, ls.status, r.room_id, r.room_name "
                + "FROM Lab_Schedule ls "
                + "JOIN Doctor_Lab dl ON dl.lab_id = ls.lab_id "
                + "LEFT JOIN Room r ON r.room_id = ls.room_id "
                + "WHERE dl.account_id = ? "
                + "ORDER BY ls.work_date DESC, ls.time_slot ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("labSchedId", rs.getInt("lab_sched_id"));
                    map.put("workDate", rs.getDate("work_date"));
                    map.put("timeSlot", rs.getString("time_slot"));
                    map.put("status", rs.getString("status"));
                    map.put("roomId", rs.getString("room_id"));
                    map.put("roomName", rs.getString("room_name"));
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}

