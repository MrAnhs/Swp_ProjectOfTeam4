<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Cài đặt - DiabetesCare</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/settings/settings.css">
</head>
<body class="settings-page">
    <aside class="settings-sidebar">
        <a class="settings-brand" href="${pageContext.request.contextPath}/">
            <span class="settings-brand-icon">+</span><strong>DiabetesCare</strong>
        </a>
        <div class="settings-user">
            <span class="settings-avatar"><c:out value="${sessionScope.currentUser.fullName.substring(0, 1)}" default="U" /></span>
            <span><strong><c:out value="${sessionScope.currentUser.fullName}" default="Người dùng" /></strong><small>Cài đặt tài khoản</small></span>
        </div>
        <a class="settings-back" href="javascript:history.back()">← Quay lại</a>
    </aside>

    <main class="settings-main">
        <header class="settings-header">
            <p class="settings-eyebrow">TÀI KHOẢN</p>
            <h1>Cài đặt</h1>
            <p>Quản lý thông tin cá nhân và thông tin tài khoản của bạn.</p>
        </header>

        <nav class="settings-tabs" aria-label="Các mục cài đặt">
            <button type="button" class="settings-tab active" data-tab="personal">Thông tin cá nhân</button>
            <button type="button" class="settings-tab" data-tab="account">Thông tin tài khoản</button>
        </nav>

        <section class="settings-panel" data-panel="personal">
            <div class="settings-panel-heading">
                <div><span class="settings-icon">◉</span><h2>Thông tin cá nhân</h2></div>
                <button type="button" class="settings-action" data-edit="personal">✎ Chỉnh sửa</button>
            </div>
            <form id="personalForm" class="settings-form" novalidate>
                <div class="settings-grid">
                    <label>Họ và tên<input name="fullName" data-field="fullName" readonly required></label>
                    <label>Ngày sinh<input type="date" name="dateOfBirth" data-field="dateOfBirth" readonly></label>
                    <label>Giới tính<select name="gender" data-field="gender" disabled><option value="">Chưa cập nhật</option><option value="male">Nam</option><option value="female">Nữ</option><option value="other">Khác</option></select></label>
                    <label>Số điện thoại<input name="phone" data-field="phone" readonly required></label>
                    <label class="settings-wide">Địa chỉ<textarea name="address" data-field="address" readonly rows="3"></textarea></label>
                </div>
                <c:set var="settingsRole" value="${fn:toLowerCase(sessionScope.currentUser.role)}" />
                <c:if test="${settingsRole eq 'doctor'}">
                    <div class="settings-readonly"><span>Khoa / chuyên khoa</span><strong data-field="department">Chưa cập nhật</strong></div>
                </c:if>
                <c:if test="${settingsRole eq 'doctor_lab' or settingsRole eq 'doctor-lab'}">
                    <div class="settings-readonly"><span>Phòng xét nghiệm</span><strong data-field="labName">Chưa cập nhật</strong></div>
                </c:if>
                <c:if test="${settingsRole eq 'receptionist'}">
                    <div class="settings-readonly"><span>Vị trí quầy</span><strong data-field="deskLocation">Chưa cập nhật</strong></div>
                </c:if>
                <div class="settings-form-actions" data-edit-actions="personal" hidden style="display:none"><button type="button" class="settings-secondary" data-cancel="personal">Hủy</button><button class="settings-primary" type="submit">Lưu thông tin</button></div>
            </form>
        </section>

        <section class="settings-panel" data-panel="account" hidden>
            <div class="settings-panel-heading"><div><span class="settings-icon">↪</span><h2>Thông tin tài khoản</h2></div></div>
            <div class="settings-grid account-grid">
                <div class="settings-value"><span>Email</span><strong data-field="email">Chưa cập nhật</strong></div>
                <div class="settings-value"><span>Số điện thoại</span><strong data-field="accountPhone">Chưa cập nhật</strong><small>Có thể thay đổi tại mục Thông tin cá nhân.</small></div>
                <div class="settings-value"><span>Phương thức đăng nhập</span><strong>Email và mật khẩu</strong></div>
                <div class="settings-value"><span>Ngày tạo tài khoản</span><strong data-field="createdAt">Chưa cập nhật</strong></div>
            </div>
            <div class="settings-account-actions"><button type="button" class="settings-primary" data-action="email">Đổi email</button><button type="button" class="settings-secondary" data-action="password">Đổi mật khẩu</button></div>
            <p class="settings-message" id="settingsMessage" hidden></p>
        </section>
        <p class="settings-message" id="personalMessage" hidden></p>
    </main>
    <dialog id="accountDialog" class="settings-dialog">
        <form method="dialog" id="accountDialogForm">
            <button class="dialog-close" value="cancel" aria-label="Đóng">×</button>
            <h2 id="dialogTitle">Cập nhật tài khoản</h2>
            <div id="emailFields" hidden><label>Email mới<input id="newEmail" type="email"></label><label>Mật khẩu hiện tại<input id="emailPassword" type="password"></label></div>
            <div id="passwordFields" hidden><label>Mật khẩu hiện tại<input id="currentPassword" type="password"></label><label>Mật khẩu mới<input id="newPassword" type="password" minlength="8"></label><label>Xác nhận mật khẩu mới<input id="passwordConfirmation" type="password" minlength="8"></label></div>
            <p class="settings-message" id="dialogMessage" hidden></p>
            <button class="settings-primary" id="dialogSubmit" value="default" type="submit">Lưu thay đổi</button>
        </form>
    </dialog>
    <script src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/settings/settings.js?v=20260714-profile5"></script>
</body>
</html>
