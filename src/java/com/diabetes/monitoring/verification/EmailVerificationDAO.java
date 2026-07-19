package com.diabetes.monitoring.verification;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;

public class EmailVerificationDAO {
    public AccountIdentity findActiveAccountByEmail(Connection connection, String email)
            throws SQLException {
        String sql = "SELECT account_id, email FROM Account "
                + "WHERE LOWER(email) = LOWER(?) AND (status IS NULL OR status = 'Active')";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return null;
                return new AccountIdentity(result.getInt("account_id"), result.getString("email"));
            }
        }
    }

    public boolean isRateLimited(Connection connection, Integer accountId,
            String targetEmail, String purpose, int minimumSeconds, int hourlyLimit)
            throws SQLException {
        String sql = "SELECT COUNT(*) AS request_count, MAX(created_at) AS last_request "
                + "FROM Email_Verification WITH (UPDLOCK, HOLDLOCK) WHERE purpose = ? "
                + "AND created_at >= DATEADD(HOUR, -1, GETDATE()) "
                + "AND (LOWER(target_email) = LOWER(?) "
                + (accountId == null ? ") " : "OR account_id = ?) ");
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, purpose);
            statement.setString(2, targetEmail);
            if (accountId != null) statement.setInt(3, accountId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return false;
                int count = result.getInt("request_count");
                Timestamp lastRequest = result.getTimestamp("last_request");
                boolean tooSoon = lastRequest != null
                        && lastRequest.toLocalDateTime().plusSeconds(minimumSeconds)
                                .isAfter(java.time.LocalDateTime.now());
                return tooSoon || count >= hourlyLimit;
            }
        }
    }

    public void consumeActive(Connection connection, Integer accountId,
            String targetEmail, String purpose) throws SQLException {
        String sql = "UPDATE Email_Verification SET consumed_at = GETDATE() "
                + "WHERE purpose = ? AND LOWER(target_email) = LOWER(?) "
                + "AND consumed_at IS NULL "
                + (accountId == null ? "" : "AND account_id = ?");
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, purpose);
            statement.setString(2, targetEmail);
            if (accountId != null) statement.setInt(3, accountId);
            statement.executeUpdate();
        }
    }

    public long insert(Connection connection, Integer accountId, String purpose,
            String targetEmail, String otpHash, int expiryMinutes) throws SQLException {
        String sql = "INSERT INTO Email_Verification "
                + "(account_id, purpose, target_email, otp_hash, expires_at, failed_attempts, created_at) "
                + "VALUES (?, ?, ?, ?, DATEADD(MINUTE, ?, GETDATE()), 0, GETDATE())";
        try (PreparedStatement statement = connection.prepareStatement(
                sql, Statement.RETURN_GENERATED_KEYS)) {
            if (accountId == null) statement.setNull(1, java.sql.Types.INTEGER);
            else statement.setInt(1, accountId);
            statement.setString(2, purpose);
            statement.setString(3, targetEmail);
            statement.setString(4, otpHash);
            statement.setInt(5, expiryMinutes);
            if (statement.executeUpdate() != 1) {
                throw new SQLException("Unable to create email verification");
            }
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
        }
        throw new SQLException("Unable to read verification id");
    }

    public EmailVerification lockLatestActive(Connection connection, Integer accountId,
            String targetEmail, String purpose) throws SQLException {
        String sql = "SELECT TOP 1 verification_id, account_id, purpose, target_email, "
                + "otp_hash, expires_at, failed_attempts "
                + "FROM Email_Verification WITH (UPDLOCK, ROWLOCK) "
                + "WHERE purpose = ? AND LOWER(target_email) = LOWER(?) "
                + "AND consumed_at IS NULL "
                + (accountId == null ? "" : "AND account_id = ? ")
                + "ORDER BY created_at DESC, verification_id DESC";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, purpose);
            statement.setString(2, targetEmail);
            if (accountId != null) statement.setInt(3, accountId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) return null;
                EmailVerification verification = new EmailVerification();
                verification.setVerificationId(result.getLong("verification_id"));
                int storedAccountId = result.getInt("account_id");
                verification.setAccountId(result.wasNull() ? null : storedAccountId);
                verification.setPurpose(result.getString("purpose"));
                verification.setTargetEmail(result.getString("target_email"));
                verification.setOtpHash(result.getString("otp_hash"));
                verification.setExpiresAt(result.getTimestamp("expires_at").toLocalDateTime());
                verification.setFailedAttempts(result.getInt("failed_attempts"));
                return verification;
            }
        }
    }

    public void registerFailedAttempt(Connection connection, long verificationId,
            int maximumAttempts) throws SQLException {
        String sql = "UPDATE Email_Verification SET failed_attempts = failed_attempts + 1, "
                + "consumed_at = CASE WHEN failed_attempts + 1 >= ? THEN GETDATE() ELSE consumed_at END "
                + "WHERE verification_id = ? AND consumed_at IS NULL";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, maximumAttempts);
            statement.setLong(2, verificationId);
            statement.executeUpdate();
        }
    }

    public void markConsumed(Connection connection, long verificationId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE Email_Verification SET consumed_at = GETDATE() "
                        + "WHERE verification_id = ? AND consumed_at IS NULL")) {
            statement.setLong(1, verificationId);
            if (statement.executeUpdate() != 1) {
                throw new SQLException("Verification was already consumed");
            }
        }
    }

    public static class AccountIdentity {
        private final int accountId;
        private final String email;

        public AccountIdentity(int accountId, String email) {
            this.accountId = accountId;
            this.email = email;
        }

        public int getAccountId() { return accountId; }
        public String getEmail() { return email; }
    }
}
