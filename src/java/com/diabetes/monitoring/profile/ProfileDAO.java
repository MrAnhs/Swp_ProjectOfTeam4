package com.diabetes.monitoring.profile;

import com.diabetes.monitoring.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/** JDBC access for the account profile aggregate. */
public class ProfileDAO {
    public Profile findByAccountId(int accountId, String role) throws SQLException {
        String normalizedRole = normalizeRole(role);
        String detailTable = detailTable(normalizedRole);
        String detailColumns = detailColumns(normalizedRole);
        String sql = "SELECT a.account_id, a.role, a.full_name AS account_name, a.email AS account_email, "
                + "a.created_at, " + detailColumns + " FROM Account a LEFT JOIN " + detailTable
                + " d ON d.account_id = a.account_id WHERE a.account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? map(rs, normalizedRole) : null;
            }
        }
    }

    public boolean emailExistsForOtherAccount(Connection connection, String email, int accountId)
            throws SQLException {
        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?) AND account_id <> ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            statement.setInt(2, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    public boolean phoneExistsForOtherAccount(Connection connection, String phone, int accountId)
            throws SQLException {
        String sql = "SELECT COUNT(*) FROM ("
                + "SELECT account_id, phone FROM Patient WHERE phone IS NOT NULL "
                + "UNION ALL SELECT account_id, phone FROM Doctor WHERE phone IS NOT NULL "
                + "UNION ALL SELECT account_id, phone FROM Doctor_Lab WHERE phone IS NOT NULL "
                + "UNION ALL SELECT account_id, phone FROM Reception WHERE phone IS NOT NULL"
                + ") p WHERE p.phone = ? AND p.account_id <> ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, phone);
            statement.setInt(2, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    public void update(Connection connection, Profile profile) throws SQLException {
        String role = normalizeRole(profile.getRole());
        String table = detailTable(role);
        String sqlAccount = "UPDATE Account SET full_name = ? WHERE account_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sqlAccount)) {
            statement.setString(1, profile.getFullName());
            statement.setInt(2, profile.getAccountId());
            if (statement.executeUpdate() == 0) throw new SQLException("Tài khoản không tồn tại");
        }

        String sql = detailUpdateSql(role, table);
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            int i = 1;
            statement.setString(i++, profile.getFullName());
            statement.setString(i++, profile.getPhone());
            if (supportsBirthDetails(role)) {
                setDate(statement, i++, profile.getDateOfBirth());
                statement.setString(i++, profile.getGender());
                statement.setString(i++, profile.getAddress());
            }
            statement.setInt(i, profile.getAccountId());
            if (statement.executeUpdate() == 0) throw new SQLException("Hồ sơ role không tồn tại");
        }
    }

    public void updateEmail(Connection connection, int accountId, String email) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("UPDATE Account SET email = ? WHERE account_id = ?")) {
            statement.setString(1, email);
            statement.setInt(2, accountId);
            if (statement.executeUpdate() == 0) throw new SQLException("Tài khoản không tồn tại");
        }
        String table = detailTableForAccount(connection, accountId);
        try (PreparedStatement statement = connection.prepareStatement("UPDATE " + table + " SET email = ? WHERE account_id = ?")) {
            statement.setString(1, email);
            statement.setInt(2, accountId);
            if (statement.executeUpdate() == 0) throw new SQLException("Hồ sơ role không tồn tại");
        }
    }

    public String findPasswordHash(Connection connection, int accountId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT password_hash FROM Account WHERE account_id = ?")) {
            statement.setInt(1, accountId);
            try (ResultSet rs = statement.executeQuery()) { return rs.next() ? rs.getString(1) : null; }
        }
    }

    public void updatePassword(Connection connection, int accountId, String passwordHash) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("UPDATE Account SET password_hash = ? WHERE account_id = ?")) {
            statement.setString(1, passwordHash);
            statement.setInt(2, accountId);
            if (statement.executeUpdate() == 0) throw new SQLException("Tài khoản không tồn tại");
        }
    }

    private Profile map(ResultSet rs, String role) throws SQLException {
        Profile profile = new Profile();
        profile.setAccountId(rs.getInt("account_id"));
        profile.setRole(rs.getString("role"));
        profile.setFullName(value(rs, "account_name", "full_name"));
        profile.setEmail(value(rs, "account_email", "email"));
        profile.setCreatedAt(rs.getTimestamp("created_at"));
        profile.setPhone(value(rs, "phone"));
        if (supportsBirthDetails(role)) {
            Date dob = rs.getDate("date_of_birth");
            profile.setDateOfBirth(dob == null ? "" : dob.toLocalDate().toString());
            profile.setGender(value(rs, "gender"));
            profile.setAddress(value(rs, "address"));
        }
        if ("doctor".equals(role)) profile.setDepartment(value(rs, "department"));
        if ("doctor_lab".equals(role)) profile.setLabName(value(rs, "lab_name"));
        if ("receptionist".equals(role)) profile.setDeskLocation(value(rs, "desk_location"));
        return profile;
    }

    private String detailTable(String role) {
        switch (role) {
            case "patient": return "Patient";
            case "doctor": return "Doctor";
            case "doctor_lab": return "Doctor_Lab";
            case "receptionist": return "Reception";
            default: throw new IllegalArgumentException("Role không được phép dùng profile");
        }
    }

    private String detailTableForAccount(Connection connection, int accountId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT role FROM Account WHERE account_id = ?")) {
            statement.setInt(1, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) throw new SQLException("Tài khoản không tồn tại");
                return detailTable(normalizeRole(rs.getString(1)));
            }
        }
    }

    private String detailColumns(String role) {
        String common = "d.full_name, d.email, d.phone";
        if (supportsBirthDetails(role)) return common + ", d.date_of_birth, d.gender, d.address";
        return common;
    }

    private String detailUpdateSql(String role, String table) {
        if (supportsBirthDetails(role)) {
            return "UPDATE " + table + " SET full_name = ?, phone = ?, date_of_birth = ?, gender = ?, address = ? WHERE account_id = ?";
        }
        return "UPDATE " + table + " SET full_name = ?, phone = ? WHERE account_id = ?";
    }

    private boolean supportsBirthDetails(String role) {
        return "patient".equals(role) || "doctor".equals(role) || "doctor_lab".equals(role)
                || "receptionist".equals(role);
    }

    private String normalizeRole(String role) {
        if (role == null) throw new IllegalArgumentException("Role không hợp lệ");
        return role.trim().replace('-', '_').replace(' ', '_').toLowerCase();
    }

    private String value(ResultSet rs, String... columns) throws SQLException {
        for (String column : columns) {
            try { return rs.getString(column) == null ? "" : rs.getString(column); }
            catch (SQLException ignored) { }
        }
        return "";
    }

    private void setDate(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null || value.isBlank()) statement.setNull(index, java.sql.Types.DATE);
        else statement.setDate(index, Date.valueOf(value));
    }
}
