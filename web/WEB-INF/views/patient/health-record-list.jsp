<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Lịch sử hồ sơ - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="records" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header">
            <div><p class="page-eyebrow">Hồ sơ sức khỏe</p><h1>Lịch sử hồ sơ</h1><p>Theo dõi các hồ sơ đã gửi và trạng thái xử lý.</p></div>
            <a class="btn-page-primary" href="${pageContext.request.contextPath}/patient/health-records/new"><i class="bi bi-plus-circle"></i> Nộp hồ sơ mới</a>
        </header>
        <section class="page-card">
            <div class="filter-bar">
                <label>Trạng thái
                    <select id="statusFilter"><option value="">Tất cả</option><option value="pending">Chờ xử lý</option><option value="approved">Đã duyệt</option></select>
                </label>
                <label>Tìm kiếm<input id="recordSearch" type="search" placeholder="Mã hồ sơ hoặc triệu chứng"></label>
            </div>
            <div id="recordList" class="record-list loading-state">Đang tải danh sách hồ sơ...</div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-list.js"></script>
</body>
</html>
