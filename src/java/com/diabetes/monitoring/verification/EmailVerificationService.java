package com.diabetes.monitoring.verification;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.profile.ProfileDAO;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.InputValidationUtil;
import com.diabetes.monitoring.util.PasswordUtil;
import java.sql.Connection;
import java.time.LocalDateTime;
import java.util.Locale;

public class EmailVerificationService {
    public static final String CHANGE_EMAIL = "CHANGE_EMAIL";
    public static final String RESET_PASSWORD = "RESET_PASSWORD";
    public static final String REGISTER = "REGISTER";
    public static final int OTP_EXPIRY_MINUTES = 5;
    public static final int RESET_GRANT_MINUTES = 10;
    private static final int MAXIMUM_ATTEMPTS = 5;
    private static final int RESEND_INTERVAL_SECONDS = 60;
    private static final int HOURLY_REQUEST_LIMIT = 5;

    private final EmailVerificationDAO verificationDAO;
    private final ProfileDAO profileDAO;
    private final OtpSecurity otpSecurity;
    private final OtpEmailSender emailSender;
    private final com.diabetes.monitoring.notification.NotificationService notificationService =
            new com.diabetes.monitoring.notification.NotificationService();

    public EmailVerificationService() {
        this(new EmailVerificationDAO(), new ProfileDAO(),
                new OtpSecurity(), new SmtpOtpEmailSender());
    }

    public EmailVerificationService(EmailVerificationDAO verificationDAO,
            ProfileDAO profileDAO, OtpSecurity otpSecurity, OtpEmailSender emailSender) {
        this.verificationDAO = verificationDAO;
        this.profileDAO = profileDAO;
        this.otpSecurity = otpSecurity;
        this.emailSender = emailSender;
    }

    public void requestEmailChange(User user, String newEmail, String currentPassword)
            throws Exception {
        ensureSignedIn(user);
        String normalizedEmail = validEmail(newEmail);
        if (normalizedEmail.equalsIgnoreCase(user.getEmail())) {
            throw new IllegalArgumentException("Email m\u1EDBi ph\u1EA3i kh\u00E1c email hi\u1EC7n t\u1EA1i");
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                String storedPassword = profileDAO.findPasswordHash(connection, user.getId());
                if (!PasswordUtil.matches(value(currentPassword), storedPassword)) {
                    throw new IllegalArgumentException("M\u1EADt kh\u1EA9u hi\u1EC7n t\u1EA1i kh\u00F4ng \u0111\u00FAng");
                }
                if (profileDAO.emailExistsForOtherAccount(connection, normalizedEmail, user.getId())) {
                    throw new IllegalArgumentException(
                            "Email n\u00E0y \u0111\u00E3 \u0111\u01B0\u1EE3c s\u1EED d\u1EE5ng b\u1EDFi t\u00E0i kho\u1EA3n kh\u00E1c");
                }
                ensureNotRateLimited(connection, user.getId(), normalizedEmail, CHANGE_EMAIL);
                createAndSend(connection, user.getId(), normalizedEmail, CHANGE_EMAIL);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public void confirmEmailChange(User user, String newEmail, String otp) throws Exception {
        ensureSignedIn(user);
        String normalizedEmail = validEmail(newEmail);
        validateOtpFormat(otp);

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                EmailVerification verification = verificationDAO.lockLatestActive(
                        connection, user.getId(), normalizedEmail, CHANGE_EMAIL);
                if (!verify(connection, verification, normalizedEmail, CHANGE_EMAIL, otp)) {
                    connection.commit();
                    throw invalidOtp();
                }
                if (profileDAO.emailExistsForOtherAccount(connection, normalizedEmail, user.getId())) {
                    verificationDAO.markConsumed(connection, verification.getVerificationId());
                    connection.commit();
                    throw new IllegalArgumentException(
                            "Email n\u00E0y \u0111\u00E3 \u0111\u01B0\u1EE3c s\u1EED d\u1EE5ng b\u1EDFi t\u00E0i kho\u1EA3n kh\u00E1c");
                }
                String oldEmail = user.getEmail();
                profileDAO.updateEmail(connection, user.getId(), normalizedEmail);
                verificationDAO.markConsumed(connection, verification.getVerificationId());
                notificationService.notifyEmailChanged(connection, user.getId(), oldEmail, normalizedEmail);
                connection.commit();
            } catch (Exception e) {
                safeRollback(connection);
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
        user.setEmail(normalizedEmail);
    }

    public void requestPasswordReset(String email) throws Exception {
        String normalizedEmail = InputValidationUtil.normalizeEmail(email);
        if (!InputValidationUtil.isValidEmail(normalizedEmail)) return;

        try (Connection connection = DatabaseConnection.getConnection()) {
            EmailVerificationDAO.AccountIdentity account =
                    verificationDAO.findActiveAccountByEmail(connection, normalizedEmail);
            if (account == null) {
                otpSecurity.hash(RESET_PASSWORD, normalizedEmail, "000000");
                return;
            }
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                if (verificationDAO.isRateLimited(connection, account.getAccountId(),
                        normalizedEmail, RESET_PASSWORD,
                        RESEND_INTERVAL_SECONDS, HOURLY_REQUEST_LIMIT)) {
                    connection.rollback();
                    return;
                }
                createAndSend(connection, account.getAccountId(),
                        account.getEmail(), RESET_PASSWORD);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public int verifyPasswordResetOtp(String email, String otp) throws Exception {
        String normalizedEmail = validEmail(email);
        validateOtpFormat(otp);
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                EmailVerificationDAO.AccountIdentity account =
                        verificationDAO.findActiveAccountByEmail(connection, normalizedEmail);
                if (account == null) {
                    connection.rollback();
                    throw invalidOtp();
                }
                EmailVerification verification = verificationDAO.lockLatestActive(
                        connection, account.getAccountId(), normalizedEmail, RESET_PASSWORD);
                if (!verify(connection, verification, normalizedEmail, RESET_PASSWORD, otp)) {
                    connection.commit();
                    throw invalidOtp();
                }
                verificationDAO.markConsumed(connection, verification.getVerificationId());
                connection.commit();
                return account.getAccountId();
            } catch (Exception e) {
                safeRollback(connection);
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public void resetPassword(int accountId, String newPassword, String confirmation)
            throws Exception {
        validateNewPassword(newPassword, confirmation);
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                profileDAO.updatePassword(connection, accountId,
                        PasswordUtil.hashPassword(newPassword));
                notificationService.notifyPasswordChanged(connection, accountId, true);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public void requestRegistrationOtp(String email) throws Exception {
        String normalizedEmail = validEmail(email);
        com.diabetes.monitoring.dao.UserDAO userDAO = new com.diabetes.monitoring.dao.UserDAO();
        if (userDAO.isEmailExists(normalizedEmail)) {
            throw new IllegalArgumentException("Email n\u00E0y \u0111\u00E3 \u0111\u01B0\u1EE3c \u0111\u0103ng k\u00FD. Vui l\u00F2ng s\u1EED d\u1EE5ng email kh\u00E1c.");
        }

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                if (verificationDAO.isRateLimited(connection, null,
                        normalizedEmail, REGISTER,
                        RESEND_INTERVAL_SECONDS, HOURLY_REQUEST_LIMIT)) {
                    connection.rollback();
                    throw new IllegalArgumentException("B\u1EA1n g\u1EEDi m\u00E3 qu\u00E1 nhanh. Vui l\u00F2ng ch\u1EDD 60 gi\u00E2y tr\u01B0\u1EDBc khi g\u1EEDi l\u1EA1i.");
                }
                createAndSendRegistrationOtp(connection, normalizedEmail);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    private void createAndSendRegistrationOtp(Connection connection, String targetEmail) throws Exception {
        verificationDAO.consumeActive(connection, null, targetEmail, REGISTER);
        String otp = otpSecurity.generateOtp();
        verificationDAO.insert(connection, null, REGISTER, targetEmail,
                otpSecurity.hash(REGISTER, targetEmail, otp), OTP_EXPIRY_MINUTES);
        emailSender.send(targetEmail, REGISTER, otp, OTP_EXPIRY_MINUTES);
    }

    public boolean verifyRegistrationOtp(String email, String otp) throws Exception {
        String normalizedEmail = validEmail(email);
        validateOtpFormat(otp);
        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                EmailVerification verification = verificationDAO.lockLatestActive(
                        connection, null, normalizedEmail, REGISTER);
                if (!verify(connection, verification, normalizedEmail, REGISTER, otp)) {
                    connection.commit();
                    throw invalidOtp();
                }
                verificationDAO.markConsumed(connection, verification.getVerificationId());
                connection.commit();
                return true;
            } catch (Exception e) {
                safeRollback(connection);
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    private void createAndSend(Connection connection, int accountId,
            String targetEmail, String purpose) throws Exception {
        verificationDAO.consumeActive(connection, accountId, targetEmail, purpose);
        String otp = otpSecurity.generateOtp();
        verificationDAO.insert(connection, accountId, purpose, targetEmail,
                otpSecurity.hash(purpose, targetEmail, otp), OTP_EXPIRY_MINUTES);
        emailSender.send(targetEmail, purpose, otp, OTP_EXPIRY_MINUTES);
    }

    private boolean verify(Connection connection, EmailVerification verification,
            String email, String purpose, String otp) throws Exception {
        if (verification == null) return false;
        if (verification.getFailedAttempts() >= MAXIMUM_ATTEMPTS
                || !verification.getExpiresAt().isAfter(LocalDateTime.now())) {
            verificationDAO.markConsumed(connection, verification.getVerificationId());
            return false;
        }
        if (!otpSecurity.matches(verification.getOtpHash(), purpose, email, otp)) {
            verificationDAO.registerFailedAttempt(connection,
                    verification.getVerificationId(), MAXIMUM_ATTEMPTS);
            return false;
        }
        return true;
    }

    private void ensureNotRateLimited(Connection connection, int accountId,
            String email, String purpose) throws Exception {
        if (verificationDAO.isRateLimited(connection, accountId, email, purpose,
                RESEND_INTERVAL_SECONDS, HOURLY_REQUEST_LIMIT)) {
            throw new IllegalArgumentException(
                    "B\u1EA1n g\u1EEDi m\u00E3 qu\u00E1 nhanh. Vui l\u00F2ng ch\u1EDD 60 gi\u00E2y tr\u01B0\u1EDBc khi g\u1EEDi l\u1EA1i");
        }
    }

    private String validEmail(String email) {
        String normalized = InputValidationUtil.normalizeEmail(email);
        if (!InputValidationUtil.isValidEmail(normalized)) {
            throw new IllegalArgumentException("Email kh\u00F4ng \u0111\u00FAng \u0111\u1ECBnh d\u1EA1ng");
        }
        return normalized;
    }

    private void validateOtpFormat(String otp) {
        if (otp == null || !otp.matches("\\d{6}")) throw invalidOtp();
    }

    private void validateNewPassword(String newPassword, String confirmation) {
        if (newPassword == null || !newPassword.equals(confirmation)) {
            throw new IllegalArgumentException("M\u1EADt kh\u1EA9u x\u00E1c nh\u1EADn kh\u00F4ng kh\u1EDBp");
        }
        if (newPassword.length() < 8) {
            throw new IllegalArgumentException("M\u1EADt kh\u1EA9u m\u1EDBi ph\u1EA3i c\u00F3 \u00EDt nh\u1EA5t 8 k\u00FD t\u1EF1");
        }
    }

    private IllegalArgumentException invalidOtp() {
        return new IllegalArgumentException(
                "M\u00E3 x\u00E1c th\u1EF1c kh\u00F4ng h\u1EE3p l\u1EC7 ho\u1EB7c \u0111\u00E3 h\u1EBFt h\u1EA1n");
    }

    private void ensureSignedIn(User user) {
        if (user == null || user.getId() <= 0) {
            throw new IllegalArgumentException("Phi\u00EAn \u0111\u0103ng nh\u1EADp \u0111\u00E3 h\u1EBFt h\u1EA1n");
        }
        String role = user.getRole() == null ? "" : user.getRole().trim()
                .replace('-', '_').replace(' ', '_').toLowerCase(Locale.ROOT);
        if ("admin".equals(role)) {
            throw new IllegalArgumentException("Qu\u1EA3n tr\u1ECB vi\u00EAn kh\u00F4ng d\u00F9ng ch\u1EE9c n\u0103ng n\u00E0y");
        }
    }

    private String value(String input) { return input == null ? "" : input; }

    private void safeRollback(Connection connection) {
        try { connection.rollback(); } catch (Exception ignored) { }
    }
}
