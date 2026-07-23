<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>L&#7883;ch s&#7917; kh&#225;m - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
</head>
<body>
    <c:set var="activePatientPage" value="history" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">B&#7879;nh &#225;n</p>
                <h1>L&#7883;ch s&#7917; kh&#225;m</h1>
                <p>M&#7895;i m&#7909;c t&#432;&#417;ng &#7913;ng m&#7897;t l&#7847;n kh&#225;m; k&#7871;t qu&#7843; ch&#7881; hi&#7875;n th&#7883; khi b&#225;c s&#297; cho ph&#233;p.</p>
            </div>
        </header>
        <section class="page-card">
            <div class="filter-row patient-search-bar">
                <label>Tr&#7841;ng th&#225;i
                    <select id="visitStatusFilter">
                        <option value="">T&#7845;t c&#7843;</option>
                        <option value="processing">&#272;ang x&#7917; l&#253;</option>
                        <option value="completed">&#272;&#227; ho&#224;n th&#224;nh</option>
                    </select>
                </label>
                <label>T&#236;m ki&#7871;m
                    <input id="visitSearch" type="search" placeholder="M&#227; l&#7847;n kh&#225;m, b&#225;c s&#297; ho&#7863;c chuy&#234;n khoa">
                </label>
                <label>Ng&#224;y kh&#225;m
                    <input id="visitDateFilter" type="date">
                </label>
            </div>
            <div id="visitList" class="record-list loading-state">&#272;ang t&#7843;i l&#7883;ch s&#7917; kh&#225;m...</div>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-status.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/visit-history.js?v=20260712-statusfix1"></script>
</body>
</html>
