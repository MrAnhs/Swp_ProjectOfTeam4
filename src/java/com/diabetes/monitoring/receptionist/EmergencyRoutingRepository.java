package com.diabetes.monitoring.receptionist;

import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.appointment.AppointmentRepository;

import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.bindParams;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository xử lý điều phối khẩn cấp và tái phân công bệnh nhân.
 */
public class EmergencyRoutingRepository {

    private static final Logger LOGGER =
            Logger.getLogger(EmergencyRoutingRepository.class.getName());

    private final AppointmentRepository appointmentRepository =
            new AppointmentRepository();

    public List<Map<String, Object>> getExceptionQueue(Integer doctorId) {
        appointmentRepository.markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT a.appointment_id, a.status AS appointment_status, a.appointment_time, "
                + "a.schedule_id, ds.doctor_id AS current_doctor_id, d.full_name AS current_doctor_name, d.department, "
                + "p.patient_id, p.full_name AS patient_name "
                + "FROM Appointment a "
                + "LEFT JOIN Doctor_Schedule ds ON a.schedule_id = ds.schedule_id "
                + "LEFT JOIN Doctor d ON ds.doctor_id = d.doctor_id "
                + "LEFT JOIN Patient p ON a.patient_id = p.patient_id "
                + "WHERE a.status IN ('Checked_In', 'In_Progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "AND a.appointment_time <= GETDATE()"
        );
        List<Object> params = new ArrayList<>();
        if (doctorId != null) {
            sql.append(" AND ds.doctor_id = ?");
            params.add(doctorId);
        }
        sql.append(" ORDER BY a.appointment_time ASC, a.appointment_id ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("appointmentStatus", rs.getString("appointment_status"));
                    row.put("appointmentTime", rs.getTimestamp("appointment_time"));
                    row.put("scheduleId", rs.getInt("schedule_id"));
                    row.put("currentDoctorId", rs.getInt("current_doctor_id"));
                    row.put("currentDoctorName", rs.getString("current_doctor_name"));
                    row.put("department", rs.getString("department"));
                    row.put("patientId", rs.getInt("patient_id"));
                    row.put("patientName", rs.getString("patient_name"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load exception queue", e);
        }
        return rows;
    }

    public List<Map<String, Object>> getAvailableDoctorsForEmergency(String department, Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active'"
        );
        List<Object> params = new ArrayList<>();
        if (department != null && !department.trim().isEmpty()) {
            sql.append(" AND d.department = ?");
            params.add(department.trim());
        }
        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }
        sql.append(" ORDER BY d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load available doctors for emergency", e);
        }
        return doctors;
    }

    public List<Map<String, Object>> getAllActiveDoctorsForEmergency(Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE LOWER(a.status) = 'active'"
        );
        List<Object> params = new ArrayList<>();
        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }
        sql.append(" ORDER BY d.department, d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load all active doctors for emergency", e);
        }
        return doctors;
    }

    public List<Map<String, Object>> getEmergencyCandidateDoctorsForAppointment(int appointmentId, Integer excludeDoctorId) {
        List<Map<String, Object>> doctors = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT DISTINCT d.doctor_id, d.full_name, d.department "
                + "FROM Appointment ap "
                + "JOIN Doctor_Schedule src_ds ON src_ds.schedule_id = ap.schedule_id "
                + "JOIN Doctor_Schedule ds ON ds.work_date = src_ds.work_date "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "JOIN Account a ON a.account_id = d.account_id "
                + "WHERE ap.appointment_id = ? "
                + "AND LOWER(a.status) = 'active' "
                + "AND LOWER(ds.status) <> 'cancelled'"
        );
        List<Object> params = new ArrayList<>();
        params.add(appointmentId);

        if (excludeDoctorId != null) {
            sql.append(" AND d.doctor_id <> ?");
            params.add(excludeDoctorId);
        }

        sql.append(" ORDER BY d.department, d.full_name ASC");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("doctorId", rs.getInt("doctor_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("department", rs.getString("department"));
                    doctors.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load emergency candidate doctors for appointmentId=" + appointmentId, e);
        }

        return doctors;
    }

    public boolean reassignAppointmentToDoctor(int appointmentId, int targetDoctorId) {
        String pickSameDayScheduleSql = "SELECT TOP 1 ds.schedule_id "
                + "FROM Appointment ap "
                + "JOIN Doctor_Schedule src_ds ON src_ds.schedule_id = ap.schedule_id "
                + "JOIN Doctor_Schedule ds ON ds.doctor_id = ? "
                + "WHERE ap.appointment_id = ? "
                + "AND ds.work_date = src_ds.work_date "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "ORDER BY TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) ASC";

        String pickFallbackScheduleSql = "SELECT TOP 1 ds.schedule_id "
                + "FROM Doctor_Schedule ds "
                + "WHERE ds.doctor_id = ? "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "AND ds.work_date >= CAST(GETDATE() AS DATE) "
                + "ORDER BY ds.work_date ASC, TRY_CAST(LEFT(REPLACE(ds.time_slot, ' ', ''), 5) AS time) ASC";

        String updateAppointmentSql = "UPDATE Appointment "
                + "SET schedule_id = ?, doctor_id = ? "
                + "WHERE appointment_id = ? AND LOWER(status) IN ('checked_in', 'in_progress', 'in-progress')";

        try (Connection connection = DatabaseConnection.getConnection()) {
            Integer targetScheduleId = null;

            try (PreparedStatement pick = connection.prepareStatement(pickSameDayScheduleSql)) {
                pick.setInt(1, targetDoctorId);
                pick.setInt(2, appointmentId);
                try (ResultSet rs = pick.executeQuery()) {
                    if (rs.next()) {
                        targetScheduleId = rs.getInt("schedule_id");
                    }
                }
            }

            if (targetScheduleId == null) {
                try (PreparedStatement pick = connection.prepareStatement(pickFallbackScheduleSql)) {
                    pick.setInt(1, targetDoctorId);
                    try (ResultSet rs = pick.executeQuery()) {
                        if (rs.next()) {
                            targetScheduleId = rs.getInt("schedule_id");
                        }
                    }
                }
            }

            if (targetScheduleId == null) {
                return false;
            }

            try (PreparedStatement update = connection.prepareStatement(updateAppointmentSql)) {
                update.setInt(1, targetScheduleId);
                update.setInt(2, targetDoctorId);
                update.setInt(3, appointmentId);
                return update.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to reassign appointment in emergency routing", e);
            return false;
        }
    }
}
