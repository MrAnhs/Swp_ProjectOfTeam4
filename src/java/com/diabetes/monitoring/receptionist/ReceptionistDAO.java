package com.diabetes.monitoring.receptionist;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReceptionistDAO {

    public Connection openConnection() throws SQLException {
        return DatabaseConnection.getConnection();
    }

    public Map<String, Object> findPatientByPhone(String phone) throws SQLException {
        try (Connection connection = openConnection()) {
            Map<String, Object> patient = null;
            String patientSql = "SELECT patient_id, full_name, phone, email, address, date_of_birth, gender "
                    + "FROM Patient WHERE phone = ?";
            try (PreparedStatement statement = connection.prepareStatement(patientSql)) {
                statement.setString(1, phone);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        patient = mapPatient(resultSet);
                    }
                }
            }

            if (patient == null) {
                return null;
            }

            int patientId = (Integer) patient.get("patientId");
            Map<String, Object> result = new HashMap<>();
            result.put("patient", patient);
            result.put("historyCount", countAppointments(connection, patientId));
            result.put("nextAppointment", findLatestAppointment(connection, patientId));
            return result;
        }
    }

    public List<Map<String, Object>> findActiveDoctors() throws SQLException {
        String sql = "SELECT d.doctor_id, d.full_name, d.department "
                + "FROM Doctor d INNER JOIN Account a ON a.account_id = d.account_id "
                + "WHERE a.role = 'Doctor' AND a.status = 'Active' "
                + "ORDER BY d.full_name";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<Map<String, Object>> doctors = new ArrayList<>();
            while (resultSet.next()) {
                Map<String, Object> doctor = new HashMap<>();
                doctor.put("doctorId", resultSet.getInt("doctor_id"));
                doctor.put("fullName", resultSet.getString("full_name"));
                doctor.put("department", resultSet.getString("department"));
                doctors.add(doctor);
            }
            return doctors;
        }
    }

    public List<Map<String, Object>> findAvailableSchedules(int doctorId) throws SQLException {
        String sql = "SELECT ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients, "
                + "COUNT(a.appointment_id) AS booked "
                + "FROM Doctor_Schedule ds "
                + "LEFT JOIN Appointment a ON a.schedule_id = ds.schedule_id AND a.status <> 'Cancelled' "
                + "WHERE ds.doctor_id = ? AND ds.work_date >= CAST(GETDATE() AS date) "
                + "AND ds.status = 'Available' "
                + "GROUP BY ds.schedule_id, ds.work_date, ds.time_slot, ds.max_patients "
                + "HAVING COUNT(a.appointment_id) < ds.max_patients "
                + "ORDER BY ds.work_date, ds.time_slot";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> schedules = new ArrayList<>();
                while (resultSet.next()) {
                    int maxPatients = resultSet.getInt("max_patients");
                    int booked = resultSet.getInt("booked");
                    Date workDate = resultSet.getDate("work_date");
                    String timeSlot = resultSet.getString("time_slot");
                    Map<String, Object> schedule = new HashMap<>();
                    schedule.put("scheduleId", resultSet.getInt("schedule_id"));
                    schedule.put("workDate", workDate == null ? "" : workDate.toString());
                    schedule.put("timeSlot", timeSlot);
                    schedule.put("label", formatScheduleLabel(workDate, timeSlot));
                    schedule.put("available", Math.max(0, maxPatients - booked));
                    schedules.add(schedule);
                }
                return schedules;
            }
        }
    }

    public Map<String, Object> registerAppointment(ReceptionistRegistrationRequest request)
            throws SQLException, ReceptionistException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);

            Integer patientId = findPatientIdByPhone(connection, request.phone);
            if (patientId == null) {
                patientId = insertPatient(connection, request);
            } else {
                updatePatient(connection, patientId, request);
            }

            Map<String, Object> schedule = lockSchedule(connection, request.doctorId, request.scheduleId);
            if (schedule == null) {
                throw new ReceptionistException("Ca khám không hợp lệ hoặc đã hết chỗ.");
            }

            LocalDate workDate = ((Date) schedule.get("workDate")).toLocalDate();
            String timeSlot = (String) schedule.get("timeSlot");
            LocalDateTime appointmentTime = LocalDateTime.of(workDate, parseStartTime(timeSlot));
            if (!appointmentTime.isAfter(LocalDateTime.now())) {
                throw new ReceptionistException("Ca khám đã bắt đầu hoặc đã kết thúc.");
            }

            int booked = (Integer) schedule.get("booked");
            int maxPatients = (Integer) schedule.get("maxPatients");
            int queueNumber = nextQueueNumber(connection, request.scheduleId);
            int appointmentId = insertAppointment(connection, patientId, request.doctorId,
                    request.scheduleId, appointmentTime, queueNumber);

            if (booked + 1 >= maxPatients) {
                markScheduleFull(connection, request.scheduleId);
            }

            connection.commit();
            Map<String, Object> result = new HashMap<>();
            result.put("appointmentId", appointmentId);
            result.put("patientId", patientId);
            result.put("queueNumber", queueNumber);
            result.put("appointmentTime", appointmentTime.toString().replace('T', ' '));
            return result;
        } catch (SQLException | ReceptionistException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }

    public Map<String, Object> getInvoiceStats() throws SQLException {
        String sql = "SELECT SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN status = 'Paid' THEN 1 ELSE 0 END) AS paid_count FROM Invoice";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            Map<String, Object> stats = new HashMap<>();
            if (resultSet.next()) {
                stats.put("pendingCount", resultSet.getInt("pending_count"));
                stats.put("paidCount", resultSet.getInt("paid_count"));
            } else {
                stats.put("pendingCount", 0);
                stats.put("paidCount", 0);
            }
            return stats;
        }
    }

    public List<Map<String, Object>> findInvoicesByStatus(String status) throws SQLException {
        String sql = "SELECT TOP 20 i.invoice_id, i.patient_id, p.full_name, p.phone, "
                + "i.final_amount, i.status, i.created_at "
                + "FROM Invoice i LEFT JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.status = ? ORDER BY i.created_at DESC, i.invoice_id DESC";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, status);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> invoices = new ArrayList<>();
                while (resultSet.next()) {
                    Map<String, Object> invoice = new HashMap<>();
                    invoice.put("invoiceId", resultSet.getInt("invoice_id"));
                    invoice.put("patientId", resultSet.getInt("patient_id"));
                    invoice.put("patientName", resultSet.getString("full_name"));
                    invoice.put("phone", resultSet.getString("phone"));
                    invoice.put("finalAmount", resultSet.getBigDecimal("final_amount"));
                    invoice.put("status", resultSet.getString("status"));
                    invoice.put("createdAt", toDisplayDateTime(resultSet.getTimestamp("created_at")));
                    invoices.add(invoice);
                }
                return invoices;
            }
        }
    }

    public int payPendingInvoice(String patientKeyword, String paymentMethod, int receptionistAccountId)
            throws SQLException, ReceptionistException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setAutoCommit(false);

            Integer invoiceId = findPendingInvoiceId(connection, patientKeyword);
            if (invoiceId == null) {
                throw new ReceptionistException("Không tìm thấy hóa đơn chờ thanh toán phù hợp.");
            }

            String sql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                    + "receptionist_id = ?, exported_at = GETDATE() WHERE invoice_id = ? AND status = 'Pending'";
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setString(1, paymentMethod);
                statement.setInt(2, receptionistAccountId);
                statement.setInt(3, invoiceId);
                if (statement.executeUpdate() == 0) {
                    throw new ReceptionistException("Hóa đơn đã được xử lý trước đó.");
                }
            }
            connection.commit();
            return invoiceId;
        } catch (SQLException | ReceptionistException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }

    public List<Map<String, Object>> findTodayQueue(String status) throws SQLException {
        String sql = "SELECT a.appointment_id, a.queue_number, a.appointment_time, a.status, "
                + "p.full_name AS patient_name, p.phone, d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = a.doctor_id "
                + "WHERE CAST(a.appointment_time AS date) = CAST(GETDATE() AS date) "
                + (status == null || status.isBlank() ? "" : "AND a.status = ? ")
                + "ORDER BY a.appointment_time, a.queue_number";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            markLateWaitingAppointmentsAsAbsent(connection);
            if (status != null && !status.isBlank()) {
                statement.setString(1, status);
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> items = new ArrayList<>();
                while (resultSet.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("appointmentId", resultSet.getInt("appointment_id"));
                    item.put("queueNumber", resultSet.getInt("queue_number"));
                    item.put("appointmentTime", toDisplayDateTime(resultSet.getTimestamp("appointment_time")));
                    item.put("status", resultSet.getString("status"));
                    item.put("patientName", resultSet.getString("patient_name"));
                    item.put("phone", resultSet.getString("phone"));
                    item.put("doctorName", resultSet.getString("doctor_name"));
                    items.add(item);
                }
                return items;
            }
        }
    }

    public boolean checkInAppointment(int appointmentId) throws SQLException {
        String sql = "UPDATE Appointment SET status = 'Checked_In' "
                + "WHERE appointment_id = ? AND status = 'Waiting' "
                + "AND CAST(appointment_time AS date) = CAST(GETDATE() AS date)";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            return statement.executeUpdate() > 0;
        }
    }

    private Map<String, Object> mapPatient(ResultSet resultSet) throws SQLException {
        Map<String, Object> patient = new HashMap<>();
        patient.put("patientId", resultSet.getInt("patient_id"));
        patient.put("fullName", resultSet.getString("full_name"));
        patient.put("phone", resultSet.getString("phone"));
        patient.put("email", resultSet.getString("email"));
        patient.put("address", resultSet.getString("address"));
        Date dob = resultSet.getDate("date_of_birth");
        patient.put("dateOfBirth", dob == null ? "" : dob.toString());
        patient.put("gender", resultSet.getString("gender"));
        return patient;
    }

    private int countAppointments(Connection connection, int patientId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM Appointment WHERE patient_id = ?")) {
            statement.setInt(1, patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                resultSet.next();
                return resultSet.getInt(1);
            }
        }
    }

    private Map<String, Object> findLatestAppointment(Connection connection, int patientId)
            throws SQLException {
        String sql = "SELECT TOP 1 a.appointment_time, a.booking_type, a.status, "
                + "a.queue_number, d.full_name AS doctor_name "
                + "FROM Appointment a LEFT JOIN Doctor d ON a.doctor_id = d.doctor_id "
                + "WHERE a.patient_id = ? ORDER BY a.appointment_time DESC";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return null;
                }
                Map<String, Object> appointment = new HashMap<>();
                appointment.put("appointmentTime", toDisplayDateTime(resultSet.getTimestamp("appointment_time")));
                appointment.put("bookingType", resultSet.getString("booking_type"));
                appointment.put("status", resultSet.getString("status"));
                appointment.put("queueNumber", resultSet.getInt("queue_number"));
                appointment.put("doctorName", resultSet.getString("doctor_name"));
                return appointment;
            }
        }
    }

    private Integer findPatientIdByPhone(Connection connection, String phone) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT patient_id FROM Patient WHERE phone = ?")) {
            statement.setString(1, phone);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? resultSet.getInt("patient_id") : null;
            }
        }
    }

    private int insertPatient(Connection connection, ReceptionistRegistrationRequest request)
            throws SQLException {
        String sql = "INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id) "
                + "VALUES (?, ?, ?, ?, ?, ?, NULL)";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, request.patientName);
            statement.setDate(2, Date.valueOf(request.dateOfBirth));
            statement.setString(3, request.gender);
            statement.setString(4, request.phone);
            statement.setString(5, emptyToNull(request.email));
            statement.setString(6, request.address);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("Unable to create patient");
    }

    private void updatePatient(Connection connection, int patientId, ReceptionistRegistrationRequest request)
            throws SQLException {
        String sql = "UPDATE Patient SET full_name = ?, date_of_birth = ?, gender = ?, "
                + "email = ?, address = ? WHERE patient_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, request.patientName);
            statement.setDate(2, Date.valueOf(request.dateOfBirth));
            statement.setString(3, request.gender);
            statement.setString(4, emptyToNull(request.email));
            statement.setString(5, request.address);
            statement.setInt(6, patientId);
            statement.executeUpdate();
        }
    }

    private Map<String, Object> lockSchedule(Connection connection, int doctorId, int scheduleId)
            throws SQLException {
        String sql = "SELECT ds.work_date, ds.time_slot, ds.max_patients, "
                + "COUNT(a.appointment_id) AS booked "
                + "FROM Doctor_Schedule ds WITH (UPDLOCK, HOLDLOCK) "
                + "LEFT JOIN Appointment a ON a.schedule_id = ds.schedule_id AND a.status <> 'Cancelled' "
                + "WHERE ds.schedule_id = ? AND ds.doctor_id = ? AND ds.status = 'Available' "
                + "AND ds.work_date >= CAST(GETDATE() AS date) "
                + "GROUP BY ds.work_date, ds.time_slot, ds.max_patients "
                + "HAVING COUNT(a.appointment_id) < ds.max_patients";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, scheduleId);
            statement.setInt(2, doctorId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return null;
                }
                Map<String, Object> schedule = new HashMap<>();
                schedule.put("workDate", resultSet.getDate("work_date"));
                schedule.put("timeSlot", resultSet.getString("time_slot"));
                schedule.put("maxPatients", resultSet.getInt("max_patients"));
                schedule.put("booked", resultSet.getInt("booked"));
                return schedule;
            }
        }
    }

    private int nextQueueNumber(Connection connection, int scheduleId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COALESCE(MAX(queue_number), 0) + 1 FROM Appointment WITH (UPDLOCK, HOLDLOCK) WHERE schedule_id = ?")) {
            statement.setInt(1, scheduleId);
            try (ResultSet resultSet = statement.executeQuery()) {
                resultSet.next();
                return resultSet.getInt(1);
            }
        }
    }

    private int insertAppointment(Connection connection, int patientId, int doctorId, int scheduleId,
            LocalDateTime appointmentTime, int queueNumber) throws SQLException {
        boolean hasBookingSource = hasColumn(connection, "Appointment", "booking_source");
        String sql = hasBookingSource
                ? "INSERT INTO Appointment (patient_id, doctor_id, schedule_id, conversation_id, "
                + "appointment_time, booking_type, booking_source, queue_number, status, created_at) "
                + "VALUES (?, ?, ?, NULL, ?, 'At_Counter', 'Receptionist', ?, 'Waiting', GETDATE())"
                : "INSERT INTO Appointment (patient_id, doctor_id, schedule_id, conversation_id, "
                + "appointment_time, booking_type, queue_number, status, created_at) "
                + "VALUES (?, ?, ?, NULL, ?, 'At_Counter', ?, 'Waiting', GETDATE())";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, patientId);
            statement.setInt(2, doctorId);
            statement.setInt(3, scheduleId);
            statement.setTimestamp(4, Timestamp.valueOf(appointmentTime));
            statement.setInt(5, queueNumber);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("Unable to create appointment");
    }

    private boolean hasColumn(Connection connection, String tableName, String columnName) throws SQLException {
        String sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, tableName);
            statement.setString(2, columnName);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private void markScheduleFull(Connection connection, int scheduleId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE Doctor_Schedule SET status = 'Full' WHERE schedule_id = ?")) {
            statement.setInt(1, scheduleId);
            statement.executeUpdate();
        }
    }

    private Integer findPendingInvoiceId(Connection connection, String keyword) throws SQLException {
        String normalized = keyword == null ? "" : keyword.trim();
        boolean hasKeyword = !normalized.isEmpty();
        String sql = "SELECT TOP 1 i.invoice_id FROM Invoice i "
                + "LEFT JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.status = 'Pending' "
                + (hasKeyword ? "AND (p.phone = ? OR p.full_name LIKE ?) " : "")
                + "ORDER BY i.created_at DESC, i.invoice_id DESC";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            if (hasKeyword) {
                statement.setString(1, normalized);
                statement.setString(2, "%" + normalized + "%");
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? resultSet.getInt("invoice_id") : null;
            }
        }
    }

    private void markLateWaitingAppointmentsAsAbsent(Connection connection) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE Appointment SET status = 'Absent' WHERE status = 'Waiting' AND appointment_time < GETDATE()")) {
            statement.executeUpdate();
        }
    }

    private LocalTime parseStartTime(String timeSlot) {
        if (timeSlot == null || timeSlot.length() < 5) {
            return LocalTime.of(9, 0);
        }
        return LocalTime.parse(timeSlot.substring(0, 5));
    }

    private String formatScheduleLabel(Date workDate, String timeSlot) {
        return (workDate == null ? "" : workDate.toString()) + " " + (timeSlot == null ? "" : timeSlot);
    }

    private String toDisplayDateTime(Timestamp timestamp) {
        return timestamp == null ? "" : timestamp.toLocalDateTime().toString().replace('T', ' ');
    }

    private String emptyToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void rollback(Connection connection) {
        if (connection != null) {
            try {
                connection.rollback();
            } catch (SQLException ignored) {
            }
        }
    }

    private void close(Connection connection) {
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException ignored) {
            }
        }
    }

    public static class ReceptionistRegistrationRequest {
        public String patientName;
        public String phone;
        public String email;
        public LocalDate dateOfBirth;
        public String gender;
        public String address;
        public int doctorId;
        public int scheduleId;
        public String note;
    }

    public static class ReceptionistException extends Exception {
        public ReceptionistException(String message) {
            super(message);
        }
    }
}
