<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="dashboard" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tổng quan lễ tân</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-balanced" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="dashboard-header-banner">
            <div class="page-kicker">Lễ tân</div>
            <h1 class="page-title">Tổng quan tiếp nhận</h1>
            <p class="page-subtitle">Tra cứu bệnh nhân, đăng ký khám tại quầy, theo dõi hàng đợi và xác nhận thanh toán.</p>
        </div>

        <section class="stat-grid my-4">
            <div class="stat-card card-orange">
                <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                <div class="stat-value" id="pendingInvoiceCount">0</div>
                <div class="muted-text">Hóa đơn chờ thanh toán</div>
            </div>
            <div class="stat-card card-green">
                <div class="stat-icon"><i class="bi bi-check2-circle"></i></div>
                <div class="stat-value" id="paidInvoiceCount">0</div>
                <div class="muted-text">Hóa đơn đã thanh toán</div>
            </div>
            <div class="stat-card card-blue">
                <div class="stat-icon"><i class="bi bi-calendar2-plus"></i></div>
                <div class="stat-value">Tại quầy</div>
                <div class="muted-text">Nguồn đặt lịch</div>
            </div>
            <div class="stat-card card-purple">
                <div class="stat-icon"><i class="bi bi-activity"></i></div>
                <div class="stat-value">Live</div>
                <div class="muted-text">Dữ liệu vận hành</div>
            </div>
        </section>

        <section class="action-grid">
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/patients/search">
                <span class="action-icon"><i class="bi bi-search"></i></span>
                <h4>Tìm bệnh nhân</h4>
                <p class="muted-text mb-0">Tra cứu theo số điện thoại và xem lịch hẹn gần nhất.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/appointments/new">
                <span class="action-icon"><i class="bi bi-calendar2-plus"></i></span>
                <h4>Đăng ký khám</h4>
                <p class="muted-text mb-0">Tạo lịch khám tại quầy và cấp số thứ tự.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/queue">
                <span class="action-icon"><i class="bi bi-people"></i></span>
                <h4>Hàng đợi khám</h4>
                <p class="muted-text mb-0">Theo dõi bệnh nhân đang chờ khám trong ngày.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/billing">
                <span class="action-icon"><i class="bi bi-receipt-cutoff"></i></span>
                <h4>Hóa đơn</h4>
                <p class="muted-text mb-0">Xem hóa đơn pending/paid và xác nhận thanh toán.</p>
            </a>
        </section>

        <!-- Danh sách bệnh nhân tái khám -->
        <section class="panel-card my-4" style="background: #fff; padding: 1.5rem; border-radius: 12px; border: 1px solid #e2e8f0; box-shadow: 0 1px 3px 0 rgba(0,0,0,0.05);">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h3 class="fw-bold mb-0" style="font-size: 1.2rem; color: #1e293b;">
                    <i class="bi bi-calendar2-check text-primary me-2"></i>Danh sách bệnh nhân tái khám
                </h3>
                <div class="d-flex align-items-center gap-2">
                    <input type="date" id="revisitDatePicker" class="form-control" style="max-width: 180px; font-size: 0.95rem; font-weight: 500;">
                    <span class="badge bg-primary text-white" id="revisitCountBadge" style="font-size: 0.9rem; padding: 0.5em 0.75em;">0 bệnh nhân</span>
                </div>
            </div>
            <div class="table-responsive bg-white rounded border">
                <table class="table table-hover align-middle mb-0" style="font-size: 0.9rem;">
                    <thead class="table-light text-secondary fw-semibold">
                        <tr>
                            <th class="ps-3">Họ và tên</th>
                            <th>Số điện thoại</th>
                            <th>Email</th>
                            <th>Ngày tái khám</th>
                            <th>Bác sĩ khám trước đó</th>
                            <th class="text-end pe-3">Hành động</th>
                        </tr>
                    </thead>
                    <tbody id="revisitTableBody">
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4">Đang tải danh sách...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/dashboard.js?v=20260709-fontfix2"></script>
</body>
</html>
