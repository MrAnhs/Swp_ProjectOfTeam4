<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="patient-search" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tìm bệnh nhân</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tra cứu</div>
        <h1 class="page-title">Tìm bệnh nhân</h1>
        <p class="page-subtitle">Nhập số điện thoại để xem thông tin bệnh nhân và lịch hẹn gần nhất.</p>

        <section class="panel-card mt-4">
            <div class="row g-3 align-items-end">
                <div class="col-md-8">
                    <label class="form-label fw-semibold" for="patientSearchPhone">Số điện thoại</label>
                    <input id="patientSearchPhone" class="form-control form-control-lg" placeholder="Ví dụ: 0912345678">
                </div>
                <div class="col-md-4 d-grid">
                    <button id="patientSearchBtn" class="btn btn-primary btn-lg" type="button">
                        <i class="bi bi-search me-1"></i>Tìm kiếm
                    </button>
                </div>
            </div>
        </section>

        <section id="patientSearchResult" class="result-card mt-4 d-none"></section>
        <section id="patientSearchEmpty" class="empty-state mt-4">Chưa có dữ liệu tra cứu.</section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/patient-search.js?v=20260709-fontfix2"></script>
</body>
</html>
