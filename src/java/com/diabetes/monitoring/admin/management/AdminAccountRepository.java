package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Repository for Admin account management operations.
 */
public class AdminAccountRepository {
    private static final Logger LOGGER = Logger.getLogger(AdminAccountRepository.class.getName());
    private static final Set<String> ALLOWED_ROLES = new HashSet<>();
    private static final Set<String> ALLOWED_ACCOUNT_STATUS = new HashSet<>();

    static {
        ALLOWED_ROLES.add("patient");
        ALLOWED_ROLES.add("doctor");
        ALLOWED_ROLES.add("doctor_lab");
        ALLOWED_ROLES.add("receptionist");
        ALLOWED_ROLES.add("admin");

        ALLOWED_ACCOUNT_STATUS.add("active");
        ALLOWED_ACCOUNT_STATUS.add("locked");
    }

    public int getCountTotalAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account");
    }

    public int getCountActiveAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'active'");
    }

    public int getCountLockedAccounts() {
        return executeCount("SELECT COUNT(*) FROM Account WHERE LOWER(status) = 'locked'");
    }

    public int getAccountsTotalCount(String search, String role, String status) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Account WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (full_name LIKE ? OR email LIKE ?)");
            params.add("%" + search.trim() + "%");
            params.add("%" + search.trim() + "%");
        }

        String normalizedRole = normalizeRole(role);
        if (normalizedRole != null) {
            sql.append(" AND LOWER(role) = ?");
            params.add(normalizedRole.toLowerCase(Locale.ROOT));
        }

        String normalizedStatus = normalizeAccountStatus(status);
        if (normalizedStatus != null) {
            sql.append(" AND LOWER(status) = ?");
            params.add(normalizedStatus.toLowerCase(Locale.ROOT));
        }

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to count admin accounts", e);
        }
        return 0;
    }

    public List<User> getAccounts(String search, String role, String status, int page, int pageSize) {
        List<User> users = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT account_id, full_name, email, role, status, created_at FROM Account WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (full_name LIKE ? OR email LIKE ?)");
            params.add("%" + search.trim() + "%");
            params.add("%" + search.trim() + "%");
        }

        String normalizedRole = normalizeRole(role);
        if (normalizedRole != null) {
            sql.append(" AND LOWER(role) = ?");
            params.add(normalizedRole.toLowerCase(Locale.ROOT));
        }

        String normalizedStatus = normalizeAccountStatus(status);
        if (normalizedStatus != null) {
            sql.append(" AND LOWER(status) = ?");
            params.add(normalizedStatus.toLowerCase(Locale.ROOT));
        }

        sql.append(" ORDER BY created_at DESC, account_id DESC");
        sql.append(" OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        int offset = (Math.max(1, page) - 1) * pageSize;
        params.add(offset);
        params.add(pageSize);

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            bindParams(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    User user = new User();
                    user.setId(rs.getInt("account_id"));
                    user.setFullName(rs.getString("full_name"));
                    user.setEmail(rs.getString("email"));
                    user.setRole(normalizeRole(rs.getString("role")));
                    user.setStatus(toTitleCase(rs.getString("status")));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    users.add(user);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to get admin account list", e);
        }
        return users;
    }

    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        return createAccount(fullName, email, passwordHash, role, status, null);
    }

    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status, String specialization) {
        String normalizedRole = normalizeRole(role);
        String normalizedStatus = normalizeAccountStatus(status);

        if (normalizedRole == null || normalizedStatus == null) {
            return false;
        }

        if (isAccountEmailExists(email)) {
            return false;
        }

        String sql = "INSERT INTO Account (full_name, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?)";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, fullName);
            statement.setString(2, email);
            statement.setString(3, passwordHash);
            statement.setString(4, normalizedRole);
            statement.setString(5, normalizedStatus);
            int affected = statement.executeUpdate();
            if (affected > 0) {
                int newAccountId = -1;
                try (ResultSet rs = statement.getGeneratedKeys()) {
                    if (rs.next()) {
                        newAccountId = rs.getInt(1);
                    }
                }

                if ("Doctor".equalsIgnoreCase(normalizedRole) || "doctor_lab".equalsIgnoreCase(normalizedRole)) {
                    String spec = (specialization != null && !specialization.isBlank()) 
                                    ? specialization.trim() 
                                    : ("doctor_lab".equalsIgnoreCase(normalizedRole) ? "Xét nghiệm" : "Nội tiết");
                    String sqlDoctor = "INSERT INTO Doctor (full_name, email, department, account_id) VALUES (?, ?, ?, ?)";
                    try (PreparedStatement psDoc = connection.prepareStatement(sqlDoctor)) {
                        psDoc.setString(1, fullName);
                        psDoc.setString(2, email);
                        psDoc.setString(3, spec);
                        psDoc.setInt(4, newAccountId);
                        psDoc.executeUpdate();
                    } catch (SQLException exDoc) {
                        LOGGER.log(Level.WARNING, "Failed to insert Doctor row for new account: " + newAccountId, exDoc);
                    }
                }
                return true;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to create account", e);
        }
        return false;
    }

    public boolean isAccountEmailExists(String email) {
        if (email == null || email.isBlank()) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?)";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email.trim());
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to check duplicate account email", e);
            return false;
        }
    }

    public boolean updateAccountRole(int accountId, String role) {
        String normalizedRole = normalizeRole(role);
        if (normalizedRole == null) {
            return false;
        }

        String sql = "UPDATE Account SET role = ? WHERE account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, normalizedRole);
            statement.setInt(2, accountId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account role", e);
            return false;
        }
    }

    public boolean updateAccountStatus(int accountId, String status) {
        String normalizedStatus = normalizeAccountStatus(status);
        if (normalizedStatus == null) {
            return false;
        }

        String sql = "UPDATE Account SET status = ? WHERE account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, normalizedStatus);
            statement.setInt(2, accountId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account status", e);
            return false;
        }
    }

    public boolean deleteAccountForAdmin(int accountId) {
        if (accountId <= 0) {
            return false;
        }
        // Soft delete: Cập nhật trạng thái của tài khoản sang 'locked' để bảo toàn dữ liệu lịch sử.
        return updateAccountStatus(accountId, "locked");
    }

    public Map<String, Object> getAccountProfileForAdminEdit(int accountId) {
        Map<String, Object> profile = new HashMap<>();
        String sqlAccount = "SELECT account_id, full_name, email, role FROM Account WHERE account_id = ?";

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement accountStmt = connection.prepareStatement(sqlAccount)) {
            accountStmt.setInt(1, accountId);
            try (ResultSet accountRs = accountStmt.executeQuery()) {
                if (!accountRs.next()) {
                    return profile;
                }

                String role = normalizeRole(accountRs.getString("role"));
                profile.put("accountId", accountRs.getInt("account_id"));
                profile.put("fullName", accountRs.getString("full_name"));
                profile.put("email", accountRs.getString("email"));
                profile.put("role", role);
                profile.put("phone", "");
                profile.put("address", "");
                profile.put("department", "");

                if ("Patient".equals(role)) {
                    String sqlPatient = "SELECT TOP 1 phone, address FROM Patient WHERE account_id = ? OR patient_id = ?";
                    try (PreparedStatement patientStmt = connection.prepareStatement(sqlPatient)) {
                        patientStmt.setInt(1, accountId);
                        patientStmt.setInt(2, accountId);
                        try (ResultSet patientRs = patientStmt.executeQuery()) {
                            if (patientRs.next()) {
                                profile.put("phone", patientRs.getString("phone"));
                                profile.put("address", patientRs.getString("address"));
                            }
                        }
                    }
                } else if ("Doctor".equals(role)) {
                    String sqlDoctor = "SELECT TOP 1 phone, department FROM Doctor WHERE account_id = ? OR doctor_id = ?";
                    try (PreparedStatement doctorStmt = connection.prepareStatement(sqlDoctor)) {
                        doctorStmt.setInt(1, accountId);
                        doctorStmt.setInt(2, accountId);
                        try (ResultSet doctorRs = doctorStmt.executeQuery()) {
                            if (doctorRs.next()) {
                                profile.put("phone", doctorRs.getString("phone"));
                                profile.put("department", normalizeDepartmentForAi(doctorRs.getString("department")));
                            }
                        }
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load account profile for admin edit", e);
            profile.clear();
        }

        return profile;
    }

    public boolean updateAccountProfileByRole(int accountId,
            String fullName,
            String email,
            String phone,
            String address,
            String department) {
        if (accountId <= 0 || fullName == null || fullName.isBlank() || email == null || email.isBlank()) {
            return false;
        }

        if (isAccountEmailExistsForOtherAccount(email, accountId)) {
            return false;
        }

        String sqlGetRole = "SELECT role FROM Account WHERE account_id = ?";
        String sqlUpdateAccount = "UPDATE Account SET full_name = ?, email = ? WHERE account_id = ?";
        String sqlUpdatePatientByAccount = "UPDATE Patient SET full_name = ?, email = ?, phone = ?, address = ? WHERE account_id = ?";
        String sqlUpdatePatientById = "UPDATE Patient SET full_name = ?, email = ?, phone = ?, address = ? WHERE patient_id = ?";
        String sqlUpdateDoctorByAccount = "UPDATE Doctor SET full_name = ?, email = ?, phone = ?, department = ? WHERE account_id = ?";
        String sqlUpdateDoctorById = "UPDATE Doctor SET full_name = ?, email = ?, phone = ?, department = ? WHERE doctor_id = ?";

        String cleanName = fullName.trim();
        String cleanEmail = email.trim();
        String cleanPhone = phone == null ? "" : phone.trim();
        String cleanAddress = address == null ? "" : address.trim();
        String normalizedDepartment = normalizeDepartmentForAi(department);

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                String role;
                try (PreparedStatement roleStmt = connection.prepareStatement(sqlGetRole)) {
                    roleStmt.setInt(1, accountId);
                    try (ResultSet rs = roleStmt.executeQuery()) {
                        if (!rs.next()) {
                            connection.rollback();
                            return false;
                        }
                        role = normalizeRole(rs.getString("role"));
                    }
                }

                try (PreparedStatement accountStmt = connection.prepareStatement(sqlUpdateAccount)) {
                    accountStmt.setString(1, cleanName);
                    accountStmt.setString(2, cleanEmail);
                    accountStmt.setInt(3, accountId);
                    if (accountStmt.executeUpdate() <= 0) {
                        connection.rollback();
                        return false;
                    }
                }

                if ("Patient".equals(role)) {
                    int updated;
                    try (PreparedStatement patientStmt = connection.prepareStatement(sqlUpdatePatientByAccount)) {
                        patientStmt.setString(1, cleanName);
                        patientStmt.setString(2, cleanEmail);
                        patientStmt.setString(3, cleanPhone);
                        patientStmt.setString(4, cleanAddress);
                        patientStmt.setInt(5, accountId);
                        updated = patientStmt.executeUpdate();
                    }
                    if (updated <= 0) {
                        try (PreparedStatement patientStmt = connection.prepareStatement(sqlUpdatePatientById)) {
                            patientStmt.setString(1, cleanName);
                            patientStmt.setString(2, cleanEmail);
                            patientStmt.setString(3, cleanPhone);
                            patientStmt.setString(4, cleanAddress);
                            patientStmt.setInt(5, accountId);
                            patientStmt.executeUpdate();
                        }
                    }
                } else if ("Doctor".equals(role)) {
                    int updated;
                    try (PreparedStatement doctorStmt = connection.prepareStatement(sqlUpdateDoctorByAccount)) {
                        doctorStmt.setString(1, cleanName);
                        doctorStmt.setString(2, cleanEmail);
                        doctorStmt.setString(3, cleanPhone);
                        doctorStmt.setString(4, normalizedDepartment);
                        doctorStmt.setInt(5, accountId);
                        updated = doctorStmt.executeUpdate();
                    }
                    if (updated <= 0) {
                        try (PreparedStatement doctorStmt = connection.prepareStatement(sqlUpdateDoctorById)) {
                            doctorStmt.setString(1, cleanName);
                            doctorStmt.setString(2, cleanEmail);
                            doctorStmt.setString(3, cleanPhone);
                            doctorStmt.setString(4, normalizedDepartment);
                            doctorStmt.setInt(5, accountId);
                            doctorStmt.executeUpdate();
                        }
                    }
                }

                connection.commit();
                return true;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account profile by role", e);
            return false;
        }
    }

    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        List<Map<String, Object>> rows = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT TOP (?) account_id, full_name, email, role, status, created_at "
                + "FROM Account "
                + "WHERE 1 = 1 "
        );

        String normalizedStatus = normalizeAccountStatus(status);

        if (normalizedStatus != null) {
            sql.append(" AND LOWER(status) = ? ");
        }

        sql.append(" ORDER BY created_at DESC, account_id DESC ");

        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int index = 1;
            statement.setInt(index++, Math.max(limit, 1));

            if (normalizedStatus != null) {
                statement.setString(index, normalizedStatus.toLowerCase(Locale.ROOT));
            }

            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("accountId", rs.getInt("account_id"));
                    row.put("fullName", rs.getString("full_name"));
                    row.put("email", rs.getString("email"));
                    row.put("role", rs.getString("role"));
                    row.put("status", rs.getString("status"));
                    row.put("createdAt", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to load quick accounts", e);
        }

        return rows;
    }

    private int executeCount(String sql) {
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to execute count query", e);
            return 0;
        }
    }

    private String normalizeRole(String role) {
        if (role == null) {
            return null;
        }
        String value = role.trim().toLowerCase(Locale.ROOT);
        if (value.isEmpty() || !ALLOWED_ROLES.contains(value)) {
            return null;
        }
        switch (value) {
            case "patient":
                return "Patient";
            case "doctor":
                return "Doctor";
            case "doctor_lab":
                return "doctor_lab";
            case "receptionist":
                return "Receptionist";
            case "admin":
                return "Admin";
            default:
                return null;
        }
    }

    private String normalizeAccountStatus(String status) {
        if (status == null) {
            return null;
        }
        String value = status.trim().toLowerCase(Locale.ROOT);
        if (value.isEmpty() || !ALLOWED_ACCOUNT_STATUS.contains(value)) {
            return null;
        }
        return "locked".equals(value) ? "Locked" : "Active";
    }

    private boolean isAccountEmailExistsForOtherAccount(String email, int accountId) {
        if (email == null || email.isBlank() || accountId <= 0) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?) AND account_id <> ?";
        try (Connection connection = DatabaseConnection.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email.trim());
            statement.setInt(2, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to check duplicate account email for profile edit", e);
            return true;
        }
    }

    private String normalizeDepartmentForAi(String rawDepartment) {
        if (rawDepartment == null) {
            return "General";
        }
        String trimmed = rawDepartment.trim();
        if (trimmed.isEmpty()) {
            return "General";
        }
        String lower = trimmed.toLowerCase(Locale.ROOT);
        if (lower.contains("nội tiết") || lower.contains("tiểu đường") || lower.contains("endocrin")) {
            return "Endocrinology";
        }
        if (lower.contains("tim mạch") || lower.contains("cardio")) {
            return "Cardiology";
        }
        if (lower.contains("thận") || lower.contains("tiết niệu") || lower.contains("nephro")) {
            return "Nephrology";
        }
        if (lower.contains("tổng quát") || lower.contains("general")) {
            return "General";
        }
        return trimmed;
    }

    private String toTitleCase(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        String lower = value.toLowerCase(Locale.ROOT);
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }

    private void bindParams(PreparedStatement statement, List<Object> params) throws SQLException {
        for (int i = 0; i < params.size(); i++) {
            Object param = params.get(i);
            int idx = i + 1;
            if (param instanceof Integer) {
                statement.setInt(idx, (Integer) param);
            } else if (param instanceof BigDecimal) {
                statement.setBigDecimal(idx, (BigDecimal) param);
            } else if (param instanceof Date) {
                statement.setDate(idx, (Date) param);
            } else if (param instanceof Timestamp) {
                statement.setTimestamp(idx, (Timestamp) param);
            } else {
                statement.setString(idx, String.valueOf(param));
            }
        }
    }

    public boolean updateAccountPassword(int accountId, String rawPassword) {
        if (accountId <= 0 || rawPassword == null || rawPassword.trim().isEmpty()) {
            return false;
        }
        String sql = "UPDATE Account SET password_hash = ? WHERE account_id = ?";
        String hashedPassword = com.diabetes.monitoring.util.PasswordUtil.hashPassword(rawPassword.trim());
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, hashedPassword);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Failed to update account password direct", e);
        }
        return false;
    }
}
