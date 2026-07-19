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
                throw new AppointmentBookingException("Ca kh\u00E1m \u0111\u00E3 b\u1EAFt \u0111\u1EA7u ho\u1EB7c \u0111\u00E3 k\u1EBFt th\u00FAC.");
            }

            int bookedPatients = countBookedPatients(connection, scheduleId);
            if (bookedPatients >= schedule.maxPatients) {
                markScheduleFull(connection, scheduleId);
                throw new AppointmentBookingException("Ca kh\u00E1m \u0111\u00E3 \u0111\u1EE7 s\u1ED1 l\u01B0\u1EE3ng b\u1EC7nh nh\u00E2n.");
            }

            if (hasDuplicateAppointment(connection, patientId, scheduleId, appointmentTime)) {
                throw new AppointmentBookingException("B\u1EA1n \u0111\u00E3 c\u00F3 l\u1ECBch h\u1EB9n trong ca kh\u00E1m n\u00E0y.");
            }

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
            throw new AppointmentBookingException("D\u1EEF li\u1EC7u ca kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7.");
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
                throw new AppointmentBookingException("Ca kh\u00E1m \u0111\u00E3 b\u1EAFt \u0111\u1EA7u ho\u1EB7c \u0111\u00E3 k\u1EBFt th\u00FAC.");
            }

            int bookedPatients = countBookedPatients(connection, schedule.scheduleId);
            if (bookedPatients >= schedule.maxPatients) {
                throw new AppointmentBookingException("Ca kh\u00E1m \u0111\u00E3 \u0111\u1EE7 s\u1ED1 l\u01B0\u1EE3ng b\u1EC7nh nh\u00E2n.");
            }

            if (hasDuplicateAppointment(connection, patientId, schedule.scheduleId, appointmentTime)) {
                throw new AppointmentBookingException("B\u1EA1n \u0111\u00E3 c\u00F3 l\u1ECBch h\u1EB9n trong ca kh\u00E1m n\u00E0y.");
            }

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
            throw new AppointmentBookingException("D\u1EEF li\u1EC7u ca kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7.");
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
        throw new AppointmentBookingException("Kh\u00F4ng t\u00ECm th\u1EA5y h\u1ED3 s\u01A1 b\u1EC7nh nh\u00E2n.");
    }

    private ScheduleSelection lockSchedule(Connection connection, int doctorId, int scheduleId)
            throws SQLException, AppointmentBookingException {
        String sql = "SELECT ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                + "d.full_name, d.department, ds.room_id, r.room_name, r.location AS room_location "
                + "FROM Doctor_Schedule ds WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                + "INNER JOIN Account a ON a.account_id = d.account_id "
                + "WHERE ds.schedule_id = ? AND ds.doctor_id = ? "
                + "AND a.role = 'Doctor' AND a.status = 'Active'";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            statement.setInt(2, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new AppointmentBookingException("Kh\u00F4ng t\u00ECm th\u1EA5y ca kh\u00E1m c\u1EE7a b\u00E1c s\u0129 \u0111\u00E3 ch\u1ECDn.");
                }

                String status = resultSet.getString("status");
                if (!"Available".equals(status)) {
                    throw new AppointmentBookingException("Ca kh\u00E1m hi\u1EC7n kh\u00F4ng c\u00F2n kh\u1EA3 d\u1EE5ng.");
                }

                ScheduleSelection schedule = new ScheduleSelection();
                schedule.workDate = resultSet.getDate("work_date").toLocalDate();
                schedule.timeSlot = resultSet.getString("time_slot");
                schedule.maxPatients = resultSet.getInt("max_patients");
                schedule.doctorName = resultSet.getString("full_name");
                schedule.department = resultSet.getString("department");
                int roomId = resultSet.getInt("room_id");
                schedule.roomId = resultSet.wasNull() ? null : roomId;
                schedule.roomName = resultSet.getString("room_name");
                schedule.roomLocation = resultSet.getString("room_location");
                return schedule;
            }
        }
    }

    private ScheduleSelection lockBestAvailableSchedule(Connection connection, LocalDate workDate,
            String timeSlot) throws SQLException, AppointmentBookingException {
        String sql = "SELECT TOP 1 ds.schedule_id, ds.doctor_id, ds.work_date, ds.time_slot, "
                + "ds.max_patients, d.full_name, d.department, ds.room_id, r.room_name, r.location AS room_location, "
                + "SUM(CASE WHEN ap.status = 'Waiting' THEN 1 ELSE 0 END) AS waiting_patients, "
                + "SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) AS booked_patients "
                + "FROM Doctor_Schedule ds WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "INNER JOIN Account acc ON acc.account_id = d.account_id "
                + "LEFT JOIN Room r ON r.room_id = ds.room_id "
                + "LEFT JOIN Appointment ap ON ap.schedule_id = ds.schedule_id "
                + "WHERE ds.work_date = ? AND ds.time_slot = ? AND ds.status = 'Available' "
                + "AND acc.role = 'Doctor' AND acc.status = 'Active' "
                + "GROUP BY ds.schedule_id, ds.doctor_id, ds.work_date, ds.time_slot, "
                + "ds.max_patients, d.full_name, d.department, ds.room_id, r.room_name, r.location "
                + "HAVING SUM(CASE WHEN ap.status <> 'Cancelled' THEN 1 ELSE 0 END) < ds.max_patients "
                + "ORDER BY waiting_patients ASC, booked_patients ASC, ds.doctor_id ASC";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(workDate));
            statement.setString(2, timeSlot);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new AppointmentBookingException(
                            "Kh\u00F4ng c\u00F2n b\u00E1c s\u0129 kh\u1EA3 d\u1EE5ng trong ca kh\u00E1m \u0111\u00E3 ch\u1ECDn.");
                }

                ScheduleSelection schedule = new ScheduleSelection();
                schedule.scheduleId = resultSet.getInt("schedule_id");
                schedule.doctorId = resultSet.getInt("doctor_id");
                schedule.workDate = resultSet.getDate("work_date").toLocalDate();
                schedule.timeSlot = resultSet.getString("time_slot");
                schedule.maxPatients = resultSet.getInt("max_patients");
                schedule.doctorName = resultSet.getString("full_name");
                schedule.department = resultSet.getString("department");
                int roomId = resultSet.getInt("room_id");
                schedule.roomId = resultSet.wasNull() ? null : roomId;
                schedule.roomName = resultSet.getString("room_name");
                schedule.roomLocation = resultSet.getString("room_location");
                return schedule;
            }
        }
    }

    private LocalDateTime toAppointmentTime(LocalDate workDate, String timeSlot)
            throws AppointmentBookingException {
        if (timeSlot == null || timeSlot.length() < 5) {
            throw new AppointmentBookingException("Khung gi\u1EDD c\u1EE7a ca kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7.");
        }
        try {
            LocalTime startTime = LocalTime.parse(timeSlot.substring(0, 5));
            return LocalDateTime.of(workDate, startTime);
        } catch (DateTimeParseException e) {
            throw new AppointmentBookingException("Khung gi\u1EDD c\u1EE7a ca kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7.");
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

    private boolean hasDuplicateAppointment(Connection connection, int patientId, int scheduleId,
            LocalDateTime appointmentTime) throws SQLException {
        String sql = "SELECT 1 FROM Appointment a WITH (UPDLOCK, HOLDLOCK) "
                + "INNER JOIN Doctor_Schedule existing_schedule "
                + "ON existing_schedule.schedule_id = a.schedule_id "
                + "INNER JOIN Doctor existing_doctor "
                + "ON existing_doctor.doctor_id = existing_schedule.doctor_id "
                + "INNER JOIN Doctor_Schedule target_schedule "
                + "ON target_schedule.schedule_id = ? "
                + "INNER JOIN Doctor target_doctor "
                + "ON target_doctor.doctor_id = target_schedule.doctor_id "
                + "WHERE a.patient_id = ? "
                + "AND a.status IN ('Waiting', 'Checked_In', 'In_Progress') "
                + "AND ((existing_schedule.work_date = target_schedule.work_date "
                + "AND ((existing_doctor.department = target_doctor.department) "
                + "OR (existing_doctor.department IS NULL AND target_doctor.department IS NULL))) "
                + "OR a.appointment_time = ?)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            statement.setInt(2, patientId);
            statement.setTimestamp(3, Timestamp.valueOf(appointmentTime));
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
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
        result.setRoomId(schedule.roomId);
        result.setRoomName(schedule.roomName);
        result.setRoomLocation(schedule.roomLocation);
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
        private Integer roomId;
        private String roomName;
        private String roomLocation;
    }
}
