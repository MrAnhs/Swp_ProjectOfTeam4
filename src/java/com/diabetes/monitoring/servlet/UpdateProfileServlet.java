package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.dao.UserDAO;
import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.util.DatabaseConnection;
import com.diabetes.monitoring.util.InputValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Set;

public class UpdateProfileServlet extends HttpServlet {
    private final UserDAO userDAO = new UserDAO();
    private static final Set<String> ALLOWED_GENDERS = Set.of("male", "female", "other");
    private static final LocalDate MIN_DATE_OF_BIRTH = LocalDate.of(1900, 1, 1);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        int accountId = currentUser.getId();
        String email = currentUser.getEmail();
        String role = currentUser.getRole();

        System.out.println("[UpdateProfileServlet] Loading profile for accountId=" + accountId + ", role=" + role + ", email=" + email);

        // Query Patient by account_id (not email) according to database architecture
        String sql = "SELECT full_name, email, phone, gender, date_of_birth, address FROM Patient WHERE account_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, accountId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String fullName  = nullToEmpty(rs.getString("full_name"));
                    String dob       = nullToEmpty(rs.getString("date_of_birth"));
                    String phone     = nullToEmpty(rs.getString("phone"));
                    String gender    = nullToEmpty(rs.getString("gender"));
                    String patientEmail = nullToEmpty(rs.getString("email"));
                    String address   = nullToEmpty(rs.getString("address"));
                    System.out.println("[UpdateProfileServlet] Loaded patient profile: fullName=" + fullName + ", dob=" + dob);
                    try (PrintWriter out = response.getWriter()) {
                        out.print("{\"fullName\":\"" + escJson(fullName) + "\","
                                + "\"email\":\""    + escJson(patientEmail.isEmpty() ? email : patientEmail) + "\","
                                + "\"phone\":\""    + escJson(phone)    + "\","
                                + "\"gender\":\""   + escJson(gender)   + "\","
                                + "\"dob\":\""      + escJson(dob)      + "\","
                                + "\"address\":\""  + escJson(address)  + "\"}");
                    }
                } else {
                    // If no patient record found, return user data from session
                    System.out.println("[UpdateProfileServlet] No patient record found for accountId=" + accountId + ", returning session data");
                    try (PrintWriter out = response.getWriter()) {
                        out.print("{\"fullName\":\"" + escJson(currentUser.getFullName()) + "\","
                                + "\"email\":\""    + escJson(email) + "\","
                                + "\"phone\":\""    + escJson(nullToEmpty(currentUser.getPhone())) + "\","
                                + "\"gender\":\""   + escJson(nullToEmpty(currentUser.getGender())) + "\","
                                + "\"dob\":\""      + escJson(nullToEmpty(currentUser.getDob())) + "\","
                                + "\"address\":\""  + escJson(nullToEmpty(currentUser.getAddress())) + "\"}");
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"DB error: " + e.getMessage() + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        User currentUser = (User) request.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            response.setStatus(401);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        int accountId = currentUser.getId();
        String fullName = InputValidationUtil.trimToNull(request.getParameter("fullName"));
        String email    = InputValidationUtil.normalizeEmail(request.getParameter("email"));
        String phone    = InputValidationUtil.normalizeVietnamesePhone(request.getParameter("phone"));
        String gender   = InputValidationUtil.trimToNull(request.getParameter("gender"));
        String dob      = InputValidationUtil.trimToNull(request.getParameter("dob"));
        String address  = InputValidationUtil.trimToNull(request.getParameter("address"));

        if (fullName == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Full name is required\"}");
            return;
        }

        if (!InputValidationUtil.isValidEmail(email)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Email không đúng định dạng\"}");
            return;
        }

        if (!InputValidationUtil.isValidVietnameseMobilePhone(phone)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Số điện thoại phải là số di động Việt Nam hợp lệ, ví dụ 0912345678 hoặc +84912345678\"}");
            return;
        }

        if (gender == null || !ALLOWED_GENDERS.contains(gender)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Giới tính không hợp lệ\"}");
            return;
        }

        if (!isValidDateOfBirth(dob)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"error\":\"Ngày sinh phải hợp lệ, từ 01/01/1900 đến ngày hiện tại\"}");
            return;
        }

        if (userDAO.isEmailExistsForOtherAccount(email, accountId)) {
            response.setStatus(HttpServletResponse.SC_CONFLICT);
            response.getWriter().print("{\"error\":\"Email này đã được sử dụng bởi tài khoản khác\"}");
            return;
        }

        if (userDAO.isPatientPhoneExistsForOtherAccount(phone, accountId)) {
            response.setStatus(HttpServletResponse.SC_CONFLICT);
            response.getWriter().print("{\"error\":\"Số điện thoại này đã được sử dụng bởi bệnh nhân khác\"}");
            return;
        }

        System.out.println("[UpdateProfileServlet] Saving profile for accountId=" + accountId);

        String patientSql = "UPDATE Patient SET full_name=?, email=?, phone=?, gender=?, date_of_birth=?, address=? WHERE account_id=?";
        String accountSql = "UPDATE Account SET full_name=?, email=? WHERE account_id=? AND role='Patient'";
        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            int patientRows;
            try (PreparedStatement stmt = conn.prepareStatement(patientSql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, email);
                stmt.setString(3, phone);
                setNullableString(stmt, 4, gender, java.sql.Types.VARCHAR);
                setNullableString(stmt, 5, dob, java.sql.Types.DATE);
                setNullableString(stmt, 6, address, java.sql.Types.NVARCHAR);
                stmt.setInt(7, accountId);
                patientRows = stmt.executeUpdate();
            }

            if (patientRows == 0) {
                conn.rollback();
                System.out.println("[UpdateProfileServlet] No patient found for accountId=" + accountId);
                response.setStatus(404);
                response.getWriter().print("{\"error\":\"Patient not found\"}");
                return;
            }

            int accountRows;
            try (PreparedStatement stmt = conn.prepareStatement(accountSql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, email);
                stmt.setInt(3, accountId);
                accountRows = stmt.executeUpdate();
            }

            if (accountRows == 0) {
                throw new SQLException("Patient account not found");
            }

            new com.diabetes.monitoring.notification.NotificationService().notifyProfileUpdated(conn, accountId);

            conn.commit();

            currentUser.setFullName(fullName);
            currentUser.setEmail(email);
            currentUser.setPhone(phone);
            currentUser.setGender(gender);
            currentUser.setDob(dob);
            currentUser.setAddress(address);
            request.getSession().setAttribute("currentUser", currentUser);
            System.out.println("[UpdateProfileServlet] Profile saved successfully");
            response.getWriter().print("{\"success\":true}");
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    rollbackError.printStackTrace();
                }
            }
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().print("{\"error\":\"Unable to save profile\"}");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException closeError) {
                    closeError.printStackTrace();
                }
            }
        }
    }

    private String nullToEmpty(String v) { return v == null ? "" : v; }

    private boolean isValidDateOfBirth(String dob) {
        try {
            LocalDate dateOfBirth = LocalDate.parse(dob);
            return !dateOfBirth.isBefore(MIN_DATE_OF_BIRTH) && !dateOfBirth.isAfter(LocalDate.now());
        } catch (DateTimeParseException | NullPointerException e) {
            return false;
        }
    }

    private void setNullableString(PreparedStatement statement, int index, String value, int sqlType)
            throws SQLException {
        if (value == null) statement.setNull(index, sqlType);
        else statement.setString(index, value);
    }

    private String escJson(String v) {
        if (v == null) return "";
        return v.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "");
    }
}
