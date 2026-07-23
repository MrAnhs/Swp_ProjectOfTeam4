package com.diabetes.monitoring.notification;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class NotificationService {
    private final NotificationDAO notificationDAO = new NotificationDAO();
    private static final DateTimeFormatter DATE_TIME_FORMAT =
            DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");

    public int countUnread(int accountId) throws Exception {
        return notificationDAO.countUnread(accountId);
    }

    public List<Notification> findLatest(int accountId) throws Exception {
        return notificationDAO.findLatest(accountId, 5);
    }

    public List<Notification> findAll(int accountId) throws Exception {
        return notificationDAO.findLatest(accountId, 50);
    }

    public boolean markRead(int accountId, int notificationId) throws Exception {
        if (notificationId <= 0) return false;
        return notificationDAO.markRead(accountId, notificationId);
    }

    public void createUpcomingAppointmentReminders(int accountId) throws SQLException {
        String sql = "SELECT a.appointment_id FROM Appointment a "
                + "JOIN Patient p ON p.patient_id = a.patient_id "
                + "WHERE p.account_id = ? AND a.status = 'Waiting' "
                + "AND a.appointment_time > GETDATE() "
                + "AND a.appointment_time <= DATEADD(HOUR, 24, GETDATE())";
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                List<Integer> appointmentIds = new ArrayList<>();
                statement.setInt(1, accountId);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        appointmentIds.add(result.getInt("appointment_id"));
                    }
                }
                for (Integer appointmentId : appointmentIds) {
                    AppointmentNotificationData data = loadAppointment(connection, appointmentId);
                    if (data != null) {
                        create(connection, accountId, "Nh\u1EAFc l\u1ECBch kh\u00E1m s\u1EAFp t\u1EDBi",
                                "B\u1EA1n c\u00F3 l\u1ECBch kh\u00E1m v\u1EDBi "
                                        + valueOrDefault(data.doctorName, "b\u00E1c s\u0129")
                                        + " l\u00FAc " + format(data.appointmentTime) + ".",
                                "APPOINTMENT_REMINDER", appointmentTarget(appointmentId),
                                "APPOINTMENT_REMINDER:" + appointmentId);
                    }
                }
                connection.commit();
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public void notifyAppointmentCheckedIn(Connection connection, int appointmentId)
            throws SQLException {
        AppointmentNotificationData data = loadAppointment(connection, appointmentId);
        if (data == null) return;
        create(connection, data.accountId, "\u0110\u00E3 x\u00E1c nh\u1EADn \u0111\u1EBFn kh\u00E1m",
                "B\u1EA1n \u0111\u00E3 \u0111\u01B0\u1EE3c x\u00E1c nh\u1EADn c\u00F3 m\u1EB7t cho l\u1ECBch h\u1EB9n #"
                        + appointmentId + ".",
                "APPOINTMENT_CHECKED_IN", appointmentTarget(appointmentId),
                "APPOINTMENT_CHECKED_IN:" + appointmentId);
    }

    public void notifyAppointmentChanged(Connection connection, int appointmentId)
            throws SQLException {
        AppointmentNotificationData data = loadAppointment(connection, appointmentId);
        if (data == null) return;
        create(connection, data.accountId, "L\u1ECBch h\u1EB9n \u0111\u00E3 thay \u0111\u1ED5i",
                "L\u1ECBch h\u1EB9n #" + appointmentId + " \u0111\u01B0\u1EE3c chuy\u1EC3n sang "
                        + format(data.appointmentTime) + ".",
                "APPOINTMENT_CHANGED", appointmentTarget(appointmentId),
                "APPOINTMENT_CHANGED:" + appointmentId + ":" + data.scheduleId);
    }

    public void notifyAppointmentCancelled(Connection connection, int appointmentId)
            throws SQLException {
        AppointmentNotificationData data = loadAppointment(connection, appointmentId);
        if (data == null) return;
        create(connection, data.accountId, "L\u1ECBch h\u1EB9n \u0111\u00E3 h\u1EE7y",
                "L\u1ECBch h\u1EB9n #" + appointmentId + " \u0111\u00E3 \u0111\u01B0\u1EE3c h\u1EE7y.",
                "APPOINTMENT_CANCELLED", appointmentTarget(appointmentId),
                "APPOINTMENT_CANCELLED:" + appointmentId);
    }

    public void notifyAppointmentCreated(Connection connection, int appointmentId)
            throws SQLException {
        AppointmentNotificationData data = loadAppointment(connection, appointmentId);
        if (data == null) return;
        String content = "L\u1ECBch h\u1EB9n v\u1EDBi " + valueOrDefault(data.doctorName, "b\u00E1c s\u0129")
                + " l\u00FAc " + format(data.appointmentTime) + " \u0111\u00E3 \u0111\u01B0\u1EE3c t\u1EA1o.";
        create(connection, data.accountId, "\u0110\u1EB7t l\u1ECBch th\u00E0nh c\u00F4ng", content,
                "APPOINTMENT_CREATED", appointmentTarget(appointmentId),
                "APPOINTMENT_CREATED:" + appointmentId);
    }

    public void notifyInvoiceCreated(Connection connection, int invoiceId)
            throws SQLException {
        InvoiceNotificationData data = loadInvoice(connection, invoiceId);
        if (data == null) return;
        String content = "H\u00F3a \u0111\u01A1n #" + invoiceId + " c\u00F3 s\u1ED1 ti\u1EC1n "
                + data.finalAmount + " \u0111ang ch\u1EDD thanh to\u00E1n.";
        create(connection, data.accountId, "C\u00F3 h\u00F3a \u0111\u01A1n m\u1EDBi", content,
                "INVOICE_CREATED", "/patient/invoices/detail?id=" + invoiceId,
                "INVOICE_CREATED:" + invoiceId);
    }

    public void prepareLaboratoryOrders(Connection connection, int invoiceId)
            throws SQLException {
        String updateDetails = "UPDATE id SET id.lab_status = 'Requested', "
                + "id.requested_at = COALESCE(id.requested_at, GETDATE()) "
                + "FROM Invoice_Detail id JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_id = ? AND ms.service_type = 'Lab_Test' "
                + "AND (id.lab_status IS NULL OR id.lab_status = 'Waiting_Payment')";
        try (PreparedStatement statement = connection.prepareStatement(updateDetails)) {
            statement.setInt(1, invoiceId);
            statement.executeUpdate();
        }

        String insertOrders = "INSERT INTO Lab_Order "
                + "(order_id, appointment_id, patient_id, room_id, service_id, lab_id, status, created_at) "
                + "SELECT CONCAT('LAB-', id.invoice_detail_id), id.appointment_id, i.patient_id, "
                + "(SELECT TOP 1 r.room_id FROM Room r WHERE r.status = 'Active' "
                + "AND (r.room_id LIKE 'LAB%' OR r.room_name LIKE N'%x\u00E9t nghi\u1EC7m%') "
                + "ORDER BY (SELECT COUNT(*) FROM Lab_Order existing "
                + "WHERE existing.room_id = r.room_id AND existing.status IN ('Requested','Processing')), "
                + "r.room_id), id.service_id, NULL, 'Requested', GETDATE() "
                + "FROM Invoice_Detail id JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_id = ? AND id.appointment_id IS NOT NULL "
                + "AND ms.service_type = 'Lab_Test' "
                + "AND NOT EXISTS (SELECT 1 FROM Lab_Order lo "
                + "WHERE lo.order_id = CONCAT('LAB-', id.invoice_detail_id))";
        try (PreparedStatement statement = connection.prepareStatement(insertOrders)) {
            statement.setInt(1, invoiceId);
            statement.executeUpdate();
        }
    }

    public void notifyInvoicePaid(Connection connection, int invoiceId)
            throws SQLException {
        InvoiceNotificationData data = loadInvoice(connection, invoiceId);
        if (data == null) return;
        create(connection, data.accountId, "Thanh to\u00E1n th\u00E0nh c\u00F4ng",
                "H\u00F3a \u0111\u01A1n #" + invoiceId + " \u0111\u00E3 \u0111\u01B0\u1EE3c x\u00E1c nh\u1EADn thanh to\u00E1n.",
                "INVOICE_PAID", "/patient/invoices/detail?id=" + invoiceId,
                "INVOICE_PAID:" + invoiceId);
    }

    public void notifyLaboratoryRequested(Connection connection, int invoiceId)
            throws SQLException {
        String sql = "SELECT TOP 1 p.account_id, lo.appointment_id "
                + "FROM Invoice i JOIN Patient p ON p.patient_id = i.patient_id "
                + "JOIN Invoice_Detail id ON id.invoice_id = i.invoice_id "
                + "JOIN Lab_Order lo ON lo.order_id = CONCAT('LAB-', id.invoice_detail_id) "
                + "WHERE i.invoice_id = ? AND lo.appointment_id IS NOT NULL";
        int accountId;
        int appointmentId;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return;
                accountId = result.getInt("account_id");
                appointmentId = result.getInt("appointment_id");
            }
        }

        List<String> rooms = loadLaboratoryRooms(connection, appointmentId);
        String roomText = rooms.isEmpty()
                ? "ph\u00F2ng x\u00E9t nghi\u1EC7m \u0111\u01B0\u1EE3c ch\u1EC9 \u0111\u1ECBnh"
                : String.join("; ", rooms);
        String content = "Y\u00EAu c\u1EA7u x\u00E9t nghi\u1EC7m \u0111\u00E3 s\u1EB5n s\u00E0ng. Vui l\u00F2ng \u0111\u1EBFn "
                + roomText + ".";
        create(connection, accountId, "Y\u00EAu c\u1EA7u x\u00E9t nghi\u1EC7m", content,
                "LAB_REQUESTED", appointmentTarget(appointmentId),
                "LAB_REQUESTED:" + invoiceId);
    }

    public void notifyLaboratoryCompleted(Connection connection, int invoiceDetailId)
            throws SQLException {
        String sql = "SELECT p.account_id, id.appointment_id, ms.service_name "
                + "FROM Invoice_Detail id JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Patient p ON p.patient_id = i.patient_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_detail_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceDetailId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return;
                int appointmentId = result.getInt("appointment_id");
                String target = result.wasNull() ? "/patient/appointments" : appointmentTarget(appointmentId);
                create(connection, result.getInt("account_id"),
                        "C\u00F3 k\u1EBFt qu\u1EA3 x\u00E9t nghi\u1EC7m",
                        "X\u00E9t nghi\u1EC7m " + result.getString("service_name")
                                + " \u0111\u00E3 ho\u00E0n th\u00E0nh.",
                        "LAB_COMPLETED", target,
                        "LAB_COMPLETED:" + invoiceDetailId);
            }
        }
    }

    public void notifyMedicalRecordCompletedByHealthRecord(Connection connection,
            int healthRecordId, boolean visible) throws SQLException {
        notifyMedicalRecordCompleted(connection,
                "mr.health_record_id = ?", healthRecordId, visible,
                "HEALTH_RECORD:" + healthRecordId);
    }

    public void notifyMedicalRecordCompletedByRecord(Connection connection,
            int recordId, boolean visible) throws SQLException {
        notifyMedicalRecordCompleted(connection,
                "mr.record_id = ?", recordId, visible,
                "MEDICAL_RECORD:" + recordId);
    }

    private void notifyMedicalRecordCompleted(Connection connection, String condition,
            int id, boolean visible, String eventSuffix) throws SQLException {
        String sql = "SELECT p.account_id, mr.appointment_id FROM Medical_record mr "
                + "JOIN Patient p ON p.patient_id = mr.patient_id WHERE " + condition;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return;
                int appointmentId = result.getInt("appointment_id");
                String target = result.wasNull()
                        ? "/patient/history"
                        : "/patient/history/detail?id=" + appointmentId;
                String title = visible
                        ? "K\u1EBFt qu\u1EA3 kh\u00E1m \u0111\u00E3 \u0111\u01B0\u1EE3c c\u00F4ng b\u1ED1"
                        : "Bu\u1ED5i kh\u00E1m \u0111\u00E3 ho\u00E0n th\u00E0nh";
                String content = visible
                        ? "B\u00E1c s\u0129 \u0111\u00E3 c\u00F4ng b\u1ED1 k\u1EBFt qu\u1EA3 kh\u00E1m c\u1EE7a b\u1EA1n."
                        : "Bu\u1ED5i kh\u00E1m \u0111\u00E3 ho\u00E0n th\u00E0nh; k\u1EBFt qu\u1EA3 ch\u01B0a \u0111\u01B0\u1EE3c c\u00F4ng b\u1ED1.";
                create(connection, result.getInt("account_id"), title, content,
                        visible ? "RESULT_PUBLISHED" : "VISIT_COMPLETED", target,
                        (visible ? "RESULT_PUBLISHED:" : "VISIT_COMPLETED:") + eventSuffix);
            }
        }
    }

    public void notifyPasswordChanged(Connection connection, int accountId, boolean isForgotFlow)
            throws SQLException {
        String title = "Bảo mật: Mật khẩu đã thay đổi";
        String content = isForgotFlow
                ? "Mật khẩu của bạn đã được khôi phục thành công bằng tính năng Quên mật khẩu."
                : "Mật khẩu của bạn đã được thay đổi thành công qua Cài đặt.";
        String type = "SECURITY_ALERT";
        String targetUrl = "/settings";
        String eventKey = "PASSWORD_CHANGED:" + accountId + ":" + System.currentTimeMillis();
        create(connection, accountId, title, content, type, targetUrl, eventKey);
    }

    public void notifyEmailChanged(Connection connection, int accountId, String oldEmail, String newEmail)
            throws SQLException {
        String title = "Bảo mật: Email đã thay đổi";
        String content = "Địa chỉ email liên kết với tài khoản của bạn đã được đổi thành công từ "
                + oldEmail + " sang " + newEmail + ".";
        String type = "SECURITY_ALERT";
        String targetUrl = "/settings";
        String eventKey = "EMAIL_CHANGED:" + accountId + ":" + System.currentTimeMillis();
        create(connection, accountId, title, content, type, targetUrl, eventKey);
    }

    public void notifyProfileUpdated(Connection connection, int accountId)
            throws SQLException {
        String title = "Thông tin cá nhân đã cập nhật";
        String content = "Thông tin cá nhân của bạn đã được cập nhật thành công.";
        String type = "PROFILE_UPDATE";
        String targetUrl = "/settings";
        String eventKey = "PROFILE_UPDATED:" + accountId + ":" + System.currentTimeMillis();
        create(connection, accountId, title, content, type, targetUrl, eventKey);
    }

    public void notifyMedicalRecordDiagnosisCompleted(Connection connection, int recordId)
            throws SQLException {
        String sql = "SELECT p.account_id, mr.appointment_id, mr.revisit_date "
                + "FROM Medical_record mr "
                + "JOIN Patient p ON p.patient_id = mr.patient_id "
                + "WHERE mr.record_id = ? OR mr.health_record_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, recordId);
            statement.setInt(2, recordId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return;
                int accountId = result.getInt("account_id");
                int appointmentId = result.getInt("appointment_id");
                Timestamp revisitTs = result.getTimestamp("revisit_date");
                String target = "/patient/history/detail?id=" + appointmentId;

                create(connection, accountId,
                        "Kết quả khám bệnh",
                        "Bác sĩ đã hoàn tất kết quả khám và chỉ số xét nghiệm của bạn.",
                        "DIAGNOSIS_COMPLETED", target,
                        "DIAGNOSIS_COMPLETED:" + recordId + ":" + System.currentTimeMillis());

                if (revisitTs != null) {
                    String dateStr = revisitTs.toLocalDateTime().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                    create(connection, accountId,
                            "Lịch hẹn tái khám",
                            "Bạn có lịch hẹn tái khám vào ngày " + dateStr + ".",
                            "REVISIT_SCHEDULED", target,
                            "REVISIT_SCHEDULED:" + recordId + ":" + revisitTs.getTime());
                }
            }
        }
    }

    private void create(Connection connection, int accountId, String title,
            String content, String type, String targetUrl, String eventKey)
            throws SQLException {
        if (accountId > 0) {
            notificationDAO.create(connection, accountId, title, content,
                    type, targetUrl, eventKey);
        }
    }

    private AppointmentNotificationData loadAppointment(Connection connection,
            int appointmentId) throws SQLException {
        String sql = "SELECT p.account_id, a.schedule_id, a.appointment_time, d.full_name "
                + "FROM Appointment a JOIN Patient p ON p.patient_id = a.patient_id "
                + "JOIN Doctor_Schedule ds ON ds.schedule_id = a.schedule_id "
                + "JOIN Doctor d ON d.doctor_id = ds.doctor_id "
                + "WHERE a.appointment_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return null;
                AppointmentNotificationData data = new AppointmentNotificationData();
                data.accountId = result.getInt("account_id");
                data.scheduleId = result.getInt("schedule_id");
                data.appointmentTime = result.getTimestamp("appointment_time");
                data.doctorName = result.getString("full_name");
                return data;
            }
        }
    }

    private InvoiceNotificationData loadInvoice(Connection connection, int invoiceId)
            throws SQLException {
        String sql = "SELECT p.account_id, i.final_amount FROM Invoice i "
                + "JOIN Patient p ON p.patient_id = i.patient_id WHERE i.invoice_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return null;
                InvoiceNotificationData data = new InvoiceNotificationData();
                data.accountId = result.getInt("account_id");
                data.finalAmount = result.getBigDecimal("final_amount").toPlainString();
                return data;
            }
        }
    }

    private List<String> loadLaboratoryRooms(Connection connection, int appointmentId)
            throws SQLException {
        String sql = "SELECT DISTINCT r.room_name, r.location FROM Lab_Order lo "
                + "JOIN Room r ON r.room_id = lo.room_id "
                + "WHERE lo.appointment_id = ? AND lo.status IN ('Requested','Processing','Completed') "
                + "ORDER BY r.room_name";
        List<String> rooms = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, appointmentId);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    String room = result.getString("room_name");
                    String location = result.getString("location");
                    rooms.add(location == null || location.isBlank()
                            ? room : room + " (" + location + ")");
                }
            }
        }
        return rooms;
    }

    private String appointmentTarget(int appointmentId) {
        return "/patient/appointments/detail?id=" + appointmentId;
    }

    private String format(Timestamp timestamp) {
        return timestamp == null ? "ch\u01B0a c\u1EADp nh\u1EADt"
                : timestamp.toLocalDateTime().format(DATE_TIME_FORMAT);
    }

    private String valueOrDefault(String value, String defaultValue) {
        return value == null || value.isBlank() ? defaultValue : value;
    }

    private static class AppointmentNotificationData {
        private int accountId;
        private int scheduleId;
        private Timestamp appointmentTime;
        private String doctorName;
    }

    private static class InvoiceNotificationData {
        private int accountId;
        private String finalAmount;
    }
}
