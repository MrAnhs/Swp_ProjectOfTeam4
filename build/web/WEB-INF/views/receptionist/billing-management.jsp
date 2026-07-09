<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="billing" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý hóa đơn</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Thanh toán</div>
        <h1 class="page-title">Quản lý hóa đơn</h1>
        <p class="page-subtitle">Xem hóa đơn chờ thanh toán và xác nhận khi bệnh nhân đã thanh toán.</p>

        <section class="stat-grid my-4">
            <button class="stat-card text-start border-0" type="button" data-invoice-status="Pending">
                <div class="stat-icon"><i class="bi bi-hourglass-split"></i></div>
                <div class="stat-value" id="pendingInvoiceCount">0</div>
                <div class="muted-text">Chờ thanh toán</div>
            </button>
            <button class="stat-card text-start border-0" type="button" data-invoice-status="Paid">
                <div class="stat-icon"><i class="bi bi-check-circle"></i></div>
                <div class="stat-value" id="paidInvoiceCount">0</div>
                <div class="muted-text">Đã thanh toán</div>
            </button>
        </section>

        <section class="panel-card">
            <div class="row g-3 align-items-end">
                <div class="col-md-5">
                    <label class="form-label fw-semibold">Tìm bệnh nhân</label>
                    <input id="billingPatientKeyword" class="form-control" placeholder="Tên hoặc số điện thoại">
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Phương thức thanh toán</label>
                    <select id="paymentMethod" class="form-select">
                        <option value="Cash">Tiền mặt</option>
                        <option value="Momo">Momo</option>
                        <option value="VNPay">VNPay</option>
                        <option value="Bank_Transfer">Chuyển khoản</option>
                    </select>
                </div>
                <div class="col-md-3 d-grid">
                    <button id="payInvoiceBtn" class="btn btn-primary" type="button">Xác nhận thanh toán</button>
                </div>
            </div>
            <div id="billingMessage" class="mt-3"></div>
        </section>

        <section class="panel-card mt-4">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div>
                    <h3 class="h5 mb-1" id="invoiceListTitle">Hóa đơn chờ thanh toán</h3>
                    <p class="muted-text mb-0">Hiển thị 20 hóa đơn mới nhất theo trạng thái.</p>
                </div>
                <button id="reloadInvoicesBtn" class="btn btn-outline-primary" type="button">
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
<script src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/pages/receptionist/billing-management.js"></script>
</body>
</html>
