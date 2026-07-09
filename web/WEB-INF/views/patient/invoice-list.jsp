<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Hóa đơn - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="invoices" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header"><div><p class="page-eyebrow">Thanh toán</p><h1>Hóa đơn của tôi</h1><p>Theo dõi chi phí khám, xét nghiệm và trạng thái xác nhận thanh toán.</p></div></header>
        <section class="page-card">
            <div class="filter-bar">
                <label>Trạng thái<select id="invoiceStatusFilter"><option value="">Tất cả</option><option value="Pending">Chưa thanh toán</option><option value="Paid">Đã thanh toán</option></select></label>
                <label>Tìm kiếm<input id="invoiceSearch" type="search" placeholder="Mã hóa đơn"></label>
            </div>
            <div id="invoiceList" class="record-list loading-state">Đang tải hóa đơn...</div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/invoice-list.js?v=20260709-fontfix2"></script>
</body>
</html>
