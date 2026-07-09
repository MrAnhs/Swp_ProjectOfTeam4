package com.diabetes.monitoring.doctorlab;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class DoctorLabDAO {

    public List<LabRequest> findRequests(String status) {
        synchronizePaidRequests();
        List<LabRequest> requests = new ArrayList<>();
        boolean hasStatus = status != null && !status.trim().isEmpty()
                && !"All".equalsIgnoreCase(status);

        String sql = "SELECT id.invoice_detail_id, id.invoice_id, id.health_record_id, "
                + "id.price, id.request_note, id.lab_status, id.lab_result, "
                + "id.requested_at, id.completed_at, i.status AS invoice_status, "
                + "i.patient_id, p.full_name AS patient_name, ms.service_name, "
                + "hr.urea, hr.cr, hr.hba1c, hr.chol, hr.tg, hr.hdl, hr.ldl, "
                + "hr.vldl, hr.bmi, hr.weight, hr.height "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "JOIN Healthy_Record hr ON hr.health_record_id = id.health_record_id "
                + "LEFT JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE id.lab_status IS NOT NULL AND i.status = 'Paid' "
                + (hasStatus ? "AND id.lab_status = ? " : "")
                + "ORDER BY CASE id.lab_status "
                + "WHEN 'Requested' THEN 1 WHEN 'Processing' THEN 2 "
                + "WHEN 'Completed' THEN 3 ELSE 4 END, id.requested_at ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (hasStatus) {
                ps.setString(1, status);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    requests.add(mapRequest(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return requests;
    }

    public Map<String, Integer> getStatusCounts() {
        synchronizePaidRequests();
        Map<String, Integer> counts = new LinkedHashMap<>();
        counts.put("total", 0);
        counts.put("requested", 0);
        counts.put("processing", 0);
        counts.put("completed", 0);

        String sql = "SELECT id.lab_status, COUNT(*) AS total "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "WHERE id.lab_status IS NOT NULL AND i.status = 'Paid' "
                + "GROUP BY id.lab_status";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String status = rs.getString("lab_status");
                int total = rs.getInt("total");
                counts.put("total", counts.get("total") + total);
                if ("Requested".equals(status)) {
                    counts.put("requested", total);
                } else if ("Processing".equals(status)) {
                    counts.put("processing", total);
                } else if ("Completed".equals(status)) {
                    counts.put("completed", total);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return counts;
    }

    public LabRequest findByInvoiceDetailId(int invoiceDetailId) {
        String sql = "SELECT id.invoice_detail_id, id.invoice_id, id.health_record_id, "
                + "id.price, id.request_note, id.lab_status, id.lab_result, "
                + "id.requested_at, id.completed_at, i.status AS invoice_status, "
                + "i.patient_id, p.full_name AS patient_name, ms.service_name, "
                + "hr.urea, hr.cr, hr.hba1c, hr.chol, hr.tg, hr.hdl, hr.ldl, "
                + "hr.vldl, hr.bmi, hr.weight, hr.height "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "JOIN Medical_Service ms ON ms.service_id = id.service_id "
                + "JOIN Healthy_Record hr ON hr.health_record_id = id.health_record_id "
                + "LEFT JOIN Patient p ON p.patient_id = i.patient_id "
                + "WHERE id.invoice_detail_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invoiceDetailId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRequest(rs) : null;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    public boolean startProcessing(int invoiceDetailId) {
        String sql = "UPDATE id SET lab_status = 'Processing' "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "WHERE id.invoice_detail_id = ? "
                + "AND id.lab_status = 'Requested' "
                + "AND i.status = 'Paid'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invoiceDetailId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public void completeRequest(LabRequest result) throws SQLException {
        String lockSql = "SELECT id.health_record_id, id.lab_status, i.status AS invoice_status "
                + "FROM Invoice_Detail id WITH (UPDLOCK, ROWLOCK) "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "WHERE id.invoice_detail_id = ?";
        String updateDetailSql = "UPDATE Invoice_Detail SET lab_status = 'Completed', "
                + "lab_result = ?, completed_at = GETDATE() "
                + "WHERE invoice_detail_id = ? AND lab_status = 'Processing'";
        String updateHealthSql = "UPDATE Healthy_Record SET "
                + "urea = COALESCE(?, urea), cr = COALESCE(?, cr), "
                + "hba1c = COALESCE(?, hba1c), chol = COALESCE(?, chol), "
                + "tg = COALESCE(?, tg), hdl = COALESCE(?, hdl), "
                + "ldl = COALESCE(?, ldl), vldl = COALESCE(?, vldl), "
                + "bmi = COALESCE(?, bmi), weight = COALESCE(?, weight), "
                + "height = COALESCE(?, height), synced_at = GETDATE(), "
                + "status = CASE WHEN status IN ('AI_Processed','Editing','Completed') "
                + "THEN status ELSE 'Accepted' END "
                + "WHERE health_record_id = ?";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int healthRecordId;
                try (PreparedStatement ps = conn.prepareStatement(lockSql)) {
                    ps.setInt(1, result.getInvoiceDetailId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException("Không tìm thấy yêu cầu xét nghiệm.");
                        }
                        if (!"Paid".equalsIgnoreCase(rs.getString("invoice_status"))) {
                            throw new SQLException("Hóa đơn xét nghiệm chưa được thanh toán.");
                        }
                        if (!"Processing".equalsIgnoreCase(rs.getString("lab_status"))) {
                            throw new SQLException("Yêu cầu xét nghiệm chưa ở trạng thái đang xử lý.");
                        }
                        healthRecordId = rs.getInt("health_record_id");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(updateDetailSql)) {
                    ps.setString(1, result.getLabResult());
                    ps.setInt(2, result.getInvoiceDetailId());
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Không thể cập nhật trạng thái xét nghiệm.");
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(updateHealthSql)) {
                    setNullable(ps, 1, result.getUrea());
                    setNullable(ps, 2, result.getCr());
                    setNullable(ps, 3, result.getHba1c());
                    setNullable(ps, 4, result.getChol());
                    setNullable(ps, 5, result.getTg());
                    setNullable(ps, 6, result.getHdl());
                    setNullable(ps, 7, result.getLdl());
                    setNullable(ps, 8, result.getVldl());
                    setNullable(ps, 9, result.getBmi());
                    setNullable(ps, 10, result.getWeight());
                    setNullable(ps, 11, result.getHeight());
                    ps.setInt(12, healthRecordId);
                    if (ps.executeUpdate() != 1) {
                        throw new SQLException("Không thể đồng bộ kết quả vào hồ sơ sức khỏe.");
                    }
                }

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void synchronizePaidRequests() {
        String sql = "UPDATE id SET id.lab_status = 'Requested' "
                + "FROM Invoice_Detail id "
                + "JOIN Invoice i ON i.invoice_id = id.invoice_id "
                + "WHERE i.status = 'Paid' AND id.lab_status = 'Waiting_Payment'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private LabRequest mapRequest(ResultSet rs) throws SQLException {
        LabRequest item = new LabRequest();
        item.setInvoiceDetailId(rs.getInt("invoice_detail_id"));
        item.setInvoiceId(rs.getInt("invoice_id"));
        item.setHealthRecordId(rs.getInt("health_record_id"));
        item.setPatientId(rs.getInt("patient_id"));
        item.setPatientName(rs.getString("patient_name"));
        item.setServiceName(rs.getString("service_name"));
        item.setPrice(rs.getBigDecimal("price"));
        item.setRequestNote(rs.getString("request_note"));
        item.setLabStatus(rs.getString("lab_status"));
        item.setInvoiceStatus(rs.getString("invoice_status"));
        item.setLabResult(rs.getString("lab_result"));
        item.setRequestedAt(rs.getTimestamp("requested_at"));
        item.setCompletedAt(rs.getTimestamp("completed_at"));
        item.setUrea(nullableDouble(rs, "urea"));
        item.setCr(nullableDouble(rs, "cr"));
        item.setHba1c(nullableDouble(rs, "hba1c"));
        item.setChol(nullableDouble(rs, "chol"));
        item.setTg(nullableDouble(rs, "tg"));
        item.setHdl(nullableDouble(rs, "hdl"));
        item.setLdl(nullableDouble(rs, "ldl"));
        item.setVldl(nullableDouble(rs, "vldl"));
        item.setBmi(nullableDouble(rs, "bmi"));
        item.setWeight(nullableDouble(rs, "weight"));
        item.setHeight(nullableDouble(rs, "height"));
        return item;
    }

    private Double nullableDouble(ResultSet rs, String column) throws SQLException {
        double value = rs.getDouble(column);
        return rs.wasNull() ? null : value;
    }

    private void setNullable(PreparedStatement ps, int index, Double value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.DECIMAL);
        } else {
            ps.setDouble(index, value);
        }
    }
}
