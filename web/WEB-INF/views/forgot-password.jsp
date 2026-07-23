<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Quên mật khẩu - DiabetesCare</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/public/forgot-password.css">
</head>
<body class="forgot-page">
    <main class="forgot-card">
        <a class="forgot-brand" href="${pageContext.request.contextPath}/">
            <span>+</span><strong>DiabetesCare</strong>
        </a>
        <div class="forgot-progress" aria-label="Tiến trình khôi phục mật khẩu">
            <span class="active" data-progress="request">1</span><i></i>
            <span data-progress="verify">2</span><i></i>
            <span data-progress="reset">3</span>
        </div>

        <section data-step="request">
            <p class="forgot-eyebrow">KHÔI PHỤC TÀI KHOẢN</p>
            <h1>Quên mật khẩu</h1>
            <p class="forgot-description">Nhập email đã đăng ký. Nếu tài khoản tồn tại, hệ thống sẽ gửi một mã xác thực gồm 6 chữ số.</p>
            <form id="requestOtpForm" novalidate>
                <label>Email tài khoản<input id="resetEmail" type="email" autocomplete="email" required placeholder="tenban@example.com"></label>
                <button type="submit" class="forgot-primary">Gửi mã xác thực</button>
            </form>
        </section>

        <section data-step="verify" hidden>
            <p class="forgot-eyebrow">XÁC THỰC EMAIL</p>
            <h1>Nhập mã xác thực</h1>
            <p class="forgot-description">Mã đã được gửi nếu email <strong id="resetEmailDisplay"></strong> thuộc một tài khoản đang hoạt động. Mã có hiệu lực trong 5 phút.</p>
            <form id="verifyOtpForm" novalidate>
                <label>Mã xác thực<input id="resetOtp" class="otp-input" type="text" inputmode="numeric" autocomplete="one-time-code" maxlength="6" pattern="[0-9]{6}" required placeholder="000000"></label>
                <button type="submit" class="forgot-primary">Xác nhận mã</button>
            </form>
            <div class="forgot-resend">
                <button type="button" id="resendResetOtp" disabled>Gửi lại mã</button>
                <span id="resetOtpCountdown" aria-live="polite"></span>
            </div>
            <button type="button" class="forgot-back-step" data-back="request">Đổi email khác</button>
        </section>

        <section data-step="reset" hidden>
            <p class="forgot-eyebrow">MẬT KHẨU MỚI</p>
            <h1>Đặt lại mật khẩu</h1>
            <p class="forgot-description">Mật khẩu mới phải có ít nhất 8 ký tự.</p>
            <form id="resetPasswordForm" novalidate>
                <label>Mật khẩu mới<input id="resetNewPassword" type="password" autocomplete="new-password" minlength="8" required></label>
                <label>Xác nhận mật khẩu mới<input id="resetPasswordConfirmation" type="password" autocomplete="new-password" minlength="8" required></label>
                <button type="submit" class="forgot-primary">Đặt lại mật khẩu</button>
            </form>
        </section>

        <section data-step="success" hidden>
            <div class="forgot-success-icon">&#10003;</div>
            <h1>Đổi mật khẩu thành công</h1>
            <p class="forgot-description">Bạn có thể đăng nhập bằng mật khẩu mới.</p>
            <a class="forgot-primary forgot-login-link" href="${pageContext.request.contextPath}/login.jsp">Quay lại đăng nhập</a>
        </section>

        <p id="forgotMessage" class="forgot-message" hidden role="alert"></p>
        <a class="forgot-login" href="${pageContext.request.contextPath}/login.jsp">&larr; Trở về đăng nhập</a>
    </main>
    <script src="${pageContext.request.contextPath}/assets/js/pages/public/forgot-password.js?v=20260715-otp1"></script>
</body>
</html>
