<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>L&#7883;ch s&#7917; h&#7891; s&#417; - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="health-records" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header">
            <div><p class="page-eyebrow">H&#7891; s&#417; s&#7913;c kh&#7887;e</p><h1>L&#7883;ch s&#7917; h&#7891; s&#417;</h1><p>Theo d&#245;i c&#225;c h&#7891; s&#417; &#273;&#227; g&#7917;i v&#224; tr&#7841;ng th&#225;i x&#7917; l&#253;.</p></div>
        </header>
        <section class="page-card">
            <div class="filter-row">
                <label>Tr&#7841;ng th&#225;i
                    <select id="statusFilter"><option value="">T&#7845;t c&#7843;</option><option value="pending">Ch&#7901; x&#7917; l&#253;</option><option value="approved">&#272;&#227; duy&#7879;t</option></select>
                </label>
                <label>T&#236;m ki&#7871;m<input id="recordSearch" type="search" placeholder="M&#227; h&#7891; s&#417; ho&#7863;c tri&#7879;u ch&#7913;ng"></label>
            </div>
            <div id="recordList" class="record-list loading-state">&#272;ang t&#7843;i danh s&#225;ch h&#7891; s&#417;...</div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-status.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/health-record-list.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>