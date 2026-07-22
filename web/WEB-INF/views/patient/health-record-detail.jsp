<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Chi tiết hồ sơ - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="records" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header">
            <div><p class="page-eyebrow">Hồ sơ sức khỏe</p><h1 id="recordTitle">Chi tiết hồ sơ</h1><p id="recordMeta">Đang tải thông tin...</p></div>
            <a class="btn-page-secondary" href="${pageContext.request.contextPath}/patient/health-records"><i class="bi bi-arrow-left"></i> Quay lại lịch sử</a>
        </header>
        <section class="page-card">
            <nav class="detail-tabs" aria-label="Chi tiết hồ sơ">
                <button class="active" data-tab-target="overviewTab">Tổng quan</button>
                <button data-tab-target="diagnosisTab">Chẩn đoán</button>
                <button data-tab-target="chatHistoryTab">Tóm tắt & Lịch sử AI</button>
            </nav>
            <div id="overviewTab" class="detail-tab active loading-state">Đang tải hồ sơ...</div>
            <div id="diagnosisTab" class="detail-tab loading-state">Chọn tab để tải chẩn đoán.</div>
            <div id="chatHistoryTab" class="detail-tab loading-state">Chọn tab để tải tóm tắt & lịch sử AI.</div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-detail.js"></script>
</body>
</html>
