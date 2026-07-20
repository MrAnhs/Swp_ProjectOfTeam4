package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.RecordSharing;
import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RecordSharingDAO {

    public List<RecordSharing> findByViewerAccountId(int viewerAccountId) throws SQLException {
        String sql = "SELECT rs.SharingID, rs.Owner_AccountID, rs.Viewer_AccountID, rs.Initiator_AccountID, "
                + "rs.CanViewAppointments, rs.CanViewInvoices, rs.CanViewRecords, rs.Status, "
                + "rs.CreatedAt, rs.UpdatedAt, "
                + "o.full_name AS owner_name, o.email AS owner_email, "
                + "v.full_name AS viewer_name, v.email AS viewer_email, "
                + "i.full_name AS initiator_name, i.email AS initiator_email, "
                + "p.patient_id AS owner_patient_id "
                + "FROM Record_Sharing rs "
                + "JOIN Account o ON o.account_id = rs.Owner_AccountID "
                + "JOIN Account v ON v.account_id = rs.Viewer_AccountID "
                + "JOIN Account i ON i.account_id = rs.Initiator_AccountID "
                + "LEFT JOIN Patient p ON p.account_id = rs.Owner_AccountID "
                + "WHERE rs.Viewer_AccountID = ? "
                + "ORDER BY rs.CreatedAt DESC";

        List<RecordSharing> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viewerAccountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRecordSharing(rs));
                }
            }
        }
        return list;
    }

    public List<RecordSharing> findByOwnerAccountId(int ownerAccountId) throws SQLException {
        String sql = "SELECT rs.SharingID, rs.Owner_AccountID, rs.Viewer_AccountID, rs.Initiator_AccountID, "
                + "rs.CanViewAppointments, rs.CanViewInvoices, rs.CanViewRecords, rs.Status, "
                + "rs.CreatedAt, rs.UpdatedAt, "
                + "o.full_name AS owner_name, o.email AS owner_email, "
                + "v.full_name AS viewer_name, v.email AS viewer_email, "
                + "i.full_name AS initiator_name, i.email AS initiator_email, "
                + "p.patient_id AS owner_patient_id "
                + "FROM Record_Sharing rs "
                + "JOIN Account o ON o.account_id = rs.Owner_AccountID "
                + "JOIN Account v ON v.account_id = rs.Viewer_AccountID "
                + "JOIN Account i ON i.account_id = rs.Initiator_AccountID "
                + "LEFT JOIN Patient p ON p.account_id = rs.Owner_AccountID "
                + "WHERE rs.Owner_AccountID = ? "
                + "ORDER BY rs.CreatedAt DESC";

        List<RecordSharing> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerAccountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRecordSharing(rs));
                }
            }
        }
        return list;
    }

    public Map<String, Object> findAccountByEmail(String email) throws SQLException {
        String sql = "SELECT account_id, full_name, email, role FROM Account WHERE LOWER(email) = LOWER(?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("accountId", rs.getInt("account_id"));
                    map.put("fullName", rs.getString("full_name"));
                    map.put("email", rs.getString("email"));
                    map.put("role", rs.getString("role"));
                    return map;
                }
            }
        }
        return null;
    }

    public boolean existsSharing(int ownerAccountId, int viewerAccountId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Record_Sharing WHERE Owner_AccountID = ? AND Viewer_AccountID = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerAccountId);
            ps.setInt(2, viewerAccountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    public RecordSharing getSharingById(int sharingId) throws SQLException {
        String sql = "SELECT rs.SharingID, rs.Owner_AccountID, rs.Viewer_AccountID, rs.Initiator_AccountID, "
                + "rs.CanViewAppointments, rs.CanViewInvoices, rs.CanViewRecords, rs.Status, "
                + "rs.CreatedAt, rs.UpdatedAt, "
                + "o.full_name AS owner_name, o.email AS owner_email, "
                + "v.full_name AS viewer_name, v.email AS viewer_email, "
                + "i.full_name AS initiator_name, i.email AS initiator_email, "
                + "p.patient_id AS owner_patient_id "
                + "FROM Record_Sharing rs "
                + "JOIN Account o ON o.account_id = rs.Owner_AccountID "
                + "JOIN Account v ON v.account_id = rs.Viewer_AccountID "
                + "JOIN Account i ON i.account_id = rs.Initiator_AccountID "
                + "LEFT JOIN Patient p ON p.account_id = rs.Owner_AccountID "
                + "WHERE rs.SharingID = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, sharingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRecordSharing(rs);
                }
            }
        }
        return null;
    }

    public boolean createSharing(int ownerAccountId, int viewerAccountId, int initiatorAccountId,
                                 boolean canViewAppointments, boolean canViewInvoices, boolean canViewRecords)
            throws SQLException {
        String sql = "INSERT INTO Record_Sharing "
                + "(Owner_AccountID, Viewer_AccountID, Initiator_AccountID, "
                + "CanViewAppointments, CanViewInvoices, CanViewRecords, Status, CreatedAt, UpdatedAt) "
                + "VALUES (?, ?, ?, ?, ?, ?, 'PENDING', GETDATE(), GETDATE())";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerAccountId);
            ps.setInt(2, viewerAccountId);
            ps.setInt(3, initiatorAccountId);
            ps.setBoolean(4, canViewAppointments);
            ps.setBoolean(5, canViewInvoices);
            ps.setBoolean(6, canViewRecords);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean updateStatus(int sharingId, String status, int currentUserId) throws SQLException {
        String sql = "UPDATE Record_Sharing SET Status = ?, UpdatedAt = GETDATE() "
                + "WHERE SharingID = ? AND (Owner_AccountID = ? OR Viewer_AccountID = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, sharingId);
            ps.setInt(3, currentUserId);
            ps.setInt(4, currentUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean updatePermissionsAndAccept(int sharingId, boolean canViewAppointments,
                                             boolean canViewInvoices, boolean canViewRecords,
                                             int currentUserId) throws SQLException {
        String sql = "UPDATE Record_Sharing SET Status = 'ACCEPTED', "
                + "CanViewAppointments = ?, CanViewInvoices = ?, CanViewRecords = ?, "
                + "UpdatedAt = GETDATE() "
                + "WHERE SharingID = ? AND Owner_AccountID = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, canViewAppointments);
            ps.setBoolean(2, canViewInvoices);
            ps.setBoolean(3, canViewRecords);
            ps.setInt(4, sharingId);
            ps.setInt(5, currentUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean deleteSharing(int sharingId, int currentUserId) throws SQLException {
        String sql = "DELETE FROM Record_Sharing "
                + "WHERE SharingID = ? AND (Owner_AccountID = ? OR Viewer_AccountID = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, sharingId);
            ps.setInt(2, currentUserId);
            ps.setInt(3, currentUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public RecordSharing getAcceptedSharingWithOwnerInfo(int ownerAccountId, int viewerAccountId) throws SQLException {
        String sql = "SELECT rs.SharingID, rs.Owner_AccountID, rs.Viewer_AccountID, rs.Initiator_AccountID, "
                + "rs.CanViewAppointments, rs.CanViewInvoices, rs.CanViewRecords, rs.Status, "
                + "rs.CreatedAt, rs.UpdatedAt, "
                + "o.full_name AS owner_name, o.email AS owner_email, "
                + "v.full_name AS viewer_name, v.email AS viewer_email, "
                + "i.full_name AS initiator_name, i.email AS initiator_email, "
                + "p.patient_id AS owner_patient_id "
                + "FROM Record_Sharing rs "
                + "JOIN Account o ON o.account_id = rs.Owner_AccountID "
                + "JOIN Account v ON v.account_id = rs.Viewer_AccountID "
                + "JOIN Account i ON i.account_id = rs.Initiator_AccountID "
                + "LEFT JOIN Patient p ON p.account_id = rs.Owner_AccountID "
                + "WHERE rs.Owner_AccountID = ? AND rs.Viewer_AccountID = ? AND rs.Status = 'ACCEPTED'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerAccountId);
            ps.setInt(2, viewerAccountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRecordSharing(rs);
                }
            }
        }
        return null;
    }

    private RecordSharing mapRecordSharing(ResultSet rs) throws SQLException {
        RecordSharing rsObj = new RecordSharing();
        rsObj.setSharingId(rs.getInt("SharingID"));
        rsObj.setOwnerAccountId(rs.getInt("Owner_AccountID"));
        rsObj.setViewerAccountId(rs.getInt("Viewer_AccountID"));
        rsObj.setInitiatorAccountId(rs.getInt("Initiator_AccountID"));
        rsObj.setCanViewAppointments(rs.getBoolean("CanViewAppointments"));
        rsObj.setCanViewInvoices(rs.getBoolean("CanViewInvoices"));
        rsObj.setCanViewRecords(rs.getBoolean("CanViewRecords"));
        rsObj.setStatus(rs.getString("Status"));
        rsObj.setCreatedAt(rs.getTimestamp("CreatedAt"));
        rsObj.setUpdatedAt(rs.getTimestamp("UpdatedAt"));

        rsObj.setOwnerName(rs.getString("owner_name"));
        rsObj.setOwnerEmail(rs.getString("owner_email"));
        rsObj.setViewerName(rs.getString("viewer_name"));
        rsObj.setViewerEmail(rs.getString("viewer_email"));
        rsObj.setInitiatorName(rs.getString("initiator_name"));
        rsObj.setInitiatorEmail(rs.getString("initiator_email"));

        int patientIdVal = rs.getInt("owner_patient_id");
        rsObj.setOwnerPatientId(rs.wasNull() ? null : patientIdVal);
        return rsObj;
    }
}
