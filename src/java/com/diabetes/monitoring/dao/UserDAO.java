package com.diabetes.monitoring.dao;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.InputValidationUtil;
import com.diabetes.monitoring.util.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class UserDAO {

    /**
     * Register new patient: create Account + Patient record
     * Returns error message or null if success
     */
    public String registerUser(User user) {
        String sqlAccount = "INSERT INTO Account (full_name, password_hash, email, role, status) VALUES (?, ?, ?, 'Patient', 'Active')";
        String sqlPatient = "INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, account_id) VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        Connection connection = null;
        try {
            connection = DatabaseConnection.getConnection();
            connection.setAutoCommit(false);

            // 1. Insert into Account table and get generated account_id
            int accountId;
            try (PreparedStatement stmtAccount = connection.prepareStatement(sqlAccount, Statement.RETURN_GENERATED_KEYS)) {
                stmtAccount.setString(1, user.getFullName());
                stmtAccount.setString(2, user.getPassword()); // already hashed
                stmtAccount.setString(3, user.getEmail());
                stmtAccount.executeUpdate();
                
                try (ResultSet rs = stmtAccount.getGeneratedKeys()) {
                    if (rs.next()) {
                        accountId = rs.getInt(1);
                    } else {
                        throw new SQLException("Failed to get generated account_id");
                    }
                }
            }

            // 2. Insert into Patient table with account_id
            try (PreparedStatement stmtPatient = connection.prepareStatement(sqlPatient)) {
                stmtPatient.setString(1, user.getFullName());
                stmtPatient.setString(2, user.getDob());
                stmtPatient.setString(3, user.getGender());
                stmtPatient.setString(4, user.getPhone());
                stmtPatient.setString(5, user.getEmail());
                stmtPatient.setString(6, user.getAddress());
                stmtPatient.setInt(7, accountId);
                stmtPatient.executeUpdate();
            }

            connection.commit();
            user.setId(accountId);
            return null;
        } catch (SQLException e) {
            if (connection != null) {
                try {
                    connection.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            return "SQL Error: " + e.getMessage();
        } finally {
            if (connection != null) {
                try {
                    connection.setAutoCommit(true);
                    connection.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Get user by account_id
     */
    public User getUserById(int accountId) {
        String sql = "SELECT account_id, full_name, email, role FROM Account WHERE account_id = ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    User user = new User();
                    user.setId(resultSet.getInt("account_id"));
                    user.setFullName(resultSet.getString("full_name"));
                    user.setEmail(resultSet.getString("email"));
                    user.setRole(resultSet.getString("role"));
                    return user;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Validate login using Account table.
     * The role is resolved from the Account record, so the login form does not need a role selector.
     * For patients/doctors: also fetch role-specific profile details.
     */
    public User validateLogin(String email, String password) {
        if (email == null || email.trim().isEmpty() || password == null) {
            return null;
        }
        String sqlAccount = "SELECT account_id, full_name, email, role, password_hash, status "
                + "FROM Account WHERE LOWER(email) = LOWER(?)";
        
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sqlAccount)) {
            statement.setString(1, email);
            
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    String storedHash = rs.getString("password_hash");
                    String status = rs.getString("status");
                    
                    // Check if account is active (allow NULL as active for existing accounts)
                    if (status != null && !"Active".equalsIgnoreCase(status)) {
                        return null;
                    }
                    
                    if (PasswordUtil.matches(password, storedHash)) {
                        int accountId = rs.getInt("account_id");
                        String userRole = rs.getString("role");
                        
                        User user = new User();
                        user.setId(accountId);
                        user.setFullName(rs.getString("full_name"));
                        user.setEmail(rs.getString("email"));
                        user.setRole(userRole);
                        
                        if ("Patient".equalsIgnoreCase(userRole)) {
                            loadPatientDetails(connection, user, accountId);
                        } else if ("Doctor".equalsIgnoreCase(userRole)) {
                            loadDoctorDetails(connection, user, accountId);
                        } else if ("Receptionist".equalsIgnoreCase(userRole)) {
                            loadReceptionDetails(connection, user, accountId);
                        } else if (isDoctorLabRole(userRole)) {
                            loadDoctorLabDetails(connection, user, accountId);
                        }
                        
                        return user;
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public User validateLogin(String email, String password, String role) {
        return validateLogin(email, password);
    }

    private void loadPatientDetails(Connection connection, User user, int accountId) throws SQLException {
        String sql = "SELECT full_name, phone, address, date_of_birth, gender FROM Patient WHERE account_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, accountId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    if (rs.getString("full_name") != null && !rs.getString("full_name").isBlank()) {
                        user.setFullName(rs.getString("full_name"));
                    }
                    user.setPhone(rs.getString("phone"));
                    user.setAddress(rs.getString("address"));
                    user.setDob(rs.getString("date_of_birth"));
                    user.setGender(rs.getString("gender"));
                }
            }
        }
    }

    private void loadDoctorDetails(Connection connection, User user, int accountId) throws SQLException {
        String sql = "SELECT full_name, phone, address, date_of_birth, gender FROM Doctor WHERE account_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, accountId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    if (rs.getString("full_name") != null && !rs.getString("full_name").isBlank()) {
                        user.setFullName(rs.getString("full_name"));
                    }
                    user.setPhone(rs.getString("phone"));
                    user.setAddress(rs.getString("address"));
                    user.setDob(rs.getString("date_of_birth"));
                    user.setGender(rs.getString("gender"));
                }
            }
        }
    }

    private void loadReceptionDetails(Connection connection, User user, int accountId) throws SQLException {
        String sql = "SELECT full_name, phone, address, date_of_birth, gender FROM Reception WHERE account_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, accountId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    if (rs.getString("full_name") != null && !rs.getString("full_name").isBlank()) {
                        user.setFullName(rs.getString("full_name"));
                    }
                    user.setPhone(rs.getString("phone"));
                    user.setAddress(rs.getString("address"));
                    user.setDob(rs.getString("date_of_birth"));
                    user.setGender(rs.getString("gender"));
                }
            }
        }
    }

    private void loadDoctorLabDetails(Connection connection, User user, int accountId) throws SQLException {
        String sql = "SELECT full_name, phone, address, date_of_birth, gender FROM Doctor_Lab WHERE account_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, accountId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    if (rs.getString("full_name") != null && !rs.getString("full_name").isBlank()) {
                        user.setFullName(rs.getString("full_name"));
                    }
                    user.setPhone(rs.getString("phone"));
                    user.setAddress(rs.getString("address"));
                    user.setDob(rs.getString("date_of_birth"));
                    user.setGender(rs.getString("gender"));
                }
            }
        }
    }

    public void syncUserDetails(User user) {
        if (user == null || user.getId() <= 0) return;
        try (Connection connection = DatabaseConnection.getConnection()) {
            String role = user.getRole();
            if ("Patient".equalsIgnoreCase(role)) {
                loadPatientDetails(connection, user, user.getId());
            } else if ("Doctor".equalsIgnoreCase(role)) {
                loadDoctorDetails(connection, user, user.getId());
            } else if ("Receptionist".equalsIgnoreCase(role)) {
                loadReceptionDetails(connection, user, user.getId());
            } else if (isDoctorLabRole(role)) {
                loadDoctorLabDetails(connection, user, user.getId());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private boolean isDoctorLabRole(String role) {
        if (role == null) return false;
        String normalized = role.trim().replace("-", "_").replace(" ", "_");
        return "doctor_lab".equalsIgnoreCase(normalized);
    }
    
    /**
     * Check if email already exists in Account table
     * Returns true if email exists, false otherwise
     */
    public boolean isEmailExists(String email) {
        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?)";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean isEmailExistsForOtherAccount(String email, int accountId) {
        String sql = "SELECT COUNT(*) FROM Account WHERE LOWER(email) = LOWER(?) AND account_id <> ?";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            statement.setInt(2, accountId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean isPatientPhoneExists(String phone) {
        return isPatientPhoneExistsForOtherAccount(phone, -1);
    }

    public boolean isPatientPhoneExistsForOtherAccount(String phone, int accountId) {
        String normalizedPhone = InputValidationUtil.normalizeVietnamesePhone(phone);
        String sql = "SELECT account_id, phone FROM Patient WHERE phone IS NOT NULL";
        try (Connection connection = DatabaseConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                if (accountId > 0 && rs.getInt("account_id") == accountId) {
                    continue;
                }
                String existingPhone = InputValidationUtil.normalizeVietnamesePhone(rs.getString("phone"));
                if (normalizedPhone != null && normalizedPhone.equals(existingPhone)) {
                    return true;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}
