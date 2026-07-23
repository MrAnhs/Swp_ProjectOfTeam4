<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Thông báo - DiabetesCare</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/components/notification-bell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/notifications.css">
</head>
<body class="notifications-page">
    <main class="notifications-container" data-notifications-page data-context-path="${pageContext.request.contextPath}">
        <a class="notifications-back" href="javascript:history.back()">← Quay lại</a>
        <div class="notifications-heading">
            <div>
                <p class="notifications-eyebrow">TRUNG TÂM THÔNG BÁO</p>
                <h1>Thông báo</h1>
                <p>Danh sách các thông báo dành cho tài khoản của bạn.</p>
            </div>
            <button type="button" class="notifications-refresh" data-notifications-refresh>Tải lại</button>
        </div>
        <section class="notifications-card">
            <div class="notifications-list" data-notifications-list>
                <p class="notification-empty">Đang tải thông báo...</p>
            </div>
        </section>
    </main>
    <script defer src="${pageContext.request.contextPath}/assets/js/pages/notifications.js?v=20260715-notification2"></script>
</body>
</html>
