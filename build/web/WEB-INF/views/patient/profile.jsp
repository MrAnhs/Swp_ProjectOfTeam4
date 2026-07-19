<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Th&#244;ng tin c&#225; nh&#226;n - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="profile" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>
    <main class="main-content-dash">
        <header class="page-header"><div><p class="page-eyebrow">T&#224;i kho&#7843;n</p><h1>Th&#244;ng tin c&#225; nh&#226;n</h1><p>C&#7853;p nh&#7853;t th&#244;ng tin li&#234;n h&#7879; v&#224; h&#7891; s&#417; b&#7879;nh nh&#226;n.</p></div></header>
        <section class="page-card">
            <form id="profileForm" class="stack-form">
                <div class="form-grid">
                    <label>H&#7885; t&#234;n<input id="profileName" name="fullName" required></label>
                    <label>Email<input id="profileEmail" type="email" name="email" required></label>
                    <label>S&#7889; &#273;i&#7879;n tho&#7841;i<input id="profilePhone" name="phone" pattern="^(0|\\+84)(3|5|7|8|9)[0-9]{8}$" required></label>
                    <label>Gi&#7899;i t&#237;nh
                        <select id="profileGender" name="gender">
                            <option value="">Ch&#7885;n gi&#7899;i t&#237;nh</option>
                            <option value="male">Nam</option>
                            <option value="female">N&#7919;</option>
                            <option value="other">Kh&#225;c</option>
                        </select>
                    </label>
                    <label>Ng&#224;y sinh<input id="profileDob" type="date" name="dob" min="1900-01-01" required></label>
                </div>
                <label class="form-field-full">&#272;&#7883;a ch&#7881;<textarea id="profileAddress" name="address" rows="3"></textarea></label>
                <p id="profileMessage" class="form-message"></p>
                <button class="btn-primary" type="submit"><i class="bi bi-save"></i> L&#432;u th&#244;ng tin</button>
            </form>
        </section>
    </main>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260710-patient-fontfix-all2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/profile.js?v=20260710-patient-fontfix-all2"></script>
</body>
</html>