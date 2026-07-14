package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.AppointmentInfo;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class PatientAppointmentDAO {
    private static final String BASE_SELECT =
            "SELECT a.appointment_id, ds.doctor_id AS doctor_id, a.schedule_id, CAST(NULL AS int) AS conversation_id, "
            + "a.appointment_time, a.booking_type, a.queue_number, a.status, a.created_at, "
            + "d.full_name AS doctor_name, d.department, d.phone AS doctor_phone, "
            + "d.email AS doctor_email, ds.time_slot, ds.room_id, r.room_name, r.location AS room_location "
            + "FROM Appointment a "
            + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
            + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
            + "INNER JOIN Doctor d ON d.doctor_id = ds.doctor_id "
            + "LEFT JOIN Room r ON r.room_id = ds.room_id ";

    public List<AppointmentInfo> findByPatientAccountId(int accountId) throws SQLException {
        return findByPatientAccountId(accountId, null);
    }

    public List<AppointmentInfo> findByPatientAccountId(int accountId, LocalDate searchDate)
            throws SQLException {
        String sql = BASE_SELECT
                + "WHERE p.account_id = ? "
                + (searchDate == null ? "" : "AND CAST(a.appointment_time AS date) = ? ")
                + "ORDER BY a.appointment_time DESC, a.appointment_id DESC";
        List<AppointmentInfo> appointments = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            markExpiredWaitingAppointments(connection, accountId);
            statement.setInt(1, accountId);
            if (searchDate != null) {
                statement.setDate(2, java.sql.Date.valueOf(searchDate));
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    appointments.add(mapAppointment(resultSet));
                }
            }
        }
        return appointments;
    }

    public AppointmentInfo findByIdAndPatientAccountId(int appointmentId, int accountId)
            throws SQLException {
        String sql = BASE_SELECT
                + "WHERE a.appointment_id = ? AND p.account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            markExpiredWaitingAppointments(connection, accountId);
            statement.setInt(1, appointmentId);
            statement.setInt(2, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapAppointment(resultSet) : null;
            }
        }
    }

    private void markExpiredWaitingAppointments(Connection connection, int accountId)
            throws SQLException {
        String sql = "UPDATE a SET status = 'Absent' "
                + "FROM Appointment a "
                + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE p.account_id = ? "
                + "AND a.status = 'Waiting' "
                + "AND DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS time), "
                + "TRY_CONVERT(time, RIGHT(REPLACE(ds.time_slot, ' ', ''), 5))), "
                + "CAST(CAST(a.appointment_time AS date) AS datetime)) < GETDATE()";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.executeUpdate();
        }
    }

    private AppointmentInfo mapAppointment(ResultSet resultSet) throws SQLException {
        AppointmentInfo appointment = new AppointmentInfo();
        appointment.setAppointmentId(resultSet.getInt("appointment_id"));
        appointment.setDoctorId(resultSet.getInt("doctor_id"));
        appointment.setScheduleId(resultSet.getInt("schedule_id"));
        int conversationId = resultSet.getInt("conversation_id");
        appointment.setConversationId(resultSet.wasNull() ? null : conversationId);
        appointment.setAppointmentTime(toLocalDateTime(resultSet.getTimestamp("appointment_time")));
        appointment.setBookingType(resultSet.getString("booking_type"));
        appointment.setQueueNumber(resultSet.getInt("queue_number"));
        appointment.setStatus(resultSet.getString("status"));
        appointment.setCreatedAt(toLocalDateTime(resultSet.getTimestamp("created_at")));
        appointment.setDoctorName(resultSet.getString("doctor_name"));
        appointment.setDepartment(resultSet.getString("department"));
        appointment.setDoctorPhone(resultSet.getString("doctor_phone"));
        appointment.setDoctorEmail(resultSet.getString("doctor_email"));
        appointment.setTimeSlot(resultSet.getString("time_slot"));
        int roomId = resultSet.getInt("room_id");
        appointment.setRoomId(resultSet.wasNull() ? null : roomId);
        appointment.setRoomName(resultSet.getString("room_name"));
        appointment.setRoomLocation(resultSet.getString("room_location"));
        return appointment;
    }

    private java.time.LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toLocalDateTime();
    }
}
