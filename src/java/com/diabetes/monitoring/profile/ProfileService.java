package com.diabetes.monitoring.profile;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.InputValidationUtil;
import com.diabetes.monitoring.util.PasswordUtil;
import java.sql.Connection;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.Set;

public class ProfileService {
    private static final Set<String> ALLOWED_GENDERS = Set.of("male", "female", "other");
    private final ProfileDAO profileDAO = new ProfileDAO();

    public Profile load(User user) throws Exception {
        ensureAllowedRole(user);
        return profileDAO.findByAccountId(user.getId(), normalizeRole(user.getRole()));
    }

    public void update(User user, Profile profile) throws Exception {
        ensureAllowedRole(user);
        profile.setAccountId(user.getId());
        profile.setRole(normalizeRole(user.getRole()));
        validate(profile);

        try (Connection connection = DatabaseConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                if (profileDAO.phoneExistsForOtherAccount(
                        connection, profile.getPhone(), user.getId())) {
                    throw new IllegalArgumentException(
                            "Số điện thoại này đã được sử dụng bởi tài khoản khác");
                }
                profileDAO.update(connection, profile);
                new com.diabetes.monitoring.notification.NotificationService().notifyProfileUpdated(connection, user.getId());
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }

        user.setFullName(profile.getFullName());
        user.setPhone(profile.getPhone());
        user.setDob(profile.getDateOfBirth());
        user.setGender(profile.getGender());
        user.setAddress(profile.getAddress());
    }

    public void changePassword(User user, String currentPassword,
            String newPassword, String confirmation) throws Exception {
        ensureAllowedRole(user);
        if (currentPassword == null || newPassword == null
                || !newPassword.equals(confirmation)) {
            throw new IllegalArgumentException(
                    "Mật khẩu xác nhận không khớp");
        }
        if (newPassword.length() < 8) {
            throw new IllegalArgumentException(
                    "Mật khẩu mới phải có ít nhất 8 ký tự");
        }
        try (Connection connection = DatabaseConnection.getConnection()) {
            String storedPassword = profileDAO.findPasswordHash(connection, user.getId());
            if (!PasswordUtil.matches(currentPassword, storedPassword)) {
                throw new IllegalArgumentException(
                        "Mật khẩu hiện tại không đúng");
            }
            connection.setAutoCommit(false);
            try {
                profileDAO.updatePassword(connection, user.getId(),
                        PasswordUtil.hashPassword(newPassword));
                new com.diabetes.monitoring.notification.NotificationService().notifyPasswordChanged(connection, user.getId(), false);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    private void validate(Profile profile) {
        if (profile.getFullName() == null || profile.getFullName().isBlank()) {
            throw new IllegalArgumentException("H\u1ECD t\u00EAn kh\u00F4ng \u0111\u01B0\u1EE3c \u0111\u1EC3 tr\u1ED1ng");
        }
        profile.setFullName(profile.getFullName().trim());
        profile.setPhone(InputValidationUtil.normalizeVietnamesePhone(profile.getPhone()));
        if (!InputValidationUtil.isValidVietnameseMobilePhone(profile.getPhone())) {
            throw new IllegalArgumentException(
                    "S\u1ED1 \u0111i\u1EC7n tho\u1EA1i Vi\u1EC7t Nam kh\u00F4ng h\u1EE3p l\u1EC7");
        }
        if (profile.getGender() != null && !profile.getGender().isBlank()
                && !ALLOWED_GENDERS.contains(profile.getGender())) {
            throw new IllegalArgumentException("Gi\u1EDBi t\u00EDnh kh\u00F4ng h\u1EE3p l\u1EC7");
        }
        if ("patient".equals(normalizeRole(profile.getRole()))
                && (profile.getDateOfBirth() == null
                    || profile.getDateOfBirth().isBlank())) {
            throw new IllegalArgumentException("Ng\u00E0y sinh kh\u00F4ng \u0111\u01B0\u1EE3c \u0111\u1EC3 tr\u1ED1ng");
        }
        if (profile.getDateOfBirth() != null && !profile.getDateOfBirth().isBlank()) {
            try {
                LocalDate date = LocalDate.parse(profile.getDateOfBirth());
                if (date.isBefore(LocalDate.of(1900, 1, 1))
                        || date.isAfter(LocalDate.now())) {
                    throw new IllegalArgumentException("Ng\u00E0y sinh kh\u00F4ng h\u1EE3p l\u1EC7");
                }
            } catch (DateTimeParseException e) {
                throw new IllegalArgumentException("Ng\u00E0y sinh kh\u00F4ng h\u1EE3p l\u1EC7");
            }
        }
    }

    private void ensureAllowedRole(User user) {
        if (user == null || "admin".equals(normalizeRole(user.getRole()))) {
            throw new IllegalArgumentException(
                    "Admin kh\u00F4ng d\u00F9ng ch\u1EE9c n\u0103ng profile n\u00E0y");
        }
    }

    private String normalizeRole(String role) {
        return role == null ? "" : role.trim().replace('-', '_')
                .replace(' ', '_').toLowerCase(Locale.ROOT);
    }
}
