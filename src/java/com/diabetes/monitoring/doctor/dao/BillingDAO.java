package com.diabetes.monitoring.doctor.dao;

import com.diabetes.monitoring.doctor.model.Invoice;
import com.diabetes.monitoring.doctor.model.InvoiceDetail;
import com.diabetes.monitoring.doctor.model.LaboratoryRequest;
import com.diabetes.monitoring.doctor.model.MedicalService;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class BillingDAO {

    public List<MedicalService> getActiveServices() {
        List<MedicalService> services = new ArrayList<>();
        String sql = "SELECT service_id, service_name, price, service_type, status "
                + "FROM Medical_Service WHERE status = 'Active' ORDER BY service_type, service_name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MedicalService service = new MedicalService();
                service.setServiceId(rs.getInt("service_id"));
                service.setServiceName(rs.getString("service_name"));
                service.setPrice(rs.getBigDecimal("price"));
                service.setServiceType(rs.getString("service_type"));
                service.setStatus(rs.getString("status"));
                services.add(service);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return services;
    }

    public int createMedicalService(MedicalService service) throws SQLException {
        String sql = "INSERT INTO Medical_Service "
                + "(service_name, price, service_type, status) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, service.getServiceName());
            ps.setBigDecimal(2, service.getPrice());
            ps.setString(3, service.getServiceType());
            ps.setString(4, service.getStatus() == null ? "Active" : service.getStatus());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("Khong the tao dich vu y te");
    }

    public int createInvoice(
            int patientId,
            Integer receptionistId,
            int appointmentId,
            Map<Integer, Integer> serviceQuantities,
            BigDecimal insuranceDeduction,
            String paymentMethod) throws SQLException {

        if (serviceQuantities == null || serviceQuantities.isEmpty()) {
            throw new SQLException("Hoa don phai co it nhat mot dich vu");
        }

        String appointmentSql = "SELECT patient_id FROM Appointment WHERE appointment_id = ?";
        String serviceSql = "SELECT service_id, price FROM Medical_Service "
                + "WHERE status = 'Active' AND service_id IN ("
                + placeholders(serviceQuantities.size()) + ")";
        String invoiceSql = "INSERT INTO Invoice "
                + "(patient_id, receptionist_id, "
                + "final_amount, payment_method, status, created_at) "
                + "VALUES (?, ?, ?, ?, 'Pending', GETDATE())";
        String detailSql = "INSERT INTO Invoice_Detail "
                + "(invoice_id, service_id, appointment_id, quantity, price) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                validateAppointmentPatient(conn, appointmentSql, appointmentId, patientId);
                Map<Integer, BigDecimal> servicePrices =
                        loadServicePrices(conn, serviceSql, serviceQuantities);

                BigDecimal total = BigDecimal.ZERO;
                for (Map.Entry<Integer, Integer> entry : serviceQuantities.entrySet()) {
                    int quantity = entry.getValue() == null ? 0 : entry.getValue();
                    if (quantity <= 0) {
                        throw new SQLException("So luong dich vu khong hop le");
                    }
                    total = total.add(
                            servicePrices.get(entry.getKey())
                                    .multiply(BigDecimal.valueOf(quantity))
                    );
                }

                BigDecimal finalAmount = total;

                int invoiceId;
                try (PreparedStatement ps = conn.prepareStatement(
                        invoiceSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, patientId);
                    if (receptionistId == null) {
                        ps.setNull(2, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(2, receptionistId);
                    }
                    ps.setBigDecimal(3, finalAmount);
                    ps.setString(4, paymentMethod);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Khong lay duoc invoice_id");
                        }
                        invoiceId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(detailSql)) {
                    for (Map.Entry<Integer, Integer> entry : serviceQuantities.entrySet()) {
                        ps.setInt(1, invoiceId);
                        ps.setInt(2, entry.getKey());
                        ps.setInt(3, appointmentId);
                        ps.setInt(4, entry.getValue());
                        ps.setBigDecimal(5, servicePrices.get(entry.getKey()));
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                conn.commit();
                return invoiceId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public boolean markInvoicePaid(int invoiceId, String paymentMethod) {
        String invoiceSql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                + "receptionist_id = COALESCE(receptionist_id, ?) "
                + "WHERE invoice_id = ? AND status IN ('Pending', 'Paid')";
        String detailSql = "UPDATE Invoice_Detail SET lab_status = 'Requested' "
                + "WHERE invoice_id = ? AND lab_status = 'Waiting_Payment'";
        return markInvoicePaid(invoiceId, paymentMethod, null, invoiceSql, detailSql);
    }

    public boolean markLaboratoryInvoicePaid(
            int invoiceId, String paymentMethod, int receptionistId) {
        String invoiceSql = "UPDATE Invoice SET status = 'Paid', payment_method = ?, "
                + "receptionist_id = ? WHERE invoice_id = ? "
                + "AND status IN ('Pending', 'Paid')";
        String detailSql = "UPDATE Invoice_Detail SET lab_status = 'Requested' "
                + "WHERE invoice_id = ? AND lab_status = 'Waiting_Payment'";
        return markInvoicePaid(
                invoiceId, paymentMethod, receptionistId, invoiceSql, detailSql);
    }

    private boolean markInvoicePaid(
            int invoiceId, String paymentMethod, Integer receptionistId,
            String invoiceSql, String detailSql) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement invoice = conn.prepareStatement(invoiceSql);
                 PreparedStatement detail = conn.prepareStatement(detailSql)) {
                invoice.setString(1, paymentMethod);
                if (receptionistId == null) {
                    invoice.setNull(2, java.sql.Types.INTEGER);
                } else {
                    invoice.setInt(2, receptionistId);
                }
                invoice.setInt(3, invoiceId);
                if (invoice.executeUpdate() != 1) {
                    conn.rollback();
                    return false;
                }
                detail.setInt(1, invoiceId);
                detail.executeUpdate();
                conn.commit();
                return true;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<LaboratoryRequest> getPendingLaboratoryPayments() {
        List<LaboratoryRequest> items = new ArrayList<>();
        String sql = "SELECT id.invoice_detail_id, id.invoice_id, id.health_record_id, "
                + "i.patient_id, id.doctor_id, id.service_id, ms.service_name, id.price, "
                + "id.request_note, id.lab_status, id.requested_at, i.status AS invoice_status, "
                + "p.full_name AS patient_name "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE id.lab_status = 'Waiting_Payment' AND i.status = 'Pending' "
                + "ORDER BY id.requested_at ASC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                LaboratoryRequest item = new LaboratoryRequest();
                item.setLaboratoryRequestId(rs.getInt("invoice_detail_id"));
                item.setInvoiceId(rs.getInt("invoice_id"));
                item.setInvoiceStatus(rs.getString("invoice_status"));
                item.setHealthRecordId(rs.getInt("health_record_id"));
                item.setPatientId(rs.getInt("patient_id"));
                item.setPatientName(rs.getString("patient_name"));
                item.setDoctorId(rs.getInt("doctor_id"));
                item.setServiceId((Integer) rs.getObject("service_id"));
                item.setTestType(rs.getString("service_name"));
                item.setTestPrice(rs.getBigDecimal("price"));
                item.setRequestNote(rs.getString("request_note"));
                item.setStatus(rs.getString("lab_status"));
                item.setRequestedAt(rs.getTimestamp("requested_at"));
                items.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return items;
    }

    public boolean markInvoiceExported(int invoiceId) {
        String sql = "UPDATE Invoice SET exported_at = GETDATE() "
                + "WHERE invoice_id = ? AND status = 'Paid'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Invoice getInvoiceById(int invoiceId) {
        String sql = "SELECT i.*, p.full_name AS patient_name "
                + "FROM Invoice i JOIN Patient p ON i.patient_id = p.patient_id "
                + "WHERE i.invoice_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Invoice invoice = new Invoice();
                    invoice.setInvoiceId(rs.getInt("invoice_id"));
                    invoice.setPatientId(rs.getInt("patient_id"));
                    invoice.setPatientName(rs.getString("patient_name"));
                    int receptionistId = rs.getInt("receptionist_id");
                    invoice.setReceptionistId(rs.wasNull() ? null : receptionistId);
                    invoice.setTotalAmount(rs.getBigDecimal("final_amount"));
                    invoice.setInsuranceDeduction(BigDecimal.ZERO);
                    invoice.setFinalAmount(rs.getBigDecimal("final_amount"));
                    invoice.setPaymentMethod(rs.getString("payment_method"));
                    invoice.setStatus(rs.getString("status"));
                    invoice.setCreatedAt(rs.getTimestamp("created_at"));
                    invoice.setExportedAt(rs.getTimestamp("exported_at"));
                    return invoice;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<InvoiceDetail> getInvoiceDetails(int invoiceId) {
        List<InvoiceDetail> details = new ArrayList<>();
        String sql = "SELECT id.*, ms.service_name "
                + "FROM Invoice_Detail id "
                + "JOIN Medical_Service ms ON id.service_id = ms.service_id "
                + "WHERE id.invoice_id = ? ORDER BY id.invoice_detail_id";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    InvoiceDetail detail = new InvoiceDetail();
                    detail.setInvoiceDetailId(rs.getInt("invoice_detail_id"));
                    detail.setInvoiceId(rs.getInt("invoice_id"));
                    detail.setServiceId(rs.getInt("service_id"));
                    detail.setServiceName(rs.getString("service_name"));
                    detail.setAppointmentId(rs.getInt("appointment_id"));
                    detail.setQuantity(rs.getInt("quantity"));
                    detail.setPrice(rs.getBigDecimal("price"));
                    details.add(detail);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return details;
    }

    private void validateAppointmentPatient(
            Connection conn,
            String sql,
            int appointmentId,
            int patientId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getInt("patient_id") != patientId) {
                    throw new SQLException("Lich hen khong thuoc benh nhan");
                }
            }
        }
    }

    private Map<Integer, BigDecimal> loadServicePrices(
            Connection conn,
            String sql,
            Map<Integer, Integer> serviceQuantities) throws SQLException {
        Map<Integer, BigDecimal> prices = new LinkedHashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int index = 1;
            for (Integer serviceId : serviceQuantities.keySet()) {
                ps.setInt(index++, serviceId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    prices.put(rs.getInt("service_id"), rs.getBigDecimal("price"));
                }
            }
        }
        if (prices.size() != serviceQuantities.size()) {
            throw new SQLException("Co dich vu khong ton tai hoac da ngung ap dung");
        }
        return prices;
    }

    private String placeholders(int count) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < count; i++) {
            if (i > 0) {
                builder.append(',');
            }
            builder.append('?');
        }
        return builder.toString();
    }
}
