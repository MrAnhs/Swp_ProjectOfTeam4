<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Thông báo của tôi - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
    <style>
        .notification-list {
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }
        .notification-card {
            display: flex;
            align-items: flex-start;
            gap: 1rem;
            padding: 1.25rem;
            border-radius: var(--radius-md, 12px);
            border: 1px solid var(--color-border, #e2e8f0);
            background: #fff;
            transition: all 0.2s ease;
            position: relative;
            cursor: pointer;
        }
        .notification-card:hover {
            border-color: var(--color-primary, #0d9488);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
        }
        .notification-card.unread {
            background: #f0fdfa;
            border-left: 4px solid var(--color-primary, #0d9488);
        }
        .notification-icon-wrapper {
            display: grid;
            place-items: center;
            width: 42px;
            height: 42px;
            border-radius: 50%;
            background: #f1f5f9;
            color: #475569;
            flex-shrink: 0;
            font-size: 1.25rem;
        }
        .notification-card.unread .notification-icon-wrapper {
            background: #ccfbf1;
            color: var(--color-primary-dark, #115e59);
        }
        .notification-body {
            flex-grow: 1;
            min-width: 0;
        }
        .notification-title {
            font-size: 1rem;
            font-weight: 600;
            color: var(--color-text-dark, #0f172a);
            margin: 0 0 0.25rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .notification-content {
            font-size: 0.875rem;
            color: var(--color-text-muted, #475569);
            margin: 0;
            line-height: 1.5;
        }
        .notification-time {
            font-size: 0.75rem;
            color: var(--color-muted, #94a3b8);
            margin-top: 0.5rem;
            display: block;
        }
        .unread-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--color-primary, #0d9488);
            display: inline-block;
        }
        .empty-notifications {
            text-align: center;
            padding: 3rem 1.5rem;
            color: var(--color-muted, #94a3b8);
        }
        .empty-notifications i {
            font-size: 3.5rem;
            margin-bottom: 1rem;
            display: block;
            color: #cbd5e1;
        }
    </style>
</head>
<body>
    <c:set var="activePatientPage" value="notifications" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">Hệ thống</p>
                <h1>Thông báo của tôi</h1>
                <p>Xem các cập nhật sức khỏe, lịch tái khám và nhắc nhở từ bác sĩ.</p>
            </div>
            <button id="btnMarkAllRead" class="btn-page-secondary d-none">
                <i class="bi bi-check-all"></i> Đánh dấu tất cả đã đọc
            </button>
        </header>

        <section class="page-card">
            <div id="notificationsContainer" class="loading-state">
                Đang tải danh sách thông báo...
            </div>
        </section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/notifications.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>
