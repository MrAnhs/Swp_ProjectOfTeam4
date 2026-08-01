package com.diabetes.monitoring.receptionist;

import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.PasswordUtil;
import com.diabetes.monitoring.notification.NotificationService;
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
import java.util.UUID;

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
            result.put("upcomingAppointments", findPatientAppointments(connection, patientId));
            return result;
        }
    }

    public Map<String, Object> findAppointmentPreview(int appointmentId) throws SQLException {
        String sql = "SELECT TOP 1 a.appointment_id, a.patient_id, ds.doctor_id AS doctor_id, a.schedule_id, a.appointment_time, "
                + "a.booking_type, a.queue_number, a.status, p.full_name, p.phone, p.email, p.address, "
                + "p.date_of_birth, p.gender, d.full_name AS doctor_name, d.department "
                + "FROM Appointment a "
                + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE a.appointment_id = ?";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapAppointmentPreview(resultSet) : null;
            }
        }
    }

    public Map<String, Object> findPatientByName(String fullName) throws SQLException {
        try (Connection connection = openConnection()) {
            Map<String, Object> patient = null;
            String patientSql = "SELECT TOP 1 patient_id, full_name, phone, email, address, date_of_birth, gender "
                    + "FROM Patient WHERE LOWER(full_name) = LOWER(?) ORDER BY patient_id DESC";
            try (PreparedStatement statement = connection.prepareStatement(patientSql)) {
                statement.setString(1, fullName);
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
            result.put("revisitDates", findPatientRevisitDates(connection, patientId));
            return result;
        }
    }

    public List<Map<String, Object>> findAppointmentsForCalendar(LocalDate fromDate, LocalDate toDate) throws SQLException {
        String sql = "SELECT a.appointment_id, a.appointment_time, a.status, a.queue_number, a.booking_type, "
                + "p.full_name AS patient_name, p.phone, d.full_name AS doctor_name "
                + "FROM Appointment a "
                + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE CAST(a.appointment_time AS date) BETWEEN ? AND ? "
                + "ORDER BY a.appointment_time, a.queue_number";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(fromDate));
            statement.setDate(2, Date.valueOf(toDate));
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> appointments = new ArrayList<>();
                while (resultSet.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("appointmentId", resultSet.getInt("appointment_id"));
                    item.put("appointmentTime", toDisplayDateTime(resultSet.getTimestamp("appointment_time")));
                    item.put("status", resultSet.getString("status"));
                    item.put("queueNumber", resultSet.getInt("queue_number"));
                    item.put("bookingType", resultSet.getString("booking_type"));
                    item.put("patientName", resultSet.getString("patient_name"));
                    item.put("phone", resultSet.getString("phone"));
                    item.put("doctorName", resultSet.getString("doctor_name"));
                    appointments.add(item);
                }
                return appointments;
            }
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
                + "AND (ds.work_date > CAST(GETDATE() AS date) "
                + "     OR CAST(GETDATE() AS time) < TRY_CONVERT(time, RIGHT(REPLACE(ds.time_slot, ' ', ''), 5))) "
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

    public Map<String, Object> createPatient(ReceptionistRegistrationRequest request)
            throws SQLException, ReceptionistException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setAutoCommit(false);
            Integer patientId = findPatientIdByPhone(connection, request.phone);
            if (patientId != null) {
                throw new ReceptionistException("Số điện thoại này đã được đăng ký cho một bệnh nhân khác.");
            }
            if (emailExists(connection, request.email)) {
                throw new ReceptionistException("Email này đã được đăng ký bởi một tài khoản khác.");
            }
            String temporaryPassword = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
            Integer accountId = insertPatientAccount(connection, request, temporaryPassword);
            patientId = insertPatient(connection, request, accountId);
            connection.commit();
            Map<String, Object> result = new HashMap<>();
            result.put("patientId", patientId);
            result.put("fullName", request.patientName);
            result.put("phone", request.phone);
            result.put("email", request.email);
            result.put("dateOfBirth", request.dateOfBirth.toString());
            result.put("gender", request.gender);
            result.put("address", request.address);
            result.put("accountId", accountId);
            result.put("temporaryPassword", temporaryPassword);
            return result;
        } catch (SQLException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }

    public Map<String, Object> registerAppointment(ReceptionistRegistrationRequest request)
            throws SQLException, ReceptionistException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);

            Map<String, Object> schedule = lockSchedule(connection, request.doctorId, request.scheduleId);
            if (schedule == null) {
                throw new ReceptionistException("Ca khám không hợp lệ hoặc đã hết chỗ.");
            }

            LocalDate workDate = ((Date) schedule.get("workDate")).toLocalDate();
            String formattedDate = workDate.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));

            Integer patientId = findPatientIdByPhone(connection, request.phone);

            if ("Revisit".equalsIgnoreCase(request.visitType)) {
                if (patientId == null || !hasRevisitScheduleOnDate(connection, patientId, workDate, request.revisitAppointmentId)) {
                    throw new ReceptionistException("Bệnh nhân không có lịch tái khám vào ngày " + formattedDate + ". Vui lòng chọn đăng ký Khám mới.");
                }
            }

            if (patientId == null) {
                patientId = insertPatient(connection, request);
            } else {
                String existingName = getPatientNameById(connection, patientId);
                if (existingName != null && !existingName.trim().equalsIgnoreCase(request.patientName.trim())) {
                    throw new ReceptionistException("Số điện thoại này đã được đăng ký cho bệnh nhân khác.");
                }
                if (hasActiveAppointmentOnSameDay(connection, patientId, request.scheduleId)) {
                    throw new ReceptionistException("Bệnh nhân này đã có lịch hẹn đăng ký vào ngày " + formattedDate + " rồi.");
                }
                updatePatient(connection, patientId, request);
            }

            String timeSlot = (String) schedule.get("timeSlot");
            LocalDateTime appointmentTime = LocalDateTime.of(workDate, parseStartTime(timeSlot));
            LocalDateTime endAppointmentTime = LocalDateTime.of(workDate, parseEndTime(timeSlot));
            if (!endAppointmentTime.isAfter(LocalDateTime.now())) {
                throw new ReceptionistException("Ca khám đã kết thúc.");
            }

            int booked = (Integer) schedule.get("booked");
            int maxPatients = (Integer) schedule.get("maxPatients");
            int queueNumber = nextQueueNumber(connection, request.scheduleId);
            String bookingType = "At_Counter";
            int appointmentId = insertAppointment(connection, patientId,
                    request.scheduleId, appointmentTime, queueNumber, bookingType);

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

    private boolean hasActiveAppointmentOnSameDay(Connection connection, int patientId, int targetScheduleId) throws SQLException {
        String sql = "SELECT 1 FROM Appointment a "
                + "INNER JOIN Doctor_Schedule target_ds ON target_ds.schedule_id = ? "
                + "INNER JOIN Doctor_Schedule existing_ds ON existing_ds.schedule_id = a.schedule_id "
                + "WHERE a.patient_id = ? "
                + "AND a.status <> 'Cancelled' "
                + "AND existing_ds.work_date = target_ds.work_date";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, targetScheduleId);
            statement.setInt(2, patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private boolean hasRevisitScheduleOnDate(Connection connection, int patientId, LocalDate targetDate, int revisitApptId) throws SQLException {
        String mrSql = "SELECT 1 FROM Medical_record "
                + "WHERE patient_id = ? AND revisit_date IS NOT NULL "
                + "AND CAST(revisit_date AS DATE) = ?";
        try (PreparedStatement statement = connection.prepareStatement(mrSql)) {
            statement.setInt(1, patientId);
            statement.setDate(2, Date.valueOf(targetDate));
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) return true;
            }
        }

        if (revisitApptId > 0) {
            String apptSql = "SELECT 1 FROM Appointment WHERE appointment_id = ? AND patient_id = ?";
            try (PreparedStatement statement = connection.prepareStatement(apptSql)) {
                statement.setInt(1, revisitApptId);
                statement.setInt(2, patientId);
                try (ResultSet rs = statement.executeQuery()) {
                    if (rs.next()) return true;
                }
            }
        }
        return false;
    }

    private List<String> findPatientRevisitDates(Connection connection, int patientId) throws SQLException {
        List<String> dates = new ArrayList<>();
        String sql = "SELECT DISTINCT CAST(revisit_date AS DATE) AS rev_date FROM Medical_record "
                + "WHERE patient_id = ? AND revisit_date IS NOT NULL ORDER BY rev_date DESC";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, patientId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Date d = rs.getDate("rev_date");
                    if (d != null) dates.add(d.toString());
                }
            }
        }
        return dates;
    }

    private String getPatientNameById(Connection connection, int patientId) throws SQLException {
        String sql = "SELECT full_name FROM Patient WHERE patient_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? resultSet.getString("full_name") : null;
            }
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

    public List<Map<String, Object>> findInvoicesByStatus(String status, String invoiceType) throws SQLException {
        return findInvoicesByStatus(status, invoiceType, null);
    }

    public List<Map<String, Object>> findInvoicesByStatus(String status, String invoiceType, String keyword) throws SQLException {
        StringBuilder sql = new StringBuilder(
                "SELECT TOP 50 i.invoice_id, i.patient_id, p.full_name, p.phone, "
                + "i.final_amount, i.status, i.created_at, "
                + "CASE WHEN EXISTS (SELECT 1 FROM Invoice_Detail id2 "
                + "INNER JOIN Medical_Service ms2 ON ms2.service_id = id2.service_id "
                + "WHERE id2.invoice_id = i.invoice_id AND ms2.service_type = 'Examination') "
                + "THEN 'Examination' ELSE 'Service' END AS invoice_type "
                + "FROM Invoice i LEFT JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.status = ? ");
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        if (hasKeyword) {
            sql.append("AND (p.phone LIKE ? OR REPLACE(REPLACE(REPLACE(p.phone, ' ', ''), '-', ''), '+84', '0') LIKE ? OR p.full_name LIKE ? OR CAST(i.invoice_id AS VARCHAR) LIKE ?) ");
        }
        if ("Examination".equalsIgnoreCase(invoiceType)) {
            sql.append("AND EXISTS (SELECT 1 FROM Invoice_Detail id2 INNER JOIN Medical_Service ms2 ON ms2.service_id = id2.service_id WHERE id2.invoice_id = i.invoice_id AND ms2.service_type = 'Examination') ");
        } else if ("Service".equalsIgnoreCase(invoiceType)) {
            sql.append("AND NOT EXISTS (SELECT 1 FROM Invoice_Detail id2 INNER JOIN Medical_Service ms2 ON ms2.service_id = id2.service_id WHERE id2.invoice_id = i.invoice_id AND ms2.service_type = 'Examination') ");
        }
        sql.append("ORDER BY i.created_at DESC, i.invoice_id DESC");
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int paramIdx = 1;
            statement.setString(paramIdx++, status);
            if (hasKeyword) {
                String rawKw = keyword.trim();
                String kw = "%" + rawKw + "%";
                String cleanKw = "%" + rawKw.replaceAll("[\\s\\-\\+]", "").replaceFirst("^84", "0") + "%";
                statement.setString(paramIdx++, kw);
                statement.setString(paramIdx++, cleanKw);
                statement.setString(paramIdx++, kw);
                statement.setString(paramIdx++, kw);
            }
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
                    invoice.put("invoiceType", resultSet.getString("invoice_type"));
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

            Integer receptionId = findReceptionIdByAccountId(connection, receptionistAccountId);

            String sql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                    + "receptionist_id = ?, exported_at = GETDATE() WHERE invoice_id = ? AND status = 'Pending'";
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setString(1, paymentMethod);
                if (receptionId == null) {
                    statement.setNull(2, java.sql.Types.INTEGER);
                } else {
                    statement.setInt(2, receptionId);
                }
                statement.setInt(3, invoiceId);
                if (statement.executeUpdate() == 0) {
                    throw new ReceptionistException("Hóa đơn đã được xử lý trước đó.");
                }
            }

            NotificationService notificationService = new NotificationService();
            notificationService.prepareLaboratoryOrders(connection, invoiceId);
            connection.commit();

            try {
                notificationService.notifyInvoicePaid(connection, invoiceId);
                notificationService.notifyLaboratoryRequested(connection, invoiceId);
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            return invoiceId;
        } catch (SQLException | ReceptionistException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }

    public int payPendingInvoiceById(int invoiceId, String paymentMethod, int receptionistAccountId)
            throws SQLException, ReceptionistException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setAutoCommit(false);

            Integer receptionId = findReceptionIdByAccountId(connection, receptionistAccountId);

            String sql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                    + "receptionist_id = ?, exported_at = GETDATE() WHERE invoice_id = ? AND status = 'Pending'";
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setString(1, paymentMethod);
                if (receptionId == null) {
                    statement.setNull(2, java.sql.Types.INTEGER);
                } else {
                    statement.setInt(2, receptionId);
                }
                statement.setInt(3, invoiceId);
                if (statement.executeUpdate() == 0) {
                    throw new ReceptionistException("Hóa đơn không tồn tại hoặc đã được xử lý trước đó.");
                }
            }

            NotificationService notificationService = new NotificationService();
            notificationService.prepareLaboratoryOrders(connection, invoiceId);
            connection.commit();

            try {
                notificationService.notifyInvoicePaid(connection, invoiceId);
                notificationService.notifyLaboratoryRequested(connection, invoiceId);
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            return invoiceId;
        } catch (SQLException | ReceptionistException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }


    public List<Map<String, Object>> findInvoiceDetails(int invoiceId) throws SQLException {
        String sql = "SELECT id.invoice_detail_id, id.service_id, ms.service_name, ms.service_type, "
                + "id.quantity, id.price "
                + "FROM Invoice_Detail id "
                + "INNER JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_id = ? "
                + "ORDER BY id.invoice_detail_id ASC";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> details = new ArrayList<>();
                while (resultSet.next()) {
                    Map<String, Object> detail = new HashMap<>();
                    detail.put("invoiceDetailId", resultSet.getInt("invoice_detail_id"));
                    detail.put("serviceId", resultSet.getInt("service_id"));
                    detail.put("serviceName", resultSet.getString("service_name"));
                    detail.put("serviceType", resultSet.getString("service_type"));
                    detail.put("quantity", resultSet.getInt("quantity"));
                    detail.put("price", resultSet.getBigDecimal("price"));
                    details.add(detail);
                }
                return details;
            }
        }
    }

    public List<Map<String, Object>> findTodayQueue(String status) throws SQLException {
        String sql = "SELECT a.appointment_id, a.queue_number, a.appointment_time, a.status, "
                + "p.full_name AS patient_name, p.phone, d.full_name AS doctor_name, mr.revisit_date "
                + "FROM Appointment a "
                + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "LEFT JOIN Medical_record mr ON mr.appointment_id = a.appointment_id "
                + "WHERE CAST(a.appointment_time AS date) = CAST(GETDATE() AS date) "
                + (status == null || status.isBlank() ? "AND a.status IN ('Waiting', 'Checked_In', 'In_Progress') " : "AND a.status = ? ")
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
                    
                    java.sql.Timestamp revisitTs = resultSet.getTimestamp("revisit_date");
                    if (revisitTs != null) {
                        item.put("revisitDate", new java.text.SimpleDateFormat("dd/MM/yyyy").format(revisitTs));
                    } else {
                        item.put("revisitDate", null);
                    }
                    
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

    public boolean reassignAppointment(int appointmentId, int doctorId, int scheduleId) throws SQLException {
        Connection connection = null;
        try {
            connection = openConnection();
            connection.setAutoCommit(false);
            Map<String, Object> schedule = loadScheduleInfo(connection, scheduleId, doctorId);
            if (schedule == null) {
                throw new SQLException("Ca khám không hợp lệ.");
            }
            LocalDate workDate = ((Date) schedule.get("workDate")).toLocalDate();
            String timeSlot = (String) schedule.get("timeSlot");
            LocalDateTime appointmentTime = LocalDateTime.of(workDate, parseStartTime(timeSlot));
            String sql = "UPDATE Appointment SET schedule_id = ?, appointment_time = ?, status = 'Waiting' "
                    + "WHERE appointment_id = ? AND status IN ('Waiting', 'Checked_In')";
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, scheduleId);
                statement.setTimestamp(2, Timestamp.valueOf(appointmentTime));
                statement.setInt(3, appointmentId);
                if (statement.executeUpdate() == 0) {
                    throw new SQLException("Không thể đổi bác sĩ/ca cho lịch hẹn này.");
                }
            }
            connection.commit();
            return true;
        } catch (SQLException e) {
            rollback(connection);
            throw e;
        } finally {
            close(connection);
        }
    }

    public boolean cancelAppointment(int appointmentId) throws SQLException {
        String sql = "UPDATE Appointment SET status = 'Cancelled' WHERE appointment_id = ? AND status IN ('Waiting', 'Checked_In')";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            return statement.executeUpdate() > 0;
        }
    }

    public Map<String, Object> findActiveShiftForNow(int accountId, LocalDate currentDate, LocalTime currentTime) {
        String sql = "SELECT rs.reception_sched_id, rs.work_date, rs.time_slot, rs.status "
                + "FROM Reception_Schedule rs "
                + "INNER JOIN Reception r ON r.reception_id = rs.reception_id "
                + "WHERE r.account_id = ? AND CAST(rs.work_date AS DATE) = ? "
                + "AND LOWER(LTRIM(RTRIM(COALESCE(rs.status, 'Active')))) NOT IN ('cancelled', 'expired', 'inactive')";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setDate(2, Date.valueOf(currentDate));
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    String timeSlot = rs.getString("time_slot");
                    if (isTimeInShiftSlot(currentTime, timeSlot)) {
                        Map<String, Object> shift = new HashMap<>();
                        shift.put("scheduleId", rs.getInt("reception_sched_id"));
                        shift.put("workDate", rs.getDate("work_date").toString());
                        shift.put("timeSlot", timeSlot);
                        shift.put("status", rs.getString("status"));
                        return shift;
                    }
                }
            }
        } catch (SQLException ex) {
            java.util.logging.Logger.getLogger(ReceptionistDAO.class.getName())
                    .log(java.util.logging.Level.SEVERE, "Failed to check receptionist shift access", ex);
        }
        return null;
    }

    public boolean isTimeInShiftSlot(LocalTime time, String timeSlot) {
        if (timeSlot == null || timeSlot.trim().isEmpty()) {
            return false;
        }
        String slot = timeSlot.trim().toLowerCase();
        if (slot.contains("sáng") || slot.contains("sang") || slot.contains("morning")) {
            return time.isAfter(LocalTime.of(6, 45)) && time.isBefore(LocalTime.of(12, 15));
        }
        if (slot.contains("chiều") || slot.contains("chieu") || slot.contains("afternoon")) {
            return time.isAfter(LocalTime.of(12, 45)) && time.isBefore(LocalTime.of(18, 15));
        }
        String[] parts = slot.split("-", 2);
        if (parts.length == 2) {
            try {
                String startStr = parts[0].trim();
                String endStr = parts[1].trim();
                if (startStr.length() == 4 && startStr.contains(":")) startStr = "0" + startStr;
                if (endStr.length() == 4 && endStr.contains(":")) endStr = "0" + endStr;
                LocalTime start = LocalTime.parse(startStr.substring(0, 5));
                LocalTime end = LocalTime.parse(endStr.substring(0, 5));
                LocalTime bufferedStart = start.minusMinutes(15);
                LocalTime bufferedEnd = end.plusMinutes(15);
                if (start.isBefore(end)) {
                    return !time.isBefore(bufferedStart) && !time.isAfter(bufferedEnd);
                } else {
                    return !time.isBefore(bufferedStart) || !time.isAfter(bufferedEnd);
                }
            } catch (Exception ignored) {
            }
        }
        return false;
    }

    public List<Map<String, Object>> findMySchedule(int accountId, LocalDate fromDate, LocalDate toDate) throws SQLException {
        String sql = "SELECT rs.reception_sched_id, rs.work_date, rs.time_slot, rs.status, COALESCE(a.full_name, N'Nhân viên Lễ tân') AS full_name "
                + "FROM Reception_Schedule rs "
                + "LEFT JOIN Reception r ON r.reception_id = rs.reception_id "
                + "LEFT JOIN Account a ON a.account_id = r.account_id "
                + "WHERE (r.account_id = ? OR rs.reception_id = (SELECT TOP 1 reception_id FROM Reception WHERE account_id = ?)) "
                + "  AND CAST(rs.work_date AS DATE) BETWEEN ? AND ? "
                + "ORDER BY rs.work_date, rs.time_slot";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            statement.setInt(2, accountId);
            statement.setDate(3, Date.valueOf(fromDate));
            statement.setDate(4, Date.valueOf(toDate));
            try (ResultSet resultSet = statement.executeQuery()) {
                List<Map<String, Object>> schedule = new ArrayList<>();
                while (resultSet.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("scheduleId", resultSet.getInt("reception_sched_id"));
                    Date workDate = resultSet.getDate("work_date");
                    item.put("workDate", workDate == null ? "" : workDate.toString());
                    item.put("timeSlot", resultSet.getString("time_slot"));
                    item.put("status", resultSet.getString("status"));
                    item.put("fullName", resultSet.getString("full_name"));
                    schedule.add(item);
                }
                return schedule;
            }
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
                + "FROM Appointment a LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
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

    public List<Map<String, Object>> findPatientAppointments(Connection connection, int patientId)
            throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT a.appointment_id, a.appointment_time, a.booking_type, a.status, "
                + "a.queue_number, d.full_name AS doctor_name "
                + "FROM Appointment a LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE a.patient_id = ? ORDER BY a.appointment_time DESC";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, patientId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Map<String, Object> appointment = new HashMap<>();
                    appointment.put("appointmentId", resultSet.getInt("appointment_id"));
                    appointment.put("appointmentTime", toDisplayDateTime(resultSet.getTimestamp("appointment_time")));
                    appointment.put("bookingType", resultSet.getString("booking_type"));
                    String status = resultSet.getString("status");
                    appointment.put("status", status);
                    appointment.put("queueNumber", resultSet.getInt("queue_number"));
                    appointment.put("doctorName", resultSet.getString("doctor_name"));
                    appointment.put("canCancel", "Waiting".equalsIgnoreCase(status));
                    list.add(appointment);
                }
            }
        }
        return list;
    }

    public boolean cancelAppointmentByReceptionist(int appointmentId, String reason, int receptionistAccountId) throws SQLException, ReceptionistException {
        try (Connection connection = openConnection()) {
            connection.setAutoCommit(false);
            try {
                String querySql = "SELECT a.appointment_id, a.patient_id, a.appointment_time, a.status, "
                        + "p.account_id AS patient_account_id, p.full_name AS patient_name, "
                        + "d.full_name AS doctor_name "
                        + "FROM Appointment a "
                        + "INNER JOIN Patient p ON p.patient_id = a.patient_id "
                        + "LEFT JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                        + "LEFT JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                        + "WHERE a.appointment_id = ?";
                int patientAccountId = 0;
                String currentStatus = null;
                String doctorName = "";
                Timestamp appointmentTime = null;
                String patientName = "";

                try (PreparedStatement statement = connection.prepareStatement(querySql)) {
                    statement.setInt(1, appointmentId);
                    try (ResultSet resultSet = statement.executeQuery()) {
                        if (resultSet.next()) {
                            currentStatus = resultSet.getString("status");
                            patientAccountId = resultSet.getInt("patient_account_id");
                            doctorName = resultSet.getString("doctor_name");
                            appointmentTime = resultSet.getTimestamp("appointment_time");
                            patientName = resultSet.getString("patient_name");
                        }
                    }
                }

                if (currentStatus == null) {
                    throw new ReceptionistException("Không tìm thấy lịch hẹn.");
                }

                if ("Cancelled".equalsIgnoreCase(currentStatus)) {
                    throw new ReceptionistException("Lịch hẹn này đã được hủy trước đó.");
                }

                if (!"Waiting".equalsIgnoreCase(currentStatus)) {
                    throw new ReceptionistException("Chỉ có thể hủy lịch hẹn ở trạng thái Chờ khám (Waiting). Lịch hẹn đã check-in hoặc đang khám không thể hủy.");
                }

                String updateSql = "UPDATE Appointment SET status = 'Cancelled' WHERE appointment_id = ? AND status = 'Waiting'";
                try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                    statement.setInt(1, appointmentId);
                    int updated = statement.executeUpdate();
                    if (updated <= 0) {
                        throw new ReceptionistException("Không thể hủy lịch hẹn (trạng thái đã thay đổi).");
                    }
                }

                if (patientAccountId > 0) {
                    String timeStr = toDisplayDateTime(appointmentTime);
                    String notifTitle = "Lịch khám đã bị hủy";
                    String notifContent = "Lịch khám ngày " + timeStr + " với " + (doctorName != null ? doctorName : "Bác sĩ") 
                            + " đã được hủy bởi Lễ tân." + (reason != null && !reason.isBlank() ? " Lý do: " + reason.trim() : "");
                    
                    try {
                        com.diabetes.monitoring.notification.NotificationDAO notifDAO = new com.diabetes.monitoring.notification.NotificationDAO();
                        notifDAO.create(connection, patientAccountId, notifTitle, notifContent, "Appointment_Cancelled", "/patient/appointments", "CANCEL_" + appointmentId);
                    } catch (Exception ex) {
                        String notifSql = "INSERT INTO Notification (AccountID, Title, Content, Type, IsRead, CreatedAt) VALUES (?, ?, ?, 'Appointment_Cancelled', 0, GETDATE())";
                        try (PreparedStatement notifStmt = connection.prepareStatement(notifSql)) {
                            notifStmt.setInt(1, patientAccountId);
                            notifStmt.setString(2, notifTitle);
                            notifStmt.setString(3, notifContent);
                            notifStmt.executeUpdate();
                        } catch (Exception ignored) {
                        }
                    }
                }

                connection.commit();
                return true;
            } catch (Exception e) {
                connection.rollback();
                if (e instanceof ReceptionistException) {
                    throw (ReceptionistException) e;
                }
                throw new SQLException("Lỗi khi hủy lịch hẹn: " + e.getMessage(), e);
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

    private boolean emailExists(Connection connection, String email) throws SQLException {
        if (email == null || email.isBlank()) return false;
        String sql = "SELECT 1 FROM Account WHERE email = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email.trim());
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private int insertPatient(Connection connection, ReceptionistRegistrationRequest request)
            throws SQLException {
        return insertPatient(connection, request, null);
    }

    private int insertPatient(Connection connection, ReceptionistRegistrationRequest request, Integer accountId)
            throws SQLException {
        String sql = "INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, request.patientName);
            statement.setDate(2, Date.valueOf(request.dateOfBirth));
            statement.setString(3, request.gender);
            statement.setString(4, request.phone);
            statement.setString(5, emptyToNull(request.email));
            statement.setString(6, request.address);
            if (accountId == null) {
                statement.setNull(7, java.sql.Types.INTEGER);
            } else {
                statement.setInt(7, accountId);
            }
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("Unable to create patient");
    }

    private int insertPatientAccount(Connection connection, ReceptionistRegistrationRequest request, String temporaryPassword)
            throws SQLException {
        String sql = "INSERT INTO Account (full_name, password_hash, email, role, created_at, status) "
                + "VALUES (?, ?, ?, 'Patient', GETDATE(), 'Active')";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, request.patientName);
            statement.setString(2, PasswordUtil.hashPassword(temporaryPassword));
            statement.setString(3, request.email);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Unable to create patient account");
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

    private Map<String, Object> loadScheduleInfo(Connection connection, int scheduleId, int doctorId) throws SQLException {
        String sql = "SELECT ds.work_date, ds.time_slot FROM Doctor_Schedule ds "
                + "WHERE ds.schedule_id = ? AND ds.doctor_id = ? AND ds.status = 'Available'";
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
                return schedule;
            }
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

    private int insertAppointment(Connection connection, int patientId, int scheduleId,
            LocalDateTime appointmentTime, int queueNumber, String bookingType) throws SQLException {
        boolean hasBookingSource = hasColumn(connection, "Appointment", "booking_source");
        boolean hasConversationId = hasColumn(connection, "Appointment", "conversation_id");
        String effectiveBookingType = bookingType == null || bookingType.isBlank() ? "At_Counter" : bookingType;
        String columns = hasConversationId
                ? "patient_id, schedule_id, conversation_id, appointment_time, booking_type, "
                : "patient_id, schedule_id, appointment_time, booking_type, ";
        String values = hasConversationId ? "?, ?, NULL, ?, ?, " : "?, ?, ?, ?, ";
        if (hasBookingSource) {
            columns += "booking_source, ";
            values += "'Receptionist', ";
        }
        String sql = "INSERT INTO Appointment (" + columns
                + "queue_number, status, created_at) VALUES (" + values
                + "?, 'Waiting', GETDATE())";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, patientId);
            statement.setInt(2, scheduleId);
            statement.setTimestamp(3, Timestamp.valueOf(appointmentTime));
            statement.setString(4, effectiveBookingType);
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
                "UPDATE a SET status = 'Absent' FROM Appointment a "
                + "INNER JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "WHERE a.status = 'Waiting' "
                + "AND DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS time), "
                + "TRY_CONVERT(time, RIGHT(REPLACE(ds.time_slot, ' ', ''), 5))), "
                + "CAST(CAST(a.appointment_time AS date) AS datetime)) < GETDATE()")) {
            statement.executeUpdate();
        }
    }

    private LocalTime parseStartTime(String timeSlot) {
        if (timeSlot == null || timeSlot.length() < 5) {
            return LocalTime.of(9, 0);
        }
        return LocalTime.parse(timeSlot.substring(0, 5));
    }

    private LocalTime parseEndTime(String timeSlot) {
        if (timeSlot == null || timeSlot.length() < 11) {
            return LocalTime.of(17, 0);
        }
        try {
            return LocalTime.parse(timeSlot.substring(6, 11));
        } catch (Exception e) {
            return LocalTime.of(17, 0);
        }
    }

    private Map<String, Object> mapAppointmentPreview(ResultSet resultSet) throws SQLException {
        Map<String, Object> appointment = new HashMap<>();
        appointment.put("appointmentId", resultSet.getInt("appointment_id"));
        appointment.put("patientId", resultSet.getInt("patient_id"));
        appointment.put("doctorId", resultSet.getInt("doctor_id"));
        appointment.put("scheduleId", resultSet.getInt("schedule_id"));
        appointment.put("appointmentTime", toDisplayDateTime(resultSet.getTimestamp("appointment_time")));
        appointment.put("bookingType", resultSet.getString("booking_type"));
        appointment.put("queueNumber", resultSet.getInt("queue_number"));
        appointment.put("status", resultSet.getString("status"));
        appointment.put("patientName", resultSet.getString("full_name"));
        appointment.put("phone", resultSet.getString("phone"));
        appointment.put("email", resultSet.getString("email"));
        appointment.put("address", resultSet.getString("address"));
        Date dob = resultSet.getDate("date_of_birth");
        appointment.put("dateOfBirth", dob == null ? "" : dob.toString());
        appointment.put("gender", resultSet.getString("gender"));
        appointment.put("doctorName", resultSet.getString("doctor_name"));
        appointment.put("department", resultSet.getString("department"));
        return appointment;
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

    public List<Map<String, Object>> findUpcomingRevisits(LocalDate date) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT mr.record_id, mr.appointment_id, p.patient_id, p.full_name AS patient_name, "
                + "p.phone AS patient_phone, p.email AS patient_email, p.gender AS patient_gender, "
                + "p.address AS patient_address, p.date_of_birth AS patient_dob, "
                + "mr.revisit_date, d.full_name AS doctor_name, "
                + "(SELECT TOP 1 a.appointment_id FROM Appointment a "
                + " INNER JOIN Doctor_Schedule ds ON a.schedule_id = ds.schedule_id "
                + " WHERE a.patient_id = p.patient_id "
                + "   AND ds.work_date = CAST(mr.revisit_date AS DATE) "
                + "   AND a.status <> 'Cancelled' "
                + ") AS active_appointment_id "
                + "FROM Medical_record mr "
                + "JOIN Patient p ON mr.patient_id = p.patient_id "
                + "LEFT JOIN Doctor d ON mr.doctor_id = d.doctor_id "
                + "WHERE mr.revisit_date IS NOT NULL "
                + "  AND CAST(mr.revisit_date AS DATE) = ? "
                + "ORDER BY mr.revisit_date ASC";
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(date));
            try (ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("recordId", resultSet.getInt("record_id"));
                item.put("patientId", resultSet.getInt("patient_id"));
                item.put("revisitAppointmentId", resultSet.getObject("appointment_id") == null ? "" : resultSet.getInt("appointment_id"));
                item.put("activeAppointmentId", resultSet.getObject("active_appointment_id") == null ? "" : resultSet.getInt("active_appointment_id"));
                item.put("patientName", resultSet.getString("patient_name"));
                item.put("patientPhone", resultSet.getString("patient_phone"));
                item.put("patientEmail", resultSet.getString("patient_email") == null ? "" : resultSet.getString("patient_email"));
                item.put("patientGender", resultSet.getString("patient_gender") == null ? "Male" : resultSet.getString("patient_gender"));
                item.put("patientAddress", resultSet.getString("patient_address") == null ? "" : resultSet.getString("patient_address"));
                Date dob = resultSet.getDate("patient_dob");
                item.put("patientDob", dob == null ? "" : dob.toString());
                Date revisit = resultSet.getDate("revisit_date");
                item.put("revisitDate", revisit == null ? "" : revisit.toString());
                item.put("doctorName", resultSet.getString("doctor_name") == null ? "Không xác định" : resultSet.getString("doctor_name"));
                list.add(item);
        }
        }
        }
        return list;
    }

    private Integer findReceptionIdByAccountId(Connection connection, int accountId) throws SQLException {
        String sql = "SELECT reception_id FROM Reception WHERE account_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("reception_id");
                }
            }
        }
        String fallbackSql = "SELECT TOP 1 reception_id FROM Reception ORDER BY reception_id ASC";
        try (PreparedStatement statement = connection.prepareStatement(fallbackSql);
             ResultSet rs = statement.executeQuery()) {
            return rs.next() ? rs.getInt("reception_id") : null;
        }
    }

    public boolean registerMySchedule(int accountId, LocalDate workDate, String timeSlot) throws SQLException, ReceptionistException {
        try (Connection connection = openConnection()) {
            Integer receptionId = findReceptionIdByAccountId(connection, accountId);
            if (receptionId == null) {
                throw new ReceptionistException("Không tìm thấy thông tin lễ tân cho tài khoản này.");
            }
            
            // Check if this slot already exists for this receptionist
            String checkSql = "SELECT 1 FROM Reception_Schedule WHERE reception_id = ? AND work_date = ? AND time_slot = ?";
            try (PreparedStatement checkStmt = connection.prepareStatement(checkSql)) {
                checkStmt.setInt(1, receptionId);
                checkStmt.setDate(2, Date.valueOf(workDate));
                checkStmt.setString(3, timeSlot);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        throw new ReceptionistException("Lịch trực này của bạn đã được đăng ký trước đó.");
                    }
                }
            }
            
            // Insert the schedule
            String insertSql = "INSERT INTO Reception_Schedule (reception_id, work_date, time_slot, status) VALUES (?, ?, ?, 'Active')";
            try (PreparedStatement insertStmt = connection.prepareStatement(insertSql)) {
                insertStmt.setInt(1, receptionId);
                insertStmt.setDate(2, Date.valueOf(workDate));
                insertStmt.setString(3, timeSlot);
                return insertStmt.executeUpdate() > 0;
            }
        }
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
        public String visitType;
        public int doctorId;
        public int scheduleId;
        public int revisitAppointmentId;
        public String note;
    }

    public static class ReceptionistException extends Exception {
        public ReceptionistException(String message) {
            super(message);
        }
    }
}
