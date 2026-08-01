package com.diabetes.monitoring.profile;

import com.diabetes.monitoring.model.User;
import com.diabetes.monitoring.verification.EmailVerificationService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Timestamp;

public class ProfileServlet extends HttpServlet {
    private final ProfileService profileService = new ProfileService();
    private final EmailVerificationService verificationService =
            new EmailVerificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = currentUser(request.getSession(false));
        if (user != null && "admin".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/admin");
            return;
        }
        String path = request.getPathInfo();
        if (path == null || "/".equals(path)) {
            if (user == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
            if ("patient".equals(role)) {
                response.sendRedirect(request.getContextPath() + "/patient/dashboard");
            } else if ("receptionist".equals(role)) {
                response.sendRedirect(request.getContextPath() + "/receptionist/dashboard");
            } else if ("doctor".equals(role)) {
                response.sendRedirect(request.getContextPath() + "/doctor/dashboard");
            } else if ("doctor_lab".equals(role) || "doctor-lab".equals(role)) {
                response.sendRedirect(request.getContextPath() + "/doctor-lab/dashboard");
            } else if ("admin".equals(role)) {
                response.sendRedirect(request.getContextPath() + "/admin");
            } else {
                request.getRequestDispatcher("/WEB-INF/views/settings.jsp").forward(request, response);
            }
            return;
        }
        if ("/profile".equals(path) || "/account".equals(path)) {
            writeProfile(response, request);
            return;
        }
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        String path = request.getPathInfo();
        if (!"/profile".equals(path)
                && !"/email/request-otp".equals(path)
                && !"/email/confirm".equals(path)
                && !"/password".equals(path)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        User user = currentUser(request.getSession(false));
        if (user == null) { writeError(response, 401, "Phi\u00EAn \u0111\u0103ng nh\u1EADp \u0111\u00E3 h\u1EBFt h\u1EA1n"); return; }
        if ("admin".equalsIgnoreCase(user.getRole())) { writeError(response, 403, "T\u00E0i kho\u1EA3n Admin kh\u00F4ng s\u1EFD d\u1EE5ng trang c\u00E0i \u0111\u1EB7t c\u00E1 nh\u00E2n"); return; }
        try {
            if ("/email/request-otp".equals(path)) {
                verificationService.requestEmailChange(user,
                        request.getParameter("newEmail"),
                        request.getParameter("currentPassword"));
                writeJson(response, "{\"success\":true,\"expiresInSeconds\":300}");
                return;
            }
            if ("/email/confirm".equals(path)) {
                verificationService.confirmEmailChange(user,
                        request.getParameter("newEmail"), request.getParameter("otp"));
                writeJson(response, "{\"success\":true}");
                return;
            }
            if ("/password".equals(path)) {
                profileService.changePassword(user, request.getParameter("currentPassword"), request.getParameter("newPassword"), request.getParameter("confirmation"));
                writeJson(response, "{\"success\":true}");
                return;
            }
            Profile profile = new Profile();
            profile.setFullName(request.getParameter("fullName"));
            profile.setEmail(user.getEmail());
            profile.setPhone(request.getParameter("phone"));
            profile.setDateOfBirth(request.getParameter("dateOfBirth"));
            profile.setGender(request.getParameter("gender"));
            profile.setAddress(request.getParameter("address"));
            profileService.update(user, profile);

            String newPassword = request.getParameter("newPassword");
            if (newPassword != null && !newPassword.isBlank()) {
                profileService.updatePasswordDirectly(user, newPassword);
            }
            writeJson(response, "{\"success\":true}");
        } catch (IllegalArgumentException e) {
            writeError(response, 400, e.getMessage());
        } catch (Exception e) {
            getServletContext().log("Không thể cập nhật hồ sơ", e);
            writeError(response, 500, "Không thể cập nhật thông tin hồ sơ");
        }
    }

    private void writeProfile(HttpServletResponse response, HttpServletRequest request) throws IOException {
        User user = currentUser(request.getSession(false));
        if (user == null) { writeError(response, 401, "Phiên đăng nhập đã hết hạn"); return; }
        try {
            Profile p = profileService.load(user);
            if (p == null) { writeError(response, 404, "Không tìm thấy hồ sơ"); return; }
            String json = "{"
                    + "\"accountId\":" + p.getAccountId() + ","
                    + "\"role\":\"" + esc(p.getRole()) + "\","
                    + "\"fullName\":\"" + esc(p.getFullName()) + "\","
                    + "\"email\":\"" + esc(p.getEmail()) + "\","
                    + "\"phone\":\"" + esc(p.getPhone()) + "\","
                    + "\"dateOfBirth\":\"" + esc(p.getDateOfBirth()) + "\","
                    + "\"gender\":\"" + esc(p.getGender()) + "\","
                    + "\"address\":\"" + esc(p.getAddress()) + "\","
                    + "\"department\":\"" + esc(p.getDepartment()) + "\","
                    + "\"labName\":\"" + esc(p.getLabName()) + "\","
                    + "\"deskLocation\":\"" + esc(p.getDeskLocation()) + "\","
                    + "\"createdAt\":\"" + esc(timestamp(p.getCreatedAt())) + "\""
                    + "}";
            writeJson(response, json);
        } catch (IllegalArgumentException e) { writeError(response, 403, e.getMessage()); }
        catch (Exception e) { getServletContext().log("Không thể tải hồ sơ", e); writeError(response, 500, "Không thể tải thông tin hồ sơ"); }
    }

    private User currentUser(HttpSession session) { return session == null ? null : (User) session.getAttribute("currentUser"); }
    private void writeJson(HttpServletResponse response, String body) throws IOException {
        response.setContentType("application/json"); response.setCharacterEncoding("UTF-8"); response.getWriter().print(body);
    }
    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status); writeJson(response, "{\"error\":\"" + esc(message) + "\"}");
    }
    private String timestamp(Timestamp value) { return value == null ? "" : value.toLocalDateTime().toString(); }
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", "\\n");
    }
}
