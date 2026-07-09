package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.PatientVisit;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class PatientVisitDAO {
    private static final String SELECT =
            "SELECT a.appointment_id, a.appointment_time, a.status appointment_status, "
            + "d.full_name doctor_name, d.department, mr.record_id, mr.result_visibility, "
            + "mr.final_diagnosis, mr.doctor_note, mr.processed_at, "
            + "hr.health_record_id, hr.status health_record_status, hr.urea, hr.cr, hr.hba1c, "
            + "hr.chol, hr.tg, hr.hdl, hr.idl AS ldl, hr.vldl, hr.bmi, hr.weight, hr.height, "
            + "hr.other_information "
            + "FROM Appointment a "
            + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
            + "INNER JOIN Doctor d ON d.doctor_id = a.doctor_id "
            + "LEFT JOIN Medical_record mr ON mr.appointment_id = a.appointment_id "
            + "OUTER APPLY (SELECT TOP 1 h.* FROM Healthy_Record h "
            + "WHERE h.record_id = mr.record_id OR h.health_record_id = mr.health_record_id "
            + "ORDER BY h.created_at DESC, h.health_record_id DESC) hr ";

    public List<PatientVisit> findByAccountId(int accountId) throws SQLException {
        String sql = SELECT + "WHERE p.account_id = ? "
                + "ORDER BY a.appointment_time DESC, a.appointment_id DESC";
        List<PatientVisit> visits = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) visits.add(map(resultSet));
            }
        }
        return visits;
    }

    public PatientVisit findByAppointmentId(int appointmentId, int accountId) throws SQLException {
        String sql = SELECT + "WHERE a.appointment_id = ? AND p.account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            statement.setInt(2, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? map(resultSet) : null;
            }
        }
    }

    private PatientVisit map(ResultSet rs) throws SQLException {
        PatientVisit visit = new PatientVisit();
        visit.appointmentId = rs.getInt("appointment_id");
        visit.appointmentTime = time(rs.getTimestamp("appointment_time"));
        visit.appointmentStatus = rs.getString("appointment_status");
        visit.doctorName = rs.getString("doctor_name");
        visit.department = rs.getString("department");

        int recordId = rs.getInt("record_id");
        visit.recordId = rs.wasNull() ? null : recordId;
        visit.resultVisible = visit.recordId != null && rs.getBoolean("result_visibility");
        visit.processedAt = time(rs.getTimestamp("processed_at"));

        int healthRecordId = rs.getInt("health_record_id");
        visit.healthRecordId = rs.wasNull() ? null : healthRecordId;
        visit.healthRecordStatus = rs.getString("health_record_status");

        if (visit.resultVisible) {
            visit.finalDiagnosis = rs.getString("final_diagnosis");
            visit.doctorNote = rs.getString("doctor_note");
            visit.urea = rs.getBigDecimal("urea");
            visit.cr = rs.getBigDecimal("cr");
            visit.hba1c = rs.getBigDecimal("hba1c");
            visit.chol = rs.getBigDecimal("chol");
            visit.tg = rs.getBigDecimal("tg");
            visit.hdl = rs.getBigDecimal("hdl");
            visit.ldl = rs.getBigDecimal("ldl");
            visit.vldl = rs.getBigDecimal("vldl");
            visit.bmi = rs.getBigDecimal("bmi");
            visit.weight = rs.getBigDecimal("weight");
            visit.height = rs.getBigDecimal("height");
            visit.otherInformation = rs.getString("other_information");
        }
        return visit;
    }

    private java.time.LocalDateTime time(Timestamp value) {
        return value == null ? null : value.toLocalDateTime();
    }
}
