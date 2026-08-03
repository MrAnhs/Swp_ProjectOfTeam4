<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="dashboard" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Tổng quan Lễ tân - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260801" rel="stylesheet">
</head>
<body class="receptionist-page master-ui-body master-ui-dark">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="dashboard-header-banner p-4 rounded-4 mb-4" style="background: linear-gradient(135deg, rgba(42, 181, 163, 0.25) 0%, rgba(15, 23, 42, 0.9) 100%); border: 1px solid rgba(42, 181, 163, 0.3); color: #FFFFFF;">
            <div class="page-kicker fw-bold text-uppercase tracking-wider" style="color: #2AB5A3; font-size: 0.8rem;">Lễ tân</div>
            <h1 class="page-title fw-bold my-1 text-white" style="font-size: 2rem;">Tổng quan tiếp nhận</h1>
            <p class="page-subtitle mb-0 text-white-50" style="font-size: 0.95rem;">Tra cứu bệnh nhân, đăng ký khám tại quầy, theo dõi hàng đợi và xác nhận thanh toán.</p>
        </div>

        <section class="stat-grid my-4">
            <div class="stat-card card-orange">
                <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                <div class="stat-value text-white" id="pendingInvoiceCount">0</div>
                <div class="muted-text text-white-50">Hóa đơn chờ thanh toán</div>
            </div>
            <div class="stat-card card-green">
                <div class="stat-icon"><i class="bi bi-check2-circle"></i></div>
                <div class="stat-value text-white" id="paidInvoiceCount">0</div>
                <div class="muted-text text-white-50">Hóa đơn đã thanh toán</div>
            </div>
            <div class="stat-card card-blue">
                <div class="stat-icon"><i class="bi bi-calendar2-plus"></i></div>
                <div class="stat-value text-white">Tại quầy</div>
                <div class="muted-text text-white-50">Nguồn đặt lịch</div>
            </div>
            <div class="stat-card card-purple">
                <div class="stat-icon"><i class="bi bi-activity"></i></div>
                <div class="stat-value text-white">Live</div>
                <div class="muted-text text-white-50">Dữ liệu vận hành</div>
            </div>
        </section>

        <section class="action-grid">
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/patients/search">
                <span class="action-icon"><i class="bi bi-search"></i></span>
                <h4 class="text-white fw-bold">Tìm bệnh nhân</h4>
                <p class="muted-text text-white-50 mb-0">Tra cứu theo số điện thoại và xem lịch hẹn gần nhất.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/appointments/new">
                <span class="action-icon"><i class="bi bi-calendar2-plus"></i></span>
                <h4 class="text-white fw-bold">Đăng ký khám</h4>
                <p class="muted-text text-white-50 mb-0">Tạo lịch khám tại quầy và cấp số thứ tự.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/queue">
                <span class="action-icon"><i class="bi bi-people"></i></span>
                <h4 class="text-white fw-bold">Hàng đợi khám</h4>
                <p class="muted-text text-white-50 mb-0">Theo dõi bệnh nhân đang chờ khám trong ngày.</p>
            </a>
            <a class="action-card" href="${pageContext.request.contextPath}/receptionist/billing">
                <span class="action-icon"><i class="bi bi-receipt-cutoff"></i></span>
                <h4 class="text-white fw-bold">Hóa đơn</h4>
                <p class="muted-text text-white-50 mb-0">Xem hóa đơn pending/paid và xác nhận thanh toán.</p>
            </a>
        </section>

        <!-- Danh sách bệnh nhân tái khám -->
        <section class="panel-card my-4 p-4" style="background: rgba(15, 23, 42, 0.75) !important; border: 1px solid rgba(255, 255, 255, 0.08) !important; border-radius: 20px !important; backdrop-filter: blur(20px) !important; color: #FFFFFF !important;">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h3 class="fw-bold mb-0" style="font-size: 1.2rem; color: #2AB5A3 !important;">
                    <i class="bi bi-calendar2-check me-2" style="color: #2AB5A3;"></i>Danh sách bệnh nhân tái khám
                </h3>
                <div class="d-flex align-items-center gap-2">
                    <input type="date" id="revisitDatePicker" class="form-control" style="max-width: 180px; font-size: 0.95rem; font-weight: 500; background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    <span class="badge bg-primary text-white" id="revisitCountBadge" style="font-size: 0.9rem; padding: 0.5em 0.75em;">0 bệnh nhân</span>
                </div>
            </div>
            <div class="table-responsive rounded border border-secondary border-opacity-10">
                <table class="table table-hover align-middle mb-0" style="font-size: 0.9rem; color: #FFFFFF !important;">
                    <thead style="background: rgba(30, 41, 59, 0.8) !important; color: #94A3B8 !important;" class="fw-semibold">
                        <tr>
                            <th class="ps-3">Họ và tên</th>
                            <th>Số điện thoại</th>
                            <th>Email</th>
                            <th>Ngày tái khám</th>
                            <th>Bác sĩ khám trước đó</th>
                            <th class="text-end pe-3">Hành động</th>
                        </tr>
                    </thead>
                    <%-- Thân bảng hiển thị danh sách bệnh nhân tái khám - Dữ liệu và nút "Đăng ký khám" được JavaScript (dashboard.js) đổ vào đây --%>
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
