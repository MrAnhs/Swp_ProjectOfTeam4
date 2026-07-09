package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.UserDAO;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.InputValidationUtil;
import com.diabetes.monitoring.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Set;

public class RegisterServlet extends HttpServlet {
    private final UserDAO userDAO = new UserDAO();
    private static final Set<String> ALLOWED_GENDERS = Set.of("male", "female", "other");
    private static final LocalDate MIN_DATE_OF_BIRTH = LocalDate.of(1900, 1, 1);
    private static final int MIN_PASSWORD_LENGTH = 8;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String fullName = InputValidationUtil.trimToNull(request.getParameter("fullName"));
        String email = InputValidationUtil.normalizeEmail(request.getParameter("email"));
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        String gender = InputValidationUtil.trimToNull(request.getParameter("gender"));
        String dob = InputValidationUtil.trimToNull(request.getParameter("dob"));
        String phone = InputValidationUtil.normalizeVietnamesePhone(request.getParameter("phone"));
        String address = InputValidationUtil.trimToNull(request.getParameter("address"));

        // Validate required fields
        String validationError = validateRequiredFields(
                fullName, email, password, confirmPassword, gender, dob, phone);
        if (validationError != null) {
            forwardWithError(request, response, validationError);
            return;
        }

        // Validate email format
        if (!InputValidationUtil.isValidEmail(email)) {
            forwardWithError(request, response, "Email không đúng định dạng. Vui lòng kiểm tra lại.");
            return;
        }

        if (!isValidGender(gender)) {
            forwardWithError(request, response, "Giới tính không hợp lệ. Vui lòng chọn lại.");
            return;
        }

        if (!isValidDateOfBirth(dob)) {
            forwardWithError(request, response,
                    "Ngày sinh phải hợp lệ, không nằm trong tương lai và không trước ngày 01/01/1900.");
            return;
        }

        if (!InputValidationUtil.isValidVietnameseMobilePhone(phone)) {
            forwardWithError(request, response,
                    "Số điện thoại phải gồm 9–15 chữ số và chỉ có thể bắt đầu bằng dấu +.");
            return;
        }

        // Validate password match
        if (!password.equals(confirmPassword)) {
            forwardWithError(request, response, "Mật khẩu xác nhận không khớp. Vui lòng nhập lại.");
            return;
        }

        // Validate password length
        if (password.length() < MIN_PASSWORD_LENGTH) {
            forwardWithError(request, response,
                    "Mật khẩu phải có ít nhất " + MIN_PASSWORD_LENGTH + " ký tự.");
            return;
        }

        // Check if email already exists
        if (userDAO.isEmailExists(email)) {
            forwardWithError(request, response,
                    "Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.");
            return;
        }

        if (userDAO.isPatientPhoneExists(phone)) {
            forwardWithError(request, response,
                    "Số điện thoại này đã được sử dụng. Vui lòng nhập số khác.");
            return;
        }

        String hashedPassword = PasswordUtil.hashPassword(password);
        User user = new User(fullName, email, hashedPassword, "Patient", gender, dob, phone, address, null, null);
        String errorMsg = userDAO.registerUser(user);
        if (errorMsg == null) {
            request.getSession().setAttribute("currentUser", user);
            response.sendRedirect(request.getContextPath() + "/patient/dashboard");
        } else {
            request.setAttribute("registerError", "Đăng ký thất bại: " + errorMsg);
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }
    
    /**
     * Validate required fields
     * Returns error message if validation fails, null if all valid
     */
    private String validateRequiredFields(String fullName, String email, String password,
            String confirmPassword, String gender, String dob, String phone) {
        if (isNullOrEmpty(fullName)) {
            return "Họ tên là bắt buộc. Vui lòng nhập họ tên của bạn.";
        }
        if (isNullOrEmpty(email)) {
            return "Email là bắt buộc. Vui lòng nhập email của bạn.";
        }
        if (isNullOrEmpty(password)) {
            return "Mật khẩu là bắt buộc. Vui lòng nhập mật khẩu.";
        }
        if (isNullOrEmpty(confirmPassword)) {
            return "Vui lòng xác nhận mật khẩu.";
        }
        if (isNullOrEmpty(gender)) {
            return "Giới tính là bắt buộc. Vui lòng chọn giới tính.";
        }
        if (isNullOrEmpty(dob)) {
            return "Ngày sinh là bắt buộc. Vui lòng nhập ngày sinh.";
        }
        if (isNullOrEmpty(phone)) {
            return "Số điện thoại là bắt buộc. Vui lòng nhập số điện thoại.";
        }
        return null;
    }
    
    /**
     * Check if string is null or empty/whitespace only
     */
    private boolean isNullOrEmpty(String value) {
        return value == null || value.trim().isEmpty();
    }
    
    private boolean isValidGender(String gender) {
        return gender != null && ALLOWED_GENDERS.contains(gender);
    }

    private boolean isValidDateOfBirth(String dob) {
        try {
            LocalDate dateOfBirth = LocalDate.parse(dob);
            return !dateOfBirth.isBefore(MIN_DATE_OF_BIRTH) && !dateOfBirth.isAfter(LocalDate.now());
        } catch (DateTimeParseException e) {
            return false;
        }
    }

    private void forwardWithError(HttpServletRequest request, HttpServletResponse response, String message)
            throws ServletException, IOException {
        request.setAttribute("registerError", message);
        request.getRequestDispatcher("register.jsp").forward(request, response);
    }
}
