<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Th&#244;ng b&#225;o - DiabetesCare</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/notifications.css?v=20260715-notification3">
</head>
<body>
    <c:set var="activePatientPage" value="notifications" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash notification-page" data-notification-page data-context-path="${pageContext.request.contextPath}">
        <header class="page-header notification-page-header">
            <div>
                <p class="page-eyebrow">TRUNG T&#194;M TH&#212;NG B&#193;O</p>
                <h1>Th&#244;ng b&#225;o c&#7911;a t&#244;i</h1>
                <p>Theo d&#245;i c&#225;c c&#7853;p nh&#7853;t quan tr&#7885;ng t&#7915; h&#7879; th&#7889;ng DiabetesCare.</p>
            </div>
            <button type="button" class="notification-refresh-button" data-notification-refresh>
                <i class="bi bi-arrow-clockwise"></i><span>L&#224;m m&#7899;i</span>
            </button>
        </header>

        <section class="notification-overview" aria-label="T&#7893;ng quan th&#244;ng b&#225;o">
            <article class="notification-stat-card">
                <span class="notification-stat-icon"><i class="bi bi-bell"></i></span>
                <div><strong data-notification-total>0</strong><span>T&#7893;ng th&#244;ng b&#225;o</span></div>
            </article>
            <article class="notification-stat-card unread">
                <span class="notification-stat-icon"><i class="bi bi-envelope-exclamation"></i></span>
                <div><strong data-notification-unread>0</strong><span>Ch&#432;a &#273;&#7885;c</span></div>
            </article>
        </section>

        <section class="notification-panel">
            <div class="notification-panel-header">
                <div>
                    <h2>Th&#244;ng b&#225;o g&#7847;n &#273;&#226;y</h2>
                    <p data-notification-description>Hi&#7875;n th&#7883; 5 th&#244;ng b&#225;o m&#7899;i nh&#7845;t.</p>
                </div>
                <div class="notification-filter-group" role="group" aria-label="B&#7897; l&#7885;c th&#244;ng b&#225;o">
                    <button type="button" class="notification-filter active" data-notification-filter="recent">G&#7847;n &#273;&#226;y</button>
                    <button type="button" class="notification-filter" data-notification-filter="all">T&#7845;t c&#7843;</button>
                </div>
            </div>
            <div class="patient-notification-list" data-notification-list aria-live="polite">
                <div class="notification-page-loading"><span class="notification-spinner"></span>&#272;ang t&#7843;i th&#244;ng b&#225;o...</div>
            </div>
            <div class="notification-panel-footer" data-notification-footer hidden>
                <button type="button" class="notification-view-more" data-notification-view-all>
                    Xem t&#7845;t c&#7843; th&#244;ng b&#225;o <i class="bi bi-arrow-right"></i>
                </button>
            </div>
        </section>
    </main>

    <script defer src="${pageContext.request.contextPath}/assets/js/pages/patient/notifications.js?v=20260715-notification3"></script>
</body>
</html>

