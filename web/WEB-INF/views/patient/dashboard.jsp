<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Tổng quan - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="dashboard" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">Tổng quan bệnh nhân</p>
                <h1>Xin chào, ${sessionScope.currentUser.fullName}</h1>
                <p>Theo dõi hồ sơ sức khỏe và các bước cần thực hiện.</p>
            </div>
        </header>

        <section class="shortcut-grid">
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/appointments/new">
                <i class="bi bi-calendar-plus"></i>
                <strong>Đặt lịch khám</strong>
                <span>Tìm bác sĩ có lịch trống và chọn giờ khám phù hợp.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/appointments">
                <i class="bi bi-calendar-check"></i>
                <strong>Lịch hẹn của tôi</strong>
                <span>Theo dõi thời gian, số thứ tự và trạng thái khám.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/invoices">
                <i class="bi bi-receipt"></i>
                <strong>Hóa đơn</strong>
                <span>Xem chi phí và trạng thái xác nhận thanh toán.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/history">
                <i class="bi bi-file-medical"></i>
                <strong>Lịch sử khám</strong>
                <span>Xem các lần khám và kết quả được bác sĩ công bố.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/ai-chat">
                <i class="bi bi-robot"></i>
                <strong>Chat với AI</strong>
                <span>Trao đổi thông tin sức khỏe để hỗ trợ quá trình khám.</span>
            </a>
            <a class="shortcut-card" href="${pageContext.request.contextPath}/patient/profile">
                <i class="bi bi-person-gear"></i>
                <strong>Thông tin cá nhân</strong>
                <span>Kiểm tra và cập nhật hồ sơ cá nhân.</span>
            </a>
        </section>

        <section class="page-card">
            <div class="page-card__header">
                <div>
                    <h2>Lần khám gần nhất</h2>
                    <p>Thông tin khám và trạng thái công bố kết quả mới nhất.</p>
                </div>
                <a href="${pageContext.request.contextPath}/patient/history">Xem tất cả</a>
            </div>
            <div id="latestRecord" class="loading-state">Đang tải lần khám gần nhất...</div>
        </section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/dashboard.js?v=20260709-fontfix2"></script>
</body>
</html>
