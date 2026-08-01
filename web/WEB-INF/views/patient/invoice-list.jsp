<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>H&#243;a &#273;&#417;n - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="invoices" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header"><div><p class="page-eyebrow">Thanh to&#225;n</p><h1>H&#243;a &#273;&#417;n c&#7911;a t&#244;i</h1><p>Theo d&#245;i chi ph&#237; kh&#225;m, x&#233;t nghi&#7879;m v&#224; tr&#7841;ng th&#225;i x&#225;c nh&#7853;n thanh to&#225;n.</p></div></header>
        <section class="card-lab-style page-card p-0">
            <div class="card-lab-header px-4 py-3">
                <h2><i class="bi bi-receipt"></i> Danh s&#225;ch h&#243;a &#273;&#417;n</h2>
            </div>
            <div class="p-4">
                <div class="filter-row patient-search-bar mb-3">
                    <label>Tr&#7841;ng th&#225;i<select id="invoiceStatusFilter"><option value="">T&#7845;t c&#7843;</option><option value="Pending">Ch&#432;a thanh to&#225;n</option><option value="Paid">&#272;&#227; thanh to&#225;n</option></select></label>
                    <label>T&#236;m ki&#7871;m<input id="invoiceSearch" type="search" placeholder="M&#227; h&#243;a &#273;&#417;n"></label>
                    <label>Ng&#224;y t&#7841;o
                        <input id="invoiceDateFilter" type="date">
                    </label>
                </div>
                <div id="invoiceList" class="record-list loading-state">&#272;ang t&#7843;i h&#243;a &#273;&#417;n...</div>
            </div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/invoice-list.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>
