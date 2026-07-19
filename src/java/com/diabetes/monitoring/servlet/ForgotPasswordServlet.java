package com.diabetes.monitoring.servlet;

import com.diabetes.monitoring.verification.EmailVerificationService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

public class ForgotPasswordServlet extends HttpServlet {
    private static final String RESET_ACCOUNT_ID =
            ForgotPasswordServlet.class.getName() + ".resetAccountId";
    private static final String RESET_GRANTED_UNTIL =
            ForgotPasswordServlet.class.getName() + ".resetGrantedUntil";
    private final EmailVerificationService verificationService =
            new EmailVerificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String path = request.getPathInfo();
        if (path == null || "/".equals(path)) {
            clearGrant(request.getSession(false));
            request.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp")
                    .forward(request, response);
            return;
        }
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        request.setCharacterEncoding("UTF-8");
        String path = request.getPathInfo();
        if ("/request".equals(path)) {
            requestOtp(request, response);
            return;
        }
        if ("/verify".equals(path)) {
            verifyOtp(request, response);
            return;
        }
        if ("/reset".equals(path)) {
            resetPassword(request, response);
            return;
        }
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    private void requestOtp(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        clearGrant(request.getSession(false));
        try {
            verificationService.requestPasswordReset(request.getParameter("email"));
        } catch (Exception e) {
            getServletContext().log("Unable to deliver password reset OTP", e);
        }
        writeJson(response, "{\"success\":true,\"expiresInSeconds\":300,"
                + "\"message\":\"N\u1EBFu email t\u1ED3n t\u1EA1i, m\u00E3 x\u00E1c th\u1EF1c \u0111\u00E3 \u0111\u01B0\u1EE3c g\u1EEDi.\"}");
    }

    private void verifyOtp(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            int accountId = verificationService.verifyPasswordResetOtp(
                    request.getParameter("email"), request.getParameter("otp"));
            HttpSession session = request.getSession(true);
            clearGrant(session);
            session.setAttribute(RESET_ACCOUNT_ID, accountId);
            session.setAttribute(RESET_GRANTED_UNTIL,
                    System.currentTimeMillis()
                            + EmailVerificationService.RESET_GRANT_MINUTES * 60_000L);
            writeJson(response, "{\"success\":true}");
        } catch (IllegalArgumentException e) {
            writeError(response, 400, e.getMessage());
        } catch (Exception e) {
            getServletContext().log("Unable to verify password reset OTP", e);
            writeError(response, 500,
                    "Kh\u00F4ng th\u1EC3 x\u00E1c th\u1EF1c m\u00E3 l\u00FAc n\u00E0y");
        }
    }

    private void resetPassword(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        Integer accountId = session == null ? null
                : (Integer) session.getAttribute(RESET_ACCOUNT_ID);
        Long grantedUntil = session == null ? null
                : (Long) session.getAttribute(RESET_GRANTED_UNTIL);
        if (accountId == null || grantedUntil == null
                || grantedUntil < System.currentTimeMillis()) {
            clearGrant(session);
            writeError(response, 403,
                    "Phi\u00EAn \u0111\u1EB7t l\u1EA1i m\u1EADt kh\u1EA9u kh\u00F4ng h\u1EE3p l\u1EC7 ho\u1EB7c \u0111\u00E3 h\u1EBFt h\u1EA1n");
            return;
        }
        try {
            verificationService.resetPassword(accountId,
                    request.getParameter("newPassword"),
                    request.getParameter("confirmation"));
            clearGrant(session);
            writeJson(response, "{\"success\":true}");
        } catch (IllegalArgumentException e) {
            writeError(response, 400, e.getMessage());
        } catch (Exception e) {
            getServletContext().log("Unable to reset password", e);
            writeError(response, 500,
                    "Kh\u00F4ng th\u1EC3 \u0111\u1EB7t l\u1EA1i m\u1EADt kh\u1EA9u l\u00FAc n\u00E0y");
        }
    }

    private void clearGrant(HttpSession session) {
        if (session == null) return;
        session.removeAttribute(RESET_ACCOUNT_ID);
        session.removeAttribute(RESET_GRANTED_UNTIL);
    }

    private void writeJson(HttpServletResponse response, String body) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(body);
    }

    private void writeError(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        writeJson(response, "{\"error\":\"" + escape(message) + "\"}");
    }

    private String escape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\r", "").replace("\n", "\\n");
    }
}
