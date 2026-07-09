<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Thông tin cá nhân - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="profile" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header"><div><p class="page-eyebrow">Tài khoản</p><h1>Thông tin cá nhân</h1><p>Cập nhật thông tin liên hệ và hồ sơ bệnh nhân.</p></div></header>
        <section class="page-card">
            <form id="profileForm" class="record-form">
                <div class="form-grid form-grid--two">
                    <label>Họ tên<input id="profileName" name="fullName" required></label>
                    <label>Email<input id="profileEmail" type="email" name="email" required></label>
                    <label>Số điện thoại<input id="profilePhone" name="phone" type="tel" inputmode="tel" pattern="(0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7}|(\+?84)(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])[0-9]{7})" required></label>
                    <label>Giới tính
                        <select id="profileGender" name="gender" required>
                            <option value="">Chọn giới tính</option>
                            <option value="male">Nam</option>
                            <option value="female">Nữ</option>
                            <option value="other">Khác</option>
                        </select>
                    </label>
                    <label>Ngày sinh<input id="profileDob" type="date" name="dob" min="1900-01-01" required></label>
                </div>
                <label class="form-field-full">Địa chỉ<textarea id="profileAddress" name="address" rows="3"></textarea></label>
                <div id="profileMessage" class="form-message" hidden></div>
                <div class="form-actions"><button class="btn-page-primary" type="submit"><i class="bi bi-check-circle"></i> Lưu thay đổi</button></div>
            </form>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/profile.js?v=20260709-fontfix2"></script>
</body>
</html>
