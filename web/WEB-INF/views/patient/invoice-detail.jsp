<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Chi tiết hóa đơn - DiabetesCare</title>
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
        <header class="page-header"><div><p class="page-eyebrow">Thanh toán</p><h1 id="invoiceTitle">Chi tiết hóa đơn</h1><p id="invoiceMeta">Đang tải...</p></div><a class="btn-page-secondary" href="${pageContext.request.contextPath}/patient/invoices"><i class="bi bi-arrow-left"></i> Quay lại</a></header>
        <section class="page-card invoice-document-card"><div id="invoiceDetail" class="loading-state">Đang tải hóa đơn...</div></section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260709-fontfix2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/invoice-detail.js?v=20260709-fontfix2"></script>
</body>
</html>
