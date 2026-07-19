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
                if (profileDAO.emailExistsForOtherAccount(connection, profile.getEmail(), user.getId())) {
                    throw new IllegalArgumentException("Email này đã được sử dụng bởi tài khoản khác");
                }
                if (profileDAO.phoneExistsForOtherAccount(connection, profile.getPhone(), user.getId())) {
                    throw new IllegalArgumentException("Số điện thoại này đã được sử dụng bởi tài khoản khác");
                }
                profileDAO.update(connection, profile);
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                throw e;
            }
        }
        user.setFullName(profile.getFullName());
        user.setEmail(profile.getEmail());
        user.setPhone(profile.getPhone());
        user.setDob(profile.getDateOfBirth());
        user.setGender(profile.getGender());
        user.setAddress(profile.getAddress());
    }

    public void changeEmail(User user, String newEmail, String currentPassword) throws Exception {
        ensureAllowedRole(user);
        newEmail = InputValidationUtil.normalizeEmail(newEmail);
        if (!InputValidationUtil.isValidEmail(newEmail)) throw new IllegalArgumentException("Email không đúng định dạng");
        try (Connection connection = DatabaseConnection.getConnection()) {
            if (!PasswordUtil.matches(currentPassword == null ? "" : currentPassword, profileDAO.findPasswordHash(connection, user.getId()))) throw new IllegalArgumentException("Mật khẩu hiện tại không đúng");
            if (profileDAO.emailExistsForOtherAccount(connection, newEmail, user.getId())) throw new IllegalArgumentException("Email này đã được sử dụng bởi tài khoản khác");
            connection.setAutoCommit(false);
            try { profileDAO.updateEmail(connection, user.getId(), newEmail); connection.commit(); }
            catch (Exception e) { connection.rollback(); throw e; }
        }
        user.setEmail(newEmail);
    }

    public void changePassword(User user, String currentPassword, String newPassword, String confirmation) throws Exception {
        ensureAllowedRole(user);
        if (currentPassword == null || newPassword == null || !newPassword.equals(confirmation)) throw new IllegalArgumentException("Mật khẩu xác nhận không khớp");
        if (newPassword.length() < 8) throw new IllegalArgumentException("Mật khẩu mới phải có ít nhất 8 ký tự");
        try (Connection connection = DatabaseConnection.getConnection()) {
            if (!PasswordUtil.matches(currentPassword, profileDAO.findPasswordHash(connection, user.getId()))) throw new IllegalArgumentException("Mật khẩu hiện tại không đúng");
            profileDAO.updatePassword(connection, user.getId(), PasswordUtil.hashPassword(newPassword));
        }
    }

    private void validate(Profile profile) {
        if (profile.getFullName() == null || profile.getFullName().isBlank()) {
            throw new IllegalArgumentException("Họ tên không được để trống");
        }
        profile.setFullName(profile.getFullName().trim());
        profile.setEmail(InputValidationUtil.normalizeEmail(profile.getEmail()));
        profile.setPhone(InputValidationUtil.normalizeVietnamesePhone(profile.getPhone()));
        if (!InputValidationUtil.isValidEmail(profile.getEmail())) throw new IllegalArgumentException("Email không đúng định dạng");
        if (!InputValidationUtil.isValidVietnameseMobilePhone(profile.getPhone())) throw new IllegalArgumentException("Số điện thoại Việt Nam không hợp lệ");
        if (profile.getGender() != null && !profile.getGender().isBlank() && !ALLOWED_GENDERS.contains(profile.getGender())) throw new IllegalArgumentException("Giới tính không hợp lệ");
        if ("patient".equals(normalizeRole(profile.getRole())) && (profile.getDateOfBirth() == null || profile.getDateOfBirth().isBlank())) {
            throw new IllegalArgumentException("Ngày sinh không được để trống");
        }
        if (profile.getDateOfBirth() != null && !profile.getDateOfBirth().isBlank()) {
            try {
                LocalDate date = LocalDate.parse(profile.getDateOfBirth());
                if (date.isBefore(LocalDate.of(1900, 1, 1)) || date.isAfter(LocalDate.now())) throw new IllegalArgumentException("Ngày sinh không hợp lệ");
            } catch (DateTimeParseException e) { throw new IllegalArgumentException("Ngày sinh không hợp lệ"); }
        }
    }

    private void ensureAllowedRole(User user) {
        if (user == null || "admin".equals(normalizeRole(user.getRole()))) throw new IllegalArgumentException("Admin không dùng chức năng profile này");
    }

    private String normalizeRole(String role) {
        return role == null ? "" : role.trim().replace('-', '_').replace(' ', '_').toLowerCase(Locale.ROOT);
    }
}
