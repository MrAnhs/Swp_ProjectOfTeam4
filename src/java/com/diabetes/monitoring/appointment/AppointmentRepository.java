package com.diabetes.monitoring.appointment;

import com.diabetes.monitoring.util.DatabaseConnection;

import static com.diabetes.monitoring.admin.common.AdminJdbcSupport.hasColumn;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository xử lý workflow và dữ liệu Appointment dùng chung theo đúng phân quyền.
 */
public class AppointmentRepository {

    private static final Logger LOGGER =
            Logger.getLogger(AppointmentRepository.class.getName());

        public int markLateWaitingAppointmentsAsNoShow() {
        String sql = "UPDATE a SET a.status = 'Absent' "
            + "FROM Appointment a "
            + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
            + "WHERE LOWER(a.status) = 'waiting' "
            + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
            + "AND ("
            + "    (ds.schedule_id IS NOT NULL AND TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5)) IS NOT NULL "
            + "        AND DATEADD(MINUTE, -30, DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), CAST(TRY_CONVERT(time, LEFT(LTRIM(RTRIM(SUBSTRING(ds.time_slot, CHARINDEX('-', ds.time_slot) + 1, 20))), 5)) AS datetime))) <= GETDATE()) "
            + " OR (ds.schedule_id IS NULL AND DATEADD(MINUTE, 30, a.appointment_time) <= GETDATE())"
            + ")";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            int updated = statement.executeUpdate();
            if (updated > 0) {
                LOGGER.log(Level.INFO, "Auto-marked late waiting appointments as Absent: {0}", updated);
            }
            return updated;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to mark late waiting appointments as Absent", e);
            return 0;
        }
    }

    public boolean startAppointment(int appointmentId) {
        return updateAppointmentStatus(appointmentId, "In_Progress", "Checked_In");
    }

    public boolean completeAppointment(int appointmentId) {
        return updateAppointmentStatus(appointmentId, "Completed", "In_Progress", "In-Progress");
    }

    private boolean updateAppointmentStatus(int appointmentId, String newStatus, String... allowedCurrentStatuses) {
        if (appointmentId <= 0 || newStatus == null || newStatus.trim().isEmpty()) {
            return false;
        }

        StringBuilder sql = new StringBuilder("UPDATE Appointment SET status = ? WHERE appointment_id = ?");
        if (allowedCurrentStatuses != null && allowedCurrentStatuses.length > 0) {
            sql.append(" AND LOWER(status) IN (");
            for (int i = 0; i < allowedCurrentStatuses.length; i++) {
                if (i > 0) {
                    sql.append(", ");
                }
                sql.append("?");
            }
            sql.append(")");
        }

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int index = 1;
            statement.setString(index++, newStatus);
            statement.setInt(index++, appointmentId);
            if (allowedCurrentStatuses != null && allowedCurrentStatuses.length > 0) {
                for (String allowedStatus : allowedCurrentStatuses) {
                    statement.setString(index++, allowedStatus == null ? null : allowedStatus.toLowerCase(Locale.ROOT).replace('-', '_'));
                }
            }
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update appointment status for appointmentId=" + appointmentId + " to " + newStatus, e);
            return false;
        }
    }

    public List<Map<String, Object>> getTodayClinicQueueStatus() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT d.doctor_id, d.full_name AS doctor_name, d.department, "
                + "COUNT(a.appointment_id) AS waiting_count "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
            + "LEFT JOIN Appointment a ON a.schedule_id = ds.schedule_id AND LOWER(a.status) = 'checked_in' "
                + "WHERE ds.work_date = CAST(GETDATE() AS DATE) "
                + "AND LOWER(ds.status) <> 'cancelled' "
                + "GROUP BY d.doctor_id, d.full_name, d.department "
                + "ORDER BY waiting_count DESC, d.full_name ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("doctorId", rs.getInt("doctor_id"));
                row.put("doctorName", rs.getString("doctor_name"));
                row.put("department", rs.getString("department"));
                row.put("waitingCount", rs.getInt("waiting_count"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today clinic queue status", e);
        }

        return rows;
    }

    public List<Map<String, Object>> getDoctorQueueDetailToday(int doctorId) {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, p.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE ds.doctor_id = ? "
                + "AND LOWER(a.status) IN ('checked_in', 'in_progress', 'in-progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    rows.add(row);
                }
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Primary queue-detail query failed; fallback to Account join", e);
        }

        String fallbackSql = "SELECT a.appointment_id, acc.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status "
                + "FROM Appointment a "
                + "JOIN Account acc ON a.patient_id = acc.account_id "
                + "JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE ds.doctor_id = ? "
                + "AND LOWER(a.status) IN ('checked_in', 'in_progress', 'in-progress') "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
            statement.setInt(1, doctorId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load queue detail for doctorId=" + doctorId, e);
        }

        return rows;
    }

    public List<Map<String, Object>> getTodayAppointments() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, "
                + "COALESCE(p.full_name, acc.full_name, N'Chưa xác định') AS patient_name, "
                + "COALESCE(d.full_name, N'Chưa phân công') AS doctor_name, "
                + "FORMAT(a.appointment_time, 'dd/MM/yyyy') AS appointment_date, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, "
                + "a.status "
                + "FROM Appointment a "
                + "LEFT JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Account acc ON acc.account_id = a.patient_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "AND LOWER(a.status) = 'completed' "
                + "AND a.appointment_time <= GETDATE() "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("appointmentId", rs.getInt("appointment_id"));
                row.put("patientName", rs.getString("patient_name"));
                row.put("doctorName", rs.getString("doctor_name"));
                row.put("appointmentDate", rs.getString("appointment_date"));
                row.put("appointmentTime", rs.getString("appointment_time"));
                row.put("status", rs.getString("status"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today appointments", e);
        }

        return rows;
    }

    public List<Map<String, Object>> getTodayWaitingDetails() {
        markLateWaitingAppointmentsAsNoShow();

        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT a.appointment_id, "
                + "COALESCE(p.full_name, acc.full_name, N'Chưa xác định') AS patient_name, "
                + "COALESCE(d.department, N'Chưa xác định') AS department, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, "
                + "a.status, "
                + "CASE WHEN DATEDIFF(MINUTE, a.appointment_time, GETDATE()) < 0 THEN 0 "
                + "ELSE DATEDIFF(MINUTE, a.appointment_time, GETDATE()) END AS waiting_minutes "
                + "FROM Appointment a "
                + "LEFT JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Account acc ON acc.account_id = a.patient_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE LOWER(a.status) = 'checked_in' "
                + "AND CAST(a.appointment_time AS DATE) = CAST(GETDATE() AS DATE) "
                + "ORDER BY a.appointment_time ASC, a.appointment_id ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("appointmentId", rs.getInt("appointment_id"));
                row.put("patientName", rs.getString("patient_name"));
                row.put("department", rs.getString("department"));
                row.put("appointmentTime", rs.getString("appointment_time"));
                row.put("status", rs.getString("status"));
                row.put("waitingMinutes", rs.getInt("waiting_minutes"));
                rows.add(row);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load today waiting details", e);
        }

        return rows;
    }

    public List<Map<String, Object>> getAppointmentsBySchedule(int scheduleId) {
        List<Map<String, Object>> rows = new ArrayList<>();
        boolean hasBookingSource = hasColumn("Appointment", "booking_source");
        boolean hasBookingType = hasColumn("Appointment", "booking_type");
        String bookingSourceExpression = hasBookingSource
                ? "a.booking_source"
                : (hasBookingType ? "a.booking_type" : "'Online'");
        String sql = "SELECT a.appointment_id, p.full_name, "
                + "FORMAT(a.appointment_time, 'HH:mm') AS appointment_time, a.status, "
                + bookingSourceExpression + " AS booking_source "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "WHERE a.schedule_id = ? "
                + "ORDER BY a.appointment_time ASC";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("appointmentId", rs.getInt("appointment_id"));
                    row.put("patientName", rs.getString("full_name"));
                    row.put("appointmentTime", rs.getString("appointment_time"));
                    row.put("status", rs.getString("status"));
                    row.put("bookingSource", rs.getString("booking_source"));
                    rows.add(row);
                }
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Failed to load appointments for schedule " + scheduleId, e);
        }
        return rows;
    }

    public boolean canCompleteConsultationByMinimumTime(int appointmentId, int minMinutes) {
        if (appointmentId <= 0 || minMinutes <= 0) {
            return false;
        }
        if (!hasColumn("Appointment", "consultation_start_time")) {
            LOGGER.log(Level.INFO, "consultation_start_time does not exist; skip minimum consultation-time guard");
            return true;
        }

        String sql = "SELECT CASE "
                + "WHEN consultation_start_time IS NULL THEN 0 "
                + "WHEN DATEDIFF(MINUTE, consultation_start_time, GETDATE()) >= ? THEN 1 "
                + "ELSE 0 END AS can_complete "
                + "FROM Appointment WHERE appointment_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, minMinutes);
            statement.setInt(2, appointmentId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("can_complete") == 1;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to evaluate minimum consultation time", e);
        }
        return false;
    }
}

