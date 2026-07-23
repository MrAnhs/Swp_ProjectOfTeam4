package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.UserDAO;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.InputValidationUtil;
import com.diabetes.monitoring.util.PasswordUtil;
import com.diabetes.monitoring.verification.EmailVerificationService;

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
    private final EmailVerificationService verificationService = new EmailVerificationService();
    private static final Set<String> ALLOWED_GENDERS = Set.of("male", "female", "other");
    private static final LocalDate MIN_DATE_OF_BIRTH = LocalDate.of(1900, 1, 1);
    private static final int MIN_PASSWORD_LENGTH = 8;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        String path = request.getPathInfo();
        if ("send-otp".equals(action) || (path != null && path.endsWith("/send-otp"))) {
            handleSendOtp(request, response);
            return;
        }

        String fullName = InputValidationUtil.trimToNull(request.getParameter("fullName"));
        String email = InputValidationUtil.normalizeEmail(request.getParameter("email"));
        String otp = InputValidationUtil.trimToNull(request.getParameter("otp"));
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

        if (otp == null || !otp.matches("\\d{6}")) {
            forwardWithError(request, response, "Vui lòng nhập mã OTP xác thực 6 chữ số.");
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

        // Verify Email OTP before registration
        try {
            verificationService.verifyRegistrationOtp(email, otp);
        } catch (IllegalArgumentException e) {
            forwardWithError(request, response, e.getMessage());
            return;
        } catch (Exception e) {
            getServletContext().log("Unable to verify registration OTP", e);
            forwardWithError(request, response, "Kh\u00f4ng th\u1ec3 x\u00e1c th\u1EF1c m\u00e3 OTP l\u00fac n\u00e0y. Vui l\u00f2ng th\u1eed l\u1ea1i.");
            return;
        }

        String hashedPassword = PasswordUtil.hashPassword(password);
        User user = new User(fullName, email, hashedPassword, "Patient", gender, dob, phone, address, null, null);
        String errorMsg = userDAO.registerUser(user);
        if (errorMsg == null) {
            request.getSession().setAttribute("currentUser", user);
            response.sendRedirect(request.getContextPath() + "/patient/dashboard");
        } else {
            request.setAttribute("registerError", "\u0110\u0103ng k\u00fd th\u1ea5t b\u1ea1i: " + errorMsg);
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }

    private void handleSendOtp(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        String email = InputValidationUtil.normalizeEmail(request.getParameter("email"));
        if (!InputValidationUtil.isValidEmail(email)) {
            response.setStatus(400);
            response.getWriter().write("{\"success\":false,\"message\":\"Email kh\u00f4ng \u0111\u00fang \u0111\u1ecbnh d\u1ea1ng. Vui l\u00f2ng ki\u1ec3m tra l\u1ea1i.\"}");
            return;
        }

        if (userDAO.isEmailExists(email)) {
            response.setStatus(400);
            response.getWriter().write("{\"success\":false,\"message\":\"Email n\u00e0y \u0111\u00e3 \u0111\u01b0\u1ee3c \u0111\u0103ng k\u00fd. Vui l\u00f2ng s\u1eed d\u1ee5ng email kh\u00e1c.\"}");
            return;
        }

        try {
            verificationService.requestRegistrationOtp(email);
            response.getWriter().write("{\"success\":true,\"message\":\"M\u00e3 OTP 6 ch\u1eed s\u1ed1 \u0111\u00e3 \u0111\u01b0\u1ee3c g\u1eedi t\u1edbi email c\u1ee7a b\u1ea1n.\"}");
        } catch (IllegalArgumentException e) {
            response.setStatus(400);
            response.getWriter().write("{\"success\":false,\"message\":\"" + escapeJson(e.getMessage()) + "\"}");
        } catch (Exception e) {
            getServletContext().log("Unable to send registration OTP", e);
            response.setStatus(500);
            String errMsg = e.getMessage() != null ? e.getMessage() : "L\u1ed7i h\u1ec7 th\u1ed1ng khi g\u1eedi email";
            response.getWriter().write("{\"success\":false,\"message\":\"" + escapeJson(errMsg) + "\"}");
        }
    }

    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
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
