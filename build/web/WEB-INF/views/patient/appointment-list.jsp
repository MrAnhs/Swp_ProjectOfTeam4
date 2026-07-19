<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>L&#7883;ch h&#7865;n c&#7911;a t&#244;i - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="appointments" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">L&#7883;ch kh&#225;m</p>
                <h1>L&#7883;ch h&#7865;n c&#7911;a t&#244;i</h1>
                <p>Theo d&#245;i b&#225;c s&#297;, ph&#242;ng kh&#225;m, th&#7901;i gian, s&#7889; th&#7913; t&#7921; v&#224; tr&#7841;ng th&#225;i kh&#225;m.</p>
            </div>
            <a class="btn-page-primary" href="${pageContext.request.contextPath}/patient/appointments/new">
                <i class="bi bi-calendar-plus"></i> &#272;&#7863;t l&#7883;ch m&#7899;i
            </a>
        </header>

        <section class="page-card">
            <div class="filter-row patient-search-bar">
                <label>Tr&#7841;ng th&#225;i
                    <select id="appointmentStatusFilter">
                        <option value="">T&#7845;t c&#7843;</option>
                        <option value="Waiting">Ch&#7901; kh&#225;m</option>
                        <option value="In_Progress">&#272;ang kh&#225;m</option>
                        <option value="Completed">&#272;&#227; ho&#224;n th&#224;nh</option>
                        <option value="Cancelled">&#272;&#227; h&#7911;y</option>
                        <option value="Absent">V&#7855;ng m&#7863;t</option>
                    </select>
                </label>
                <label>T&#236;m ki&#7871;m
                    <input id="appointmentSearch" type="search" placeholder="M&#227; l&#7883;ch h&#7865;n, b&#225;c s&#297;, chuy&#234;n khoa ho&#7863;c ph&#242;ng kh&#225;m">
                </label>
                <label>Ng&#224;y kh&#225;m
                    <input id="appointmentDateFilter" type="date">
                </label>
            </div>
            <div id="appointmentList" class="record-list loading-state">
                &#272;ang t&#7843;i danh s&#225;ch l&#7883;ch h&#7865;n...
            </div>
        </section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-status.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-list.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>
