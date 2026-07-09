package com.diabetes.monitoring.doctor.dao;

import com.diabetes.monitoring.doctor.model.Appointment;
import com.diabetes.monitoring.doctor.model.DoctorSchedule;
import com.diabetes.monitoring.doctor.model.Patient;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class AppointmentDAO {

    public List<DoctorSchedule> getAvailableSchedules(Date fromDate, Date toDate) {
        List<DoctorSchedule> schedules = new ArrayList<>();
        String sql = "SELECT ds.schedule_id, ds.doctor_id, d.full_name AS doctor_name, "
                + "ds.work_date, ds.time_slot, ds.max_patients, ds.status, "
                + "COUNT(CASE WHEN a.status <> 'Cancelled' THEN 1 END) AS booked_patients "
                + "FROM Doctor_Schedule ds "
                + "JOIN Doctor d ON ds.doctor_id = d.doctor_id "
                + "LEFT JOIN Appointment a ON ds.schedule_id = a.schedule_id "
                + "WHERE ds.work_date BETWEEN ? AND ? AND ds.status = 'Available' "
                + "GROUP BY ds.schedule_id, ds.doctor_id, d.full_name, ds.work_date, "
                + "ds.time_slot, ds.max_patients, ds.status "
                + "HAVING COUNT(CASE WHEN a.status <> 'Cancelled' THEN 1 END) < ds.max_patients "
                + "ORDER BY ds.work_date, ds.time_slot, d.full_name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, fromDate);
            ps.setDate(2, toDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DoctorSchedule schedule = new DoctorSchedule();
                    schedule.setScheduleId(rs.getInt("schedule_id"));
                    schedule.setDoctorId(rs.getInt("doctor_id"));
                    schedule.setDoctorName(rs.getString("doctor_name"));
                    schedule.setWorkDate(rs.getDate("work_date"));
                    schedule.setTimeSlot(rs.getString("time_slot"));
                    schedule.setMaxPatients(rs.getInt("max_patients"));
                    schedule.setStatus(rs.getString("status"));
                    schedule.setBookedPatients(rs.getInt("booked_patients"));
                    schedules.add(schedule);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return schedules;
    }

    public int createSchedule(DoctorSchedule schedule) throws SQLException {
        String sql = "INSERT INTO Doctor_Schedule "
                + "(doctor_id, work_date, time_slot, max_patients, status) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, schedule.getDoctorId());
            ps.setDate(2, schedule.getWorkDate());
            ps.setString(3, schedule.getTimeSlot());
            ps.setInt(4, schedule.getMaxPatients());
            ps.setString(5, schedule.getStatus() == null ? "Available" : schedule.getStatus());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("Khong the tao lich truc");
    }

    public int bookAppointment(
            int patientId,
            int scheduleId,
            Integer conversationId,
            Timestamp appointmentTime,
            String bookingType) throws SQLException {

        String lockScheduleSql = "SELECT doctor_id, work_date, max_patients, status "
                + "FROM Doctor_Schedule WITH (UPDLOCK, HOLDLOCK) WHERE schedule_id = ?";
        String queueSql = "SELECT COUNT(*) AS booked_count, "
                + "ISNULL(MAX(queue_number), 0) + 1 AS next_queue "
                + "FROM Appointment WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE schedule_id = ? AND status <> 'Cancelled'";
        String insertSql = "INSERT INTO Appointment "
                + "(patient_id, doctor_id, schedule_id, conversation_id, appointment_time, "
                + "booking_type, queue_number, status, created_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, 'Waiting', GETDATE())";
        String fullSql = "UPDATE Doctor_Schedule SET status = 'Full' WHERE schedule_id = ?";
        String duplicateSql = "SELECT COUNT(*) FROM Appointment "
                + "WHERE patient_id = ? AND schedule_id = ? AND status <> 'Cancelled'";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int doctorId;
                int maxPatients;
                String scheduleStatus;
                Date workDate;

                try (PreparedStatement ps = conn.prepareStatement(lockScheduleSql)) {
                    ps.setInt(1, scheduleId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong tim thay lich truc");
                        }
                        doctorId = rs.getInt("doctor_id");
                        workDate = rs.getDate("work_date");
                        maxPatients = rs.getInt("max_patients");
                        scheduleStatus = rs.getString("status");
                    }
                }

                if (!"Available".equals(scheduleStatus)) {
                    throw new SQLException("Khung gio khong con kha dung");
                }
                if (!appointmentTime.toLocalDateTime().toLocalDate()
                        .equals(workDate.toLocalDate())) {
                    throw new SQLException("Thoi gian hen khong dung ngay truc da chon");
                }

                try (PreparedStatement ps = conn.prepareStatement(duplicateSql)) {
                    ps.setInt(1, patientId);
                    ps.setInt(2, scheduleId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            throw new SQLException("Benh nhan da co lich trong khung gio nay");
                        }
                    }
                }

                int bookedCount;
                int queueNumber;
                try (PreparedStatement ps = conn.prepareStatement(queueSql)) {
                    ps.setInt(1, scheduleId);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        bookedCount = rs.getInt("booked_count");
                        queueNumber = rs.getInt("next_queue");
                    }
                }

                if (bookedCount >= maxPatients) {
                    throw new SQLException("Khung gio da du so luong benh nhan");
                }

                int appointmentId;
                try (PreparedStatement ps = conn.prepareStatement(
                        insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, patientId);
                    ps.setInt(2, doctorId);
                    ps.setInt(3, scheduleId);
                    if (conversationId == null) {
                        ps.setNull(4, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(4, conversationId);
                    }
                    ps.setTimestamp(5, appointmentTime);
                    ps.setString(6, bookingType);
                    ps.setInt(7, queueNumber);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong lay duoc appointment_id");
                        }
                        appointmentId = rs.getInt(1);
                    }
                }

                if (bookedCount + 1 >= maxPatients) {
                    try (PreparedStatement ps = conn.prepareStatement(fullSql)) {
                        ps.setInt(1, scheduleId);
                        ps.executeUpdate();
                    }
                }

                conn.commit();
                return appointmentId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public List<Appointment> getAppointmentsByDoctor(int doctorId, Date workDate) {
        List<Appointment> appointments = new ArrayList<>();
        String sql = "SELECT a.*, p.full_name AS patient_name, d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "JOIN Doctor d ON a.doctor_id = d.doctor_id "
                + "WHERE a.doctor_id = ? AND CAST(a.appointment_time AS DATE) = ? "
                + "ORDER BY a.queue_number";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ps.setDate(2, workDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    appointments.add(mapAppointment(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return appointments;
    }

    public List<Appointment> getWaitingAppointmentsByDoctor(int doctorId) {
        List<Appointment> appointments = new ArrayList<>();
        String sql = "SELECT a.*, p.full_name AS patient_name, "
                + "d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "JOIN Patient p ON p.patient_id = a.patient_id "
                + "JOIN Doctor d ON d.doctor_id = a.doctor_id "
                + "WHERE a.doctor_id = ? AND a.status = 'Waiting' "
                + "ORDER BY a.appointment_time ASC, a.queue_number ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    appointments.add(mapAppointment(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return appointments;
    }

    public List<Appointment> getAppointmentsByPatient(int patientId) {
        List<Appointment> appointments = new ArrayList<>();
        String sql = "SELECT a.*, p.full_name AS patient_name, d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "JOIN Doctor d ON a.doctor_id = d.doctor_id "
                + "WHERE a.patient_id = ? "
                + "ORDER BY a.appointment_time DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    appointments.add(mapAppointment(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return appointments;
    }

    public List<Appointment> getAppointmentsByDate(Date workDate) {
        List<Appointment> appointments = new ArrayList<>();
        String sql = "SELECT a.*, p.full_name AS patient_name, d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "JOIN Patient p ON a.patient_id = p.patient_id "
                + "JOIN Doctor d ON a.doctor_id = d.doctor_id "
                + "WHERE CAST(a.appointment_time AS DATE) = ? "
                + "ORDER BY d.full_name, a.queue_number";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, workDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    appointments.add(mapAppointment(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return appointments;
    }

    public Patient findPatientByPhone(String phone) {
        String sql = "SELECT patient_id, full_name, gender, phone, email, address "
                + "FROM Patient WHERE phone = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Patient patient = new Patient();
                    patient.setPatientId(rs.getInt("patient_id"));
                    patient.setFullName(rs.getString("full_name"));
                    patient.setGender(rs.getString("gender"));
                    patient.setPhone(rs.getString("phone"));
                    patient.setEmail(rs.getString("email"));
                    patient.setAddress(rs.getString("address"));
                    return patient;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateAppointmentStatus(int appointmentId, int doctorId, String status) {
        String sql = "UPDATE Appointment SET status = ? "
                + "WHERE appointment_id = ? AND doctor_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, appointmentId);
            ps.setInt(3, doctorId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private Appointment mapAppointment(ResultSet rs) throws SQLException {
        Appointment appointment = new Appointment();
        appointment.setAppointmentId(rs.getInt("appointment_id"));
        appointment.setPatientId(rs.getInt("patient_id"));
        appointment.setPatientName(rs.getString("patient_name"));
        appointment.setDoctorId(rs.getInt("doctor_id"));
        appointment.setDoctorName(rs.getString("doctor_name"));
        appointment.setScheduleId(rs.getInt("schedule_id"));
        int conversationId = rs.getInt("conversation_id");
        appointment.setConversationId(rs.wasNull() ? null : conversationId);
        appointment.setAppointmentTime(rs.getTimestamp("appointment_time"));
        appointment.setBookingType(rs.getString("booking_type"));
        appointment.setQueueNumber(rs.getInt("queue_number"));
        appointment.setStatus(rs.getString("status"));
        appointment.setCreatedAt(rs.getTimestamp("created_at"));
        return appointment;
    }
}
