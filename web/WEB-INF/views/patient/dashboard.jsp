<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>T&#7893;ng quan - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="dashboard" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">T&#7893;ng quan b&#7879;nh nh&#226;n</p>
                <h1>Xin ch&#224;o, ${sessionScope.currentUser.fullName}</h1>
                <p>Theo d&#245;i h&#7891; s&#417; s&#7913;c kh&#7887;e v&#224; c&#225;c b&#432;&#7899;c c&#7847;n th&#7921;c hi&#7879;n.</p>
            </div>
        </header>

        <section class="shortcut-grid">
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/appointments/new">
                <i class="bi bi-calendar-plus"></i>
                <strong>&#272;&#7863;t l&#7883;ch kh&#225;m</strong>
                <span>T&#236;m b&#225;c s&#297; c&#243; l&#7883;ch tr&#7889;ng v&#224; ch&#7885;n gi&#7901; kh&#225;m ph&#249; h&#7907;p.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/appointments">
                <i class="bi bi-calendar-check"></i>
                <strong>L&#7883;ch h&#7865;n c&#7911;a t&#244;i</strong>
                <span>Theo d&#245;i th&#7901;i gian, s&#7889; th&#7913; t&#7921; v&#224; tr&#7841;ng th&#225;i kh&#225;m.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/invoices">
                <i class="bi bi-receipt"></i>
                <strong>H&#243;a &#273;&#417;n</strong>
                <span>Xem chi ph&#237; v&#224; tr&#7841;ng th&#225;i x&#225;c nh&#7853;n thanh to&#225;n.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/history">
                <i class="bi bi-file-medical"></i>
                <strong>L&#7883;ch s&#7917; kh&#225;m</strong>
                <span>Xem c&#225;c l&#7847;n kh&#225;m v&#224; k&#7871;t qu&#7843; &#273;&#432;&#7907;c b&#225;c s&#297; c&#444;ng b&#7889;.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/ai-chat">
                <i class="bi bi-robot"></i>
                <strong>Chat v&#7899;i AI</strong>
                <span>Trao &#273;&#7893;i th&#244;ng tin s&#7913;c kh&#7887;e &#273;&#7875; h&#7895; tr&#7907; qu&#225; tr&#236;nh kh&#225;m.</span>
            </a>
            <a class="shortcut-card" href="javascript:void(0)" onclick="openGlobalEditProfileModal()">
                <i class="bi bi-person-gear"></i>
                <strong>Th&#244;ng tin c&#225; nh&#226;n</strong>
                <span>Ki&#7875;m tra v&#224; c&#7853;p nh&#7853;t h&#7891; s&#417; c&#225; nh&#226;n.</span>
            </a>
        </section>

        <section class="card-lab-style page-card p-0">
            <div class="card-lab-header page-card__header px-4 py-3">
                <div>
                    <h2><i class="bi bi-journal-medical"></i> L&#7847;n kh&#225;m g&#7847;n nh&#7845;t</h2>
                    <p class="mb-0">Th&#244;ng tin kh&#225;m v&#224; tr&#7841;ng th&#225;i c&#244;ng b&#7889; k&#7871;t qu&#7843; m&#7899;i nh&#7845;t.</p>
                </div>
                <a href="${pageContext.request.contextPath}/patient/history" class="btn-action-lab btn-lab-primary">
                    <i class="bi bi-arrow-right-short"></i> Xem t&#7845;t c&#7843;
                </a>
            </div>
            <div class="p-3">
                <div id="latestRecord" class="loading-state">&#272;ang t&#7843;i l&#7847;n kh&#225;m g&#7847;n nh&#7845;t...</div>
            </div>
        </section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-status.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/dashboard.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>
