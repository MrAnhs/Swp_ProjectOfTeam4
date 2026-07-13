package com.diabetes.monitoring.service;

import com.diabetes.monitoring.model.AppointmentBookingResult;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;

public class AppointmentService {

    public AppointmentBookingResult bookByDoctor(int accountId, int doctorId, int scheduleId)
            throws SQLException, AppointmentBookingException {
        Connection connection = null;
        try {
            connection = DatabaseConnection.getConnection();
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);

            int patientId = findPatientId(connection, accountId);
            ScheduleSelection schedule = lockSchedule(connection, doctorId, scheduleId);
            schedule.doctorId = doctorId;
            schedule.scheduleId = scheduleId;
            LocalDateTime appointmentTime = toAppointmentTime(schedule.workDate, schedule.timeSlot);

            if (!appointmentTime.isAfter(LocalDateTime.now())) {
                throw new AppointmentBookingException("Ca khám đã bắt đầu hoặc đã kết thúc.");
            }

            int bookedPatients = countBookedPatients(connection, scheduleId);
            if (bookedPatients >= schedule.maxPatients) {
                markScheduleFull(connection, scheduleId);
                throw new AppointmentBookingException("Ca khám đã đủ số lượng bệnh nhân.");
            }

            validatePatientBookingRules(connection, patientId, schedule, appointmentTime);

            int queueNumber = nextQueueNumber(connection, scheduleId);
            int appointmentId = insertAppointment(connection, patientId, scheduleId,
                    appointmentTime, queueNumber);

            if (bookedPatients + 1 >= schedule.maxPatients) {
                markScheduleFull(connection, scheduleId);
            }

            connection.commit();
            return createResult(appointmentId, scheduleId, queueNumber, appointmentTime, schedule);
        } catch (AppointmentBookingException | SQLException e) {
            rollback(connection);
            throw e;
        } catch (RuntimeException e) {
            rollback(connection);
            throw new AppointmentBookingException("Dữ liệu ca khám không hợp lệ.");
        } finally {
            close(connection);
        }
    }

    public AppointmentBookingResult bookByAvailability(int accountId, LocalDate workDate,
            String timeSlot) throws SQLException, AppointmentBookingException {
        Connection connection = null;
        try {
            connection = DatabaseConnection.getConnection();
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);

            int patientId = findPatientId(connection, accountId);
            ScheduleSelection schedule = lockBestAvailableSchedule(connection, workDate, timeSlot);
            LocalDateTime appointmentTime = toAppointmentTime(schedule.workDate, schedule.timeSlot);

            if (!appointmentTime.isAfter(LocalDateTime.now())) {
                throw new AppointmentBookingException("Ca khám đã bắt đầu hoặc đã kết thúc.");
            }

            int bookedPatients = countBookedPatients(connection, schedule.scheduleId);
            if (bookedPatients >= schedule.maxPatients) {
                throw new AppointmentBookingException("Ca khám đã đủ số lượng bệnh nhân.");
            }

            validatePatientBookingRules(connection, patientId, schedule, appointmentTime);

            int queueNumber = nextQueueNumber(connection, schedule.scheduleId);
            int appointmentId = insertAppointment(connection, patientId,
                    schedule.scheduleId, appointmentTime, queueNumber);

            if (bookedPatients + 1 >= schedule.maxPatients) {
                markScheduleFull(connection, schedule.scheduleId);
            }

            connection.commit();
            return createResult(appointmentId, schedule.scheduleId, queueNumber,
                    appointmentTime, schedule);
        } catch (AppointmentBookingException | SQLException e) {
            rollback(connection);
            throw e;
        } catch (RuntimeException e) {
            rollback(connection);
            throw new AppointmentBookingException("Dữ liệu ca khám không hợp lệ.");
        } finally {
            close(connection);
        }
    }

    private int findPatientId(Connection connection, int accountId)
            throws SQLException, AppointmentBookingException {
        String sql = "SELECT patient_id FROM Patient WHERE account_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("patient_id");
                }
            }
        }
        throw new AppointmentBookingException("Không tìm thấy hồ sơ bệnh nhân.");
    }

    private ScheduleSelection lockSchedule(Connection connection, int doctorId, int scheduleId)
            throws SQLException, AppointmentBookingException {
        String sql = "SELECT ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                + "d.full_name, d.department "
                + "FROM Doctor_Schedule ds WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "INNER JOIN Account a ON a.account_id = d.account_id "
                + "WHERE ds.schedule_id = ? AND ds.doctor_id = ? "
                + "AND a.role = 'Doctor' AND a.status = 'Active'";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            statement.setInt(2, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new AppointmentBookingException("Không tìm thấy ca khám của bác sĩ đã chọn.");
                }

                String status = resultSet.getString("status");
                if (!"Available".equals(status)) {
                    throw new AppointmentBookingException("Ca khám hiện không còn khả dụng.");
                }

                ScheduleSelection schedule = new ScheduleSelection();
                schedule.workDate = resultSet.getDate("work_date").toLocalDate();
                schedule.timeSlot = resultSet.getString("time_slot");
                schedule.maxPatients = resultSet.getInt("max_patients");
                schedule.doctorName = resultSet.getString("full_name");
                schedule.department = resultSet.getString("department");
                return schedule;
            }
        }
    }

    private ScheduleSelection lockBestAvailableSchedule(Connection connection, LocalDate workDate,
            String timeSlot) throws SQLException, AppointmentBookingException {
        String sql = "SELECT TOP 1 ds.schedule_id, ds.doctor_id, ds.work_date, ds.time_slot, "
                + "ds.max_patients, d.full_name, d.department, "
                + "SUM(CASE WHEN ap.status = 'Waiting' THEN 1 ELSE 0 END) AS waiting_patients, "
                + "SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) AS booked_patients "
                + "FROM Doctor_Schedule ds WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "INNER JOIN Account acc ON acc.account_id = d.account_id "
                + "LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id "
                + "WHERE ds.work_date = ? AND ds.time_slot = ? AND ds.status = 'Available' "
                + "AND acc.role = 'Doctor' AND acc.status = 'Active' "
                + "GROUP BY ds.schedule_id, ds.doctor_id, ds.work_date, ds.time_slot, "
                + "ds.max_patients, d.full_name, d.department "
                + "HAVING SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) < ds.max_patients "
                + "ORDER BY waiting_patients ASC, booked_patients ASC, ds.doctor_id ASC";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(workDate));
            statement.setString(2, timeSlot);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new AppointmentBookingException(
                            "Không còn bác sĩ khả dụng trong ca khám đã chọn.");
                }

                ScheduleSelection schedule = new ScheduleSelection();
                schedule.scheduleId = resultSet.getInt("schedule_id");
                schedule.doctorId = resultSet.getInt("doctor_id");
                schedule.workDate = resultSet.getDate("work_date").toLocalDate();
                schedule.timeSlot = resultSet.getString("time_slot");
                schedule.maxPatients = resultSet.getInt("max_patients");
                schedule.doctorName = resultSet.getString("full_name");
                schedule.department = resultSet.getString("department");
                return schedule;
            }
        }
    }

    private LocalDateTime toAppointmentTime(LocalDate workDate, String timeSlot)
            throws AppointmentBookingException {
        if (timeSlot == null || timeSlot.length() < 5) {
            throw new AppointmentBookingException("Khung giờ của ca khám không hợp lệ.");
        }
        try {
            LocalTime startTime = LocalTime.parse(timeSlot.substring(0, 5));
            return LocalDateTime.of(workDate, startTime);
        } catch (DateTimeParseException e) {
            throw new AppointmentBookingException("Khung giờ của ca khám không hợp lệ.");
        }
    }

    private int countBookedPatients(Connection connection, int scheduleId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Appointment WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE schedule_id = ? AND status <> 'Cancelled'";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet resultSet = statement.executeQuery()) {
                resultSet.next();
                return resultSet.getInt(1);
            }
        }
    }

    private void validatePatientBookingRules(Connection connection, int patientId,
            ScheduleSelection schedule, LocalDateTime appointmentTime)
            throws SQLException, AppointmentBookingException {
        String departmentSql = "SELECT 1 FROM Appointment a WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor_Schedule existing_schedule "
                + "ON existing_schedule.schedule_id = a.schedule_id "
                + "INNER JOIN Doctor existing_doctor "
                + "ON existing_doctor.doctor_id = existing_schedule.doctor_id "
                + "WHERE a.patient_id = ? "
                + "AND a.status IN ('Waiting', 'Checked_In', 'In_Progress') "
                + "AND existing_schedule.work_date = ? "
                + "AND ((existing_doctor.department = ?) "
                + "OR (existing_doctor.department IS NULL AND ? IS NULL))";
        try (PreparedStatement statement = connection.prepareStatement(departmentSql)) {
            statement.setInt(1, patientId);
            statement.setDate(2, java.sql.Date.valueOf(schedule.workDate));
            statement.setString(3, schedule.department);
            statement.setString(4, schedule.department);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    throw new AppointmentBookingException(
                            "Bạn đã có lịch hẹn chưa hoàn tất ở chuyên khoa này trong ngày đã chọn.");
                }
            }
        }

        String timeSlotSql = "SELECT 1 FROM Appointment WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE patient_id = ? "
                + "AND status IN ('Waiting', 'Checked_In', 'In_Progress') "
                + "AND appointment_time = ?";
        try (PreparedStatement statement = connection.prepareStatement(timeSlotSql)) {
            statement.setInt(1, patientId);
            statement.setTimestamp(2, Timestamp.valueOf(appointmentTime));
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    throw new AppointmentBookingException(
                            "Bạn đã có một lịch hẹn khác trùng ca khám này.");
                }
            }
        }
    }

    private int nextQueueNumber(Connection connection, int scheduleId) throws SQLException {
        String sql = "SELECT COALESCE(MAX(queue_number), 0) + 1 "
                + "FROM Appointment WITH (UPDLOCK, HOLDLOCK) WHERE schedule_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            try (ResultSet resultSet = statement.executeQuery()) {
                resultSet.next();
                return resultSet.getInt(1);
            }
        }
    }

    private int insertAppointment(Connection connection, int patientId, int scheduleId,
            LocalDateTime appointmentTime, int queueNumber) throws SQLException {
        boolean hasConversationId = hasColumn(connection, "Appointment", "conversation_id");
        String sql = hasConversationId
                ? "INSERT INTO Appointment (patient_id, schedule_id, conversation_id, "
                + "appointment_time, booking_type, queue_number, status, created_at) "
                + "VALUES (?, ?, NULL, ?, 'Online', ?, 'Waiting', GETDATE())"
                : "INSERT INTO Appointment (patient_id, schedule_id, "
                + "appointment_time, booking_type, queue_number, status, created_at) "
                + "VALUES (?, ?, ?, 'Online', ?, 'Waiting', GETDATE())";
        try (PreparedStatement statement = connection.prepareStatement(sql,
                Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, patientId);
            statement.setInt(2, scheduleId);
            statement.setTimestamp(3, Timestamp.valueOf(appointmentTime));
            statement.setInt(4, queueNumber);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("Unable to retrieve generated appointment ID");
    }

    private boolean hasColumn(Connection connection, String tableName, String columnName)
            throws SQLException {
        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS "
                + "WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, tableName);
            statement.setString(2, columnName);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private void markScheduleFull(Connection connection, int scheduleId) throws SQLException {
        String sql = "UPDATE Doctor_Schedule SET status = 'Full' WHERE schedule_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            statement.executeUpdate();
        }
    }

    private AppointmentBookingResult createResult(int appointmentId, int scheduleId, int queueNumber,
            LocalDateTime appointmentTime, ScheduleSelection schedule) {
        AppointmentBookingResult result = new AppointmentBookingResult();
        result.setAppointmentId(appointmentId);
        result.setScheduleId(scheduleId);
        result.setQueueNumber(queueNumber);
        result.setAppointmentTime(appointmentTime);
        result.setStatus("Waiting");
        result.setDoctorName(schedule.doctorName);
        result.setDepartment(schedule.department);
        result.setTimeSlot(schedule.timeSlot);
        return result;
    }

    private void rollback(Connection connection) {
        if (connection == null) {
            return;
        }
        try {
            connection.rollback();
        } catch (SQLException rollbackError) {
            rollbackError.printStackTrace();
        }
    }

    private void close(Connection connection) {
        if (connection == null) {
            return;
        }
        try {
            connection.close();
        } catch (SQLException closeError) {
            closeError.printStackTrace();
        }
    }

    private static class ScheduleSelection {
        private int scheduleId;
        private int doctorId;
        private LocalDate workDate;
        private String timeSlot;
        private int maxPatients;
        private String doctorName;
        private String department;
    }
}
