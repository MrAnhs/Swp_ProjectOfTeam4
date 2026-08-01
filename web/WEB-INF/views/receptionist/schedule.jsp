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
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-balanced" rel="stylesheet">
    <style>
        .receptionist-page {
            background-color: #f8fafc !important;
        }
        .page-kicker-green {
            color: #16a34a;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            font-size: 0.85rem;
            margin-bottom: 4px;
        }
        .page-title-dark {
            color: #0f172a;
            font-weight: 800;
            font-size: 2rem;
            margin-bottom: 4px;
        }
        .page-subtitle-muted {
            color: #64748b;
            font-size: 0.925rem;
        }

        /* Top Right Filters Box matching Image 2 */
        .filter-controls-box {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px 12px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.03);
            display: inline-flex;
            align-items: center;
            gap: 16px;
        }
        .filter-label-year {
            color: #dc2626;
            font-weight: 700;
            font-size: 0.8rem;
            letter-spacing: 0.05em;
        }
        .filter-label-week {
            color: #2563eb;
            font-weight: 700;
            font-size: 0.8rem;
            letter-spacing: 0.05em;
        }
        .filter-select {
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 4px 28px 4px 10px;
            font-size: 0.875rem;
            font-weight: 500;
            color: #334155;
            background-color: #ffffff;
            cursor: pointer;
        }

        /* Schedule Container & Grid Table matching Image 2 */
        .schedule-card-panel {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
            margin-top: 20px;
        }

        .schedule-table-grid {
            display: grid;
            grid-template-columns: 110px repeat(7, 1fr);
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            overflow: hidden;
            background-color: #e2e8f0;
            gap: 1px;
        }

        .sched-hdr-cell {
            background-color: #f8fafc;
            padding: 12px 8px;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .sched-hdr-title {
            font-weight: 700;
            color: #334155;
            font-size: 0.9rem;
        }

        .sched-day-name {
            font-size: 0.8rem;
            color: #64748b;
            font-weight: 500;
            margin-bottom: 2px;
        }
        .sched-date-num {
            font-size: 1.4rem;
            font-weight: 700;
            color: #2563eb;
            line-height: 1;
            margin-bottom: 3px;
        }
        .sched-month-name {
            font-size: 0.75rem;
            color: #64748b;
        }

        .sched-hdr-cell.is-today .sched-date-num {
            background-color: #2563eb;
            color: #ffffff;
            width: 34px;
            height: 34px;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-top: 1px;
            margin-bottom: 2px;
        }

        .sched-time-col {
            background-color: #ffffff;
            padding: 16px 8px;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .sched-shift-title {
            font-weight: 800;
            color: #0f172a;
            font-size: 0.95rem;
        }
        .sched-shift-time {
            font-size: 0.775rem;
            color: #64748b;
            margin-top: 2px;
        }

        .sched-grid-cell {
            background-color: #ffffff;
            padding: 8px;
            min-height: 130px;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        /* Shift Card Components (Exact Image 2 Match) */
        .shift-card {
            border-radius: 8px;
            padding: 10px;
            font-size: 0.8rem;
            line-height: 1.45;
        }

        /* Expired / Cancelled (Red theme in Image 2) */
        .shift-card.status-cancelled,
        .shift-card.status-expired {
            background-color: #fce8e6;
            color: #1f2937;
        }
        .shift-card.status-cancelled .shift-time-head,
        .shift-card.status-expired .shift-time-head {
            color: #991b1b;
            font-weight: 700;
        }

        /* Active / Scheduled (Blue theme in Image 2) */
        .shift-card.status-scheduled,
        .shift-card.status-active {
            background-color: #e0f2fe;
            color: #1f2937;
        }
        .shift-card.status-scheduled .shift-time-head,
        .shift-card.status-active .shift-time-head {
            color: #1e40af;
            font-weight: 700;
        }

        .shift-staff-name {
            color: #4b5563;
            margin-top: 3px;
            margin-bottom: 4px;
        }

        .shift-badge-expired {
            background-color: #dc2626;
            color: #ffffff;
            font-weight: 600;
            border-radius: 12px;
            padding: 3px 8px;
            font-size: 0.725rem;
        }
        .shift-badge-scheduled {
            background-color: #2563eb;
            color: #ffffff;
            font-weight: 600;
            border-radius: 12px;
            padding: 3px 8px;
            font-size: 0.725rem;
        }
    </style>
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <!-- Shared Master Duty Schedule Grid Component -->
        <%@ include file="/WEB-INF/views/components/shared/duty-schedule-grid.jspf" %>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/core/duty-schedule-shared.js"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/schedule.js?v=20260725-v5"></script>
</body>
</html>
