<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<c:set var="currentAction" value="reports" />

<%--
    Trang Báo cáo Admin:
    - Tổng hợp doanh thu và lượt khám theo ngày/tháng/năm
    - Cho phép drill-down chi tiết hóa đơn và lịch hẹn theo kỳ
--%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Báo cáo Doanh thu và Lượt khám - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        .report-chart-panel {
            position: relative;
            height: 320px;
            min-height: 320px;
        }

        .report-table-scroll {
            max-height: 470px;
            overflow-y: auto;
            overflow-x: auto;
            border: 1px solid #e9ecef;
            border-radius: 12px;
        }

        .report-table-scroll table {
            margin-bottom: 0;
            table-layout: fixed;
            width: 100%;
        }

        .report-table-scroll thead th {
            position: sticky;
            top: 0;
            z-index: 2;
            background: #f8f9fa;
            word-wrap: break-word;
            white-space: normal;
        }

        .report-chart-panel canvas {
            width: 100% !important;
            height: 100% !important;
        }

        /* Table cell styling */
        .report-table-scroll table tbody td {
            vertical-align: middle;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }

        .report-table-scroll table tbody td button {
            white-space: nowrap;
        }

        /* Column sizing for invoice table */
        .report-table-scroll table thead th:nth-child(1),
        .report-table-scroll table tbody td:nth-child(1) {
            width: 10%;
        }

        .report-table-scroll table thead th:nth-child(2),
        .report-table-scroll table tbody td:nth-child(2) {
            width: 18%;
        }

        .report-table-scroll table thead th:nth-child(3),
        .report-table-scroll table tbody td:nth-child(3) {
            width: 15%;
        }

        .report-table-scroll table thead th:nth-child(4),
        .report-table-scroll table tbody td:nth-child(4) {
            width: 15%;
        }

        .report-table-scroll table thead th:nth-child(5),
        .report-table-scroll table tbody td:nth-child(5) {
            width: 15%;
        }

        .report-table-scroll table thead th:nth-child(6),
        .report-table-scroll table tbody td:nth-child(6) {
            width: 15%;
        }

        .report-table-scroll table thead th:nth-child(7),
        .report-table-scroll table tbody td:nth-child(7) {
            width: 12%;
        }

        @media (max-width: 992px) {
            .report-chart-panel {
                height: 280px;
                min-height: 280px;
            }
        }
    </style>
</head>
<body class="bg-light">
<div class="container py-4">
    <div class="admin-layout row g-3">
        <div class="col-lg-3 admin-sidebar-col">
            <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
        </div>
        <div class="col-lg-9 admin-content-col">
            <div class="admin-page-header mb-3">
                <h2 class="mb-1">Phân hệ Báo cáo Doanh thu &amp; Hiệu suất Phòng khám S-COMS</h2>
                <p class="text-secondary mb-0">FR-ADM-06 và FR-ADM-07</p>
            </div>

    <c:if test="${not empty errorMessage}">
        <div class="alert alert-danger" role="alert">${errorMessage}</div>
    </c:if>

    <div class="card mb-4">
        <div class="card-body">
            <form method="get" action="${pageContext.request.contextPath}/admin" class="row g-3 align-items-end">
                <input type="hidden" name="action" value="reports">
                <div class="col-md-4">
                    <label class="form-label">Chế độ xem</label>
                    <div class="d-flex gap-3">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="granularity" id="gDay" value="day" ${granularity == 'day' ? 'checked' : ''}>
                            <label class="form-check-label" for="gDay">Theo Ngày</label>
                        </div>
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="granularity" id="gMonth" value="month" ${granularity == 'month' ? 'checked' : ''}>
                            <label class="form-check-label" for="gMonth">Theo Tháng</label>
                        </div>
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="granularity" id="gYear" value="year" ${granularity == 'year' ? 'checked' : ''}>
                            <label class="form-check-label" for="gYear">Theo Năm</label>
                        </div>
                    </div>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Năm</label>
                    <input class="form-control" type="number" name="year" value="${year}" placeholder="2026">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Tháng</label>
                    <input class="form-control" type="number" min="1" max="12" name="month" value="${month}" placeholder="6">
                </div>
                <div class="col-md-3 d-none" id="reportRangeFilterWrap">
                    <label class="form-label">Từ ngày</label>
                    <input class="form-control" type="date" name="reportStartDate" id="reportStartDate" value="${reportStartDate}">
                    <label class="form-label mt-2">Đến ngày</label>
                    <input class="form-control" type="date" name="reportEndDate" id="reportEndDate" value="${reportEndDate}">
                    <div class="form-text">Dùng khi chọn chế độ xem theo ngày. Mặc định là cả tháng hiện tại.</div>
                </div>
                <div class="col-md-2" id="reportSubmitWrap">
                    <button type="submit" class="btn btn-primary w-100">Lọc dữ liệu</button>
                </div>
            </form>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header fw-semibold">Doanh thu đã thanh toán</div>
                <div class="card-body">
                    <div class="report-chart-panel">
                        <canvas id="revenueChart"></canvas>
                    </div>
                    <div class="table-responsive report-table-scroll mt-3">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>Kỳ</th><th>Doanh thu</th></tr></thead>
                            <tbody>
                            <c:forEach var="r" items="${revenueSeries}">
                                <tr>
                                    <td>${r.period}</td>
                                    <td>
                                        <fmt:formatNumber value="${r.value}" type="number" maxFractionDigits="0" groupingUsed="true" /> VNĐ
                                    </td>
                                </tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header fw-semibold">Lượt khám hoàn tất</div>
                <div class="card-body">
                    <div class="report-chart-panel">
                        <canvas id="visitChart"></canvas>
                    </div>
                    <div class="table-responsive report-table-scroll mt-3">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>Kỳ</th><th>Lượt khám</th></tr></thead>
                            <tbody>
                            <c:forEach var="v" items="${visitSeries}">
                                <tr><td>${v.period}</td><td>${v.value}</td></tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="card mt-4">
        <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
            <span>Danh sách chi tiết hóa đơn &amp; lượt khám trong kỳ</span>
            <span id="selectedPeriodBadge" class="badge bg-secondary">Chưa chọn kỳ</span>
        </div>
        <div class="card-body">
            <ul class="nav nav-tabs" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="invoiceTab" data-bs-toggle="tab" data-bs-target="#invoicePane" type="button" role="tab" aria-controls="invoicePane" aria-selected="true">Hóa đơn</button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="appointmentTab" data-bs-toggle="tab" data-bs-target="#appointmentPane" type="button" role="tab" aria-controls="appointmentPane" aria-selected="false">Lượt khám</button>
                </li>
            </ul>
            <div class="tab-content mt-3">
                <div class="tab-pane fade show active" id="invoicePane" role="tabpanel" aria-labelledby="invoiceTab">
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead class="table-light">
                            <tr>
                                <th>ID Hóa đơn</th>
                                <th>Bệnh nhân</th>
                                <th class="text-end">Tổng tiền</th>
                                <th class="text-end">Khấu trừ BHYT</th>
                                <th class="text-end">Tiền thanh toán</th>
                                <th>Ngày thanh toán</th>
                                <th>Hành động</th>
                            </tr>
                            </thead>
                            <tbody id="invoiceTableBody">
                            <tr><td colspan="7" class="text-center text-muted py-3">Đang tải dữ liệu kỳ gần nhất...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="tab-pane fade" id="appointmentPane" role="tabpanel" aria-labelledby="appointmentTab">
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead class="table-light">
                            <tr>
                                <th>Mã lượt khám</th>
                                <th>Tên bệnh nhân</th>
                                <th>Bác sĩ điều trị</th>
                                <th>Khung giờ</th>
                                <th>Trạng thái</th>
                                <th>Ngày khám</th>
                            </tr>
                            </thead>
                            <tbody id="appointmentTableBody">
                            <tr><td colspan="6" class="text-center text-muted py-3">Đang tải dữ liệu kỳ gần nhất...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
        </div>
    </div>
</div>

<div class="modal fade" id="invoiceDetailModal" tabindex="-1" aria-labelledby="invoiceDetailModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="invoiceDetailModalLabel">Chi tiết hóa đơn</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p class="mb-2 text-secondary">Mã hóa đơn: <span id="invoiceDetailModalInvoiceId" class="fw-semibold">-</span></p>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle">
                        <thead class="table-light">
                        <tr>
                            <th>Dịch vụ</th>
                            <th class="text-end">Số lượng</th>
                            <th class="text-end">Đơn giá</th>
                            <th class="text-end">Thành tiền</th>
                        </tr>
                        </thead>
                        <tbody id="invoiceItemTableBody">
                        <tr><td colspan="4" class="text-center text-muted py-3">Chưa có dữ liệu</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    window.AdminConfig = window.AdminConfig || {};
    window.AdminConfig.contextPath = '${pageContext.request.contextPath}';
    window.AdminConfig.csrfToken = '${sessionScope.csrfToken}';
    window.AdminConfig.adminEndpoint = '${pageContext.request.contextPath}/admin';
    window.AdminConfig.loginUrl = '${pageContext.request.contextPath}/login.jsp';
    window.AdminConfig.revenueSeries = ${empty revenueJson ? '[]' : revenueJson};
    window.AdminConfig.visitSeries = ${empty visitJson ? '[]' : visitJson};
    window.AdminConfig.initialPeriod = '${initialPeriod}';
    window.AdminConfig.initialInvoices = ${empty initialInvoicesJson ? '[]' : initialInvoicesJson};
    window.AdminConfig.initialAppointments = ${empty initialAppointmentsJson ? '[]' : initialAppointmentsJson};
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/reports.js?v=20260723-v3"></script>
</body>
</html>


