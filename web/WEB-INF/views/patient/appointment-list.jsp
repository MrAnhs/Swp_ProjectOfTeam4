<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Lịch hẹn của tôi - DiabetesCare</title>
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
                <p class="page-eyebrow">Lịch khám</p>
                <h1>Lịch hẹn của tôi</h1>
                <p>Theo dõi bác sĩ, thời gian, số thứ tự và trạng thái khám.</p>
            </div>
            <a class="btn-page-primary" href="${pageContext.request.contextPath}/patient/appointments/new">
                <i class="bi bi-calendar-plus"></i> Đặt lịch mới
            </a>
        </header>

        <section class="page-card">
            <div class="filter-bar">
                <label>Trạng thái
                    <select id="appointmentStatusFilter">
                        <option value="">Tất cả</option>
                        <option value="Waiting">Chờ khám</option>
                        <option value="In_Progress">Đang khám</option>
                        <option value="Completed">Đã hoàn thành</option>
                        <option value="Cancelled">Đã hủy</option>
                        <option value="Absent">Vắng mặt</option>
                    </select>
                </label>
                <label>Tìm kiếm
                    <input id="appointmentSearch" type="search" placeholder="Mã lịch hẹn, bác sĩ hoặc chuyên khoa">
                </label>
            </div>
            <div id="appointmentList" class="record-list loading-state">
                Đang tải danh sách lịch hẹn...
            </div>
        </section>
    </main>

    <script src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-status.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-list.js"></script>
</body>
</html>
