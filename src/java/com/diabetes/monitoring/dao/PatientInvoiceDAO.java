package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.InvoiceInfo;
import com.diabetes.monitoring.model.InvoiceItem;
import com.diabetes.monitoring.notification.NotificationService;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public class PatientInvoiceDAO {
    private static final Set<String> PAYMENT_METHODS =
            Set.of("Cash", "Momo", "VNPay", "Bank_Transfer");

    public List<InvoiceInfo> findByPatientAccountId(int accountId) throws SQLException {
        return findByPatientAccountId(accountId, null);
    }

    public List<InvoiceInfo> findByPatientAccountId(int accountId, LocalDate searchDate)
            throws SQLException {
        String sql = "SELECT i.invoice_id, i.total_amount, i.insurance_deduction, i.final_amount, "
                + "i.payment_method, i.status, i.created_at, i.exported_at, "
                + "p.patient_id, p.full_name AS patient_name, p.phone AS patient_phone, "
                + "p.email AS patient_email, p.address AS patient_address "
                + "FROM Invoice i INNER JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE p.account_id = ? "
                + (searchDate == null ? "" : "AND CAST(i.created_at AS date) = ? ")
                + "ORDER BY i.created_at DESC, i.invoice_id DESC";
        List<InvoiceInfo> invoices = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            if (searchDate != null) {
                statement.setDate(2, java.sql.Date.valueOf(searchDate));
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) invoices.add(mapInvoice(resultSet));
            }
        }
        return invoices;
    }

    public InvoiceInfo findById(int invoiceId, int accountId) throws SQLException {
        String sql = "SELECT i.invoice_id, i.total_amount, i.insurance_deduction, i.final_amount, "
                + "i.payment_method, i.status, i.created_at, i.exported_at, "
                + "p.patient_id, p.full_name AS patient_name, p.phone AS patient_phone, "
                + "p.email AS patient_email, p.address AS patient_address "
                + "FROM Invoice i INNER JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE i.invoice_id = ? AND p.account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            statement.setInt(2, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapInvoice(resultSet) : null;
            }
        }
    }

    public InvoiceInfo findById(int invoiceId) throws SQLException {
        String sql = "SELECT i.invoice_id, i.total_amount, i.insurance_deduction, i.final_amount, "
                + "i.payment_method, i.status, i.created_at, i.exported_at, "
                + "p.patient_id, p.full_name AS patient_name, p.phone AS patient_phone, "
                + "p.email AS patient_email, p.address AS patient_address "
                + "FROM Invoice i INNER JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE i.invoice_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapInvoice(resultSet) : null;
            }
        }
    }

    public List<InvoiceItem> findItems(int invoiceId, int accountId) throws SQLException {
        String sql = "SELECT id.invoice_detail_id, id.appointment_id, id.service_id, "
                + "ms.service_name, ms.service_type, id.quantity, id.price "
                + "FROM Invoice_Detail id "
                + "INNER JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "INNER JOIN Patient p ON p.patient_id = i.patient_id "
                + "INNER JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "WHERE id.invoice_id = ? AND p.account_id = ? ORDER BY id.invoice_detail_id";
        List<InvoiceItem> items = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, invoiceId);
            statement.setInt(2, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    InvoiceItem item = new InvoiceItem();
                    item.setInvoiceDetailId(resultSet.getInt("invoice_detail_id"));
                    item.setAppointmentId(resultSet.getInt("appointment_id"));
                    item.setServiceId(resultSet.getInt("service_id"));
                    item.setServiceName(resultSet.getString("service_name"));
                    item.setServiceType(resultSet.getString("service_type"));
                    item.setQuantity(resultSet.getInt("quantity"));
                    item.setPrice(resultSet.getBigDecimal("price"));
                    items.add(item);
                }
            }
        }
        return items;
    }

    public boolean requestPayment(int invoiceId, int accountId, String paymentMethod)
            throws SQLException {
        if (!PAYMENT_METHODS.contains(paymentMethod)) {
            throw new IllegalArgumentException("Phương thức thanh toán không hợp lệ.");
        }
        String sql = "UPDATE i SET payment_method = ? "
                + "FROM Invoice i INNER JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE i.invoice_id = ? AND p.account_id = ? AND i.status = 'Pending'";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, paymentMethod);
            statement.setInt(2, invoiceId);
            statement.setInt(3, accountId);
            return statement.executeUpdate() > 0;
        }
    }

    public boolean payInvoiceOnline(int invoiceId, String paymentMethod) throws SQLException {
        if (!PAYMENT_METHODS.contains(paymentMethod)) {
            throw new IllegalArgumentException("Phương thức thanh toán không hợp lệ.");
        }
        String sql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                + "exported_at = GETDATE() WHERE invoice_id = ? AND status = 'Pending'";
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setString(1, paymentMethod);
                statement.setInt(2, invoiceId);
                if (statement.executeUpdate() > 0) {
                    NotificationService notificationService = new NotificationService();
                    notificationService.prepareLaboratoryOrders(connection, invoiceId);
                    notificationService.notifyInvoicePaid(connection, invoiceId);
                    notificationService.notifyLaboratoryRequested(connection, invoiceId);
                    connection.commit();
                    return true;
                }
                connection.rollback();
                return false;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            }
        }
    }

    private InvoiceInfo mapInvoice(ResultSet resultSet) throws SQLException {
        InvoiceInfo invoice = new InvoiceInfo();
        invoice.setInvoiceId(resultSet.getInt("invoice_id"));
        invoice.setTotalAmount(resultSet.getBigDecimal("total_amount"));
        invoice.setInsuranceDeduction(resultSet.getBigDecimal("insurance_deduction"));
        invoice.setFinalAmount(resultSet.getBigDecimal("final_amount"));
        invoice.setPaymentMethod(resultSet.getString("payment_method"));
        invoice.setStatus(resultSet.getString("status"));
        invoice.setCreatedAt(toLocalDateTime(resultSet.getTimestamp("created_at")));
        invoice.setExportedAt(toLocalDateTime(resultSet.getTimestamp("exported_at")));
        invoice.setPatientId(resultSet.getInt("patient_id"));
        invoice.setPatientName(resultSet.getString("patient_name"));
        invoice.setPatientPhone(resultSet.getString("patient_phone"));
        invoice.setPatientEmail(resultSet.getString("patient_email"));
        invoice.setPatientAddress(resultSet.getString("patient_address"));
        return invoice;
    }

    private java.time.LocalDateTime toLocalDateTime(Timestamp value) {
        return value == null ? null : value.toLocalDateTime();
    }
}
