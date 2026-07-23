<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="schedule" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lịch trực của tôi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css" rel="stylesheet">
    <style>
        .schedule-grid {
            display: grid;
            grid-template-columns: 100px repeat(7, 1fr);
            gap: 1px;
            background-color: #dee2e6;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
            margin-top: 20px;
        }
        .schedule-header {
            background-color: #f8f9fa;
            padding: 15px;
            text-align: center;
            font-weight: 600;
        }
        .schedule-time {
            background-color: #f8f9fa;
            padding: 15px;
            text-align: center;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .schedule-cell {
            background-color: #fff;
            padding: 10px;
            min-height: 100px;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .schedule-item {
            background-color: #e3f2fd;
            border-left: 4px solid #0d6efd;
            padding: 8px;
            border-radius: 4px;
            font-size: 0.875rem;
        }
        .schedule-item.status-scheduled {
            border-left-color: #0d6efd;
            background-color: #e3f2fd;
        }
        .schedule-item.status-completed {
            border-left-color: #198754;
            background-color: #d1e7dd;
        }
        .schedule-item.status-cancelled {
            border-left-color: #dc3545;
            background-color: #f8d7da;
        }
        .date-number {
            font-size: 1.5rem;
            color: #0d6efd;
            margin-bottom: 5px;
        }
        .day-name {
            font-size: 0.875rem;
            color: #6c757d;
        }
        .today .date-number {
            color: #fff;
            background-color: #0d6efd;
            display: inline-block;
            width: 40px;
            height: 40px;
            line-height: 40px;
            border-radius: 50%;
        }
    </style>
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Lễ tân</div>
        <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
            <div>
                <h1 class="page-title">Lịch trực của tôi</h1>
                <p class="page-subtitle">Xem lịch làm việc theo tuần.</p>
            </div>
            <div class="d-flex align-items-center gap-3 flex-wrap">
                <div class="d-flex align-items-center gap-2 bg-light p-2 rounded border">
                    <div class="d-flex align-items-center gap-1">
                        <span class="fw-bold text-danger small" style="text-decoration: underline;">YEAR</span>
                        <select id="selectYear" class="form-select form-select-sm" style="width: 100px;">
                        </select>
                    </div>
                    <div class="d-flex align-items-center gap-1 ms-2">
                        <span class="fw-bold text-primary small">WEEK</span>
                        <select id="selectWeek" class="form-select form-select-sm" style="width: 220px;">
                        </select>
                    </div>
                </div>
            </div>
        </div>

        <div class="schedule-container bg-white p-4 rounded shadow-sm">
            <div class="schedule-grid" id="scheduleGrid">
                <!-- Data will be populated by JS -->
            </div>
        </div>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/schedule.js?v=1"></script>
</body>
</html>
