<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Thông báo - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260801">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260801">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/notifications.css?v=20260801">
</head>
<body class="master-ui-body master-ui-dark">
    <c:set var="activePatientPage" value="notifications" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash notification-page" data-notification-page data-context-path="${pageContext.request.contextPath}">
        <header class="page-header notification-page-header">
            <div>
                <p class="page-eyebrow fw-bold text-uppercase" style="color: #2AB5A3;">TRUNG TÂM THÔNG BÁO</p>
                <h1 class="fw-bold text-white my-1" style="font-size: 2rem;">Thông báo của tôi</h1>
                <p class="text-white-50 mb-0" style="font-size: 0.95rem;">Theo dõi các cập nhật quan trọng từ hệ thống DiabetesCare.</p>
            </div>
            <button type="button" class="notification-refresh-button" data-notification-refresh>
                <i class="bi bi-arrow-clockwise"></i><span>Làm mới</span>
            </button>
        </header>

        <section class="notification-overview" aria-label="Tổng quan thông báo">
            <article class="notification-stat-card">
                <span class="notification-stat-icon"><i class="bi bi-bell"></i></span>
                <div><strong data-notification-total>0</strong><span style="font-size: 0.9rem; color: #94A3B8;">Tổng thông báo</span></div>
            </article>
            <article class="notification-stat-card unread">
                <span class="notification-stat-icon"><i class="bi bi-envelope-exclamation"></i></span>
                <div><strong data-notification-unread>0</strong><span style="font-size: 0.9rem; color: #94A3B8;">Chưa đọc</span></div>
            </article>
        </section>

        <section class="notification-panel">
            <div class="notification-panel-header">
                <div>
                    <h2 class="fw-bold text-white mb-1" style="font-size: 1.25rem;">Thông báo gần đây</h2>
                    <p data-notification-description style="font-size: 0.9rem; color: #94A3B8;">Hiển thị 5 thông báo mới nhất.</p>
                </div>
                <div class="notification-filter-group" role="group" aria-label="Bộ lọc thông báo">
                    <button type="button" class="notification-filter active" data-notification-filter="recent">Gần đây</button>
                    <button type="button" class="notification-filter" data-notification-filter="all">Tất cả</button>
                </div>
            </div>
            <div class="patient-notification-list" data-notification-list aria-live="polite">
                <div class="notification-page-loading"><span class="notification-spinner"></span>Đang tải thông báo...</div>
            </div>
            <div class="notification-panel-footer" data-notification-footer hidden>
                <button type="button" class="notification-view-more" data-notification-view-all>
                    Xem tất cả thông báo <i class="bi bi-arrow-right"></i>
                </button>
            </div>
        </section>
    </main>

<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
<script defer src="${pageContext.request.contextPath}/assets/js/pages/patient/notifications.js?v=20260725-redirectfix2"></script>
</body>
</html>
