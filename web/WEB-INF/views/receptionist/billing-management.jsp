<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="billing" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Quản lý hóa đơn - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260801" rel="stylesheet">
</head>
<body class="receptionist-page master-ui-body master-ui-dark">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker fw-bold text-uppercase" style="color: #2AB5A3;">Thanh toán</div>
        <h1 class="page-title fw-bold text-white">Quản lý hóa đơn</h1>
        <p class="page-subtitle text-white-50">Xem hóa đơn chờ thanh toán và xác nhận khi bệnh nhân đã thanh toán.</p>

        <section class="stat-grid my-4">
            <button class="stat-card text-start border-0" type="button" data-invoice-status="Pending">
                <div class="stat-icon"><i class="bi bi-hourglass-split"></i></div>
                <div class="stat-value text-white" id="pendingInvoiceCount">0</div>
                <div class="muted-text text-white-50">Chờ thanh toán</div>
            </button>
            <button class="stat-card text-start border-0" type="button" data-invoice-status="Paid">
                <div class="stat-icon"><i class="bi bi-check-circle"></i></div>
                <div class="stat-value text-white" id="paidInvoiceCount">0</div>
                <div class="muted-text text-white-50">Đã thanh toán</div>
            </button>
        </section>

        <section class="panel-card p-4" style="background: rgba(15, 23, 42, 0.75) !important; border: 1px solid rgba(255, 255, 255, 0.08) !important; border-radius: 20px !important;">
            <div class="row g-3 align-items-end">
                <div class="col-md-9">
                    <label class="form-label fw-semibold text-white">Tìm kiếm hóa đơn</label>
                    <input id="billingPatientKeyword" class="form-control" placeholder="Nhập số điện thoại hoặc tên bệnh nhân..." style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                </div>
                <div class="col-md-3 d-grid">
                    <button id="searchInvoiceBtn" class="master-btn-primary" type="button" style="height: 44px; display: inline-flex; align-items: center; justify-content: center;">
                        <i class="bi bi-search me-1"></i>Tìm kiếm
                    </button>
                </div>
            </div>
            <div id="billingMessage" class="mt-3"></div>
        </section>

        <section class="panel-card mt-4 p-4" style="background: rgba(15, 23, 42, 0.75) !important; border: 1px solid rgba(255, 255, 255, 0.08) !important; border-radius: 20px !important;">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div>
                    <h3 class="h5 mb-1 text-white fw-bold" id="invoiceListTitle">Hóa đơn chờ thanh toán</h3>
                    <p class="muted-text text-white-50 mb-0">Hiển thị 20 hóa đơn mới nhất theo trạng thái.</p>
                </div>
                <button id="reloadInvoicesBtn" class="btn btn-outline-secondary btn-sm" type="button" style="border-color: rgba(255,255,255,0.2) !important; color: #FFFFFF !important;">
                    <i class="bi bi-arrow-clockwise me-1"></i>Tải lại
                </button>
            </div>
            <div id="invoiceList"></div>
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
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/billing-management.js?v=20260723-v4"></script>
</body>
</html>
