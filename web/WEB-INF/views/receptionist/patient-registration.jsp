<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="patient-register" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đăng ký bệnh nhân</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-balanced" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tạo hồ sơ</div>
        <h1 class="page-title">Đăng ký bệnh nhân</h1>
        <p class="page-subtitle">Tạo hồ sơ bệnh nhân mới, sau đó chuyển thẳng sang đăng ký khám.</p>

        <section class="panel-card mt-4">
            <form id="patientRegistrationForm" class="needs-validation" novalidate>
                <c:set var="isSelfRegistration" value="false" scope="request" />
                <%@ include file="/WEB-INF/views/components/shared/patient-registration-form.jspf" %>

                <div class="mt-4 d-flex gap-2">
                    <button class="btn btn-primary btn-lg px-4 fw-semibold" type="submit">
                        <i class="bi bi-person-plus me-1"></i>Tạo hồ sơ bệnh nhân
                    </button>
                    <button class="btn btn-outline-secondary btn-lg px-4" id="resetPatientRegistrationBtn" type="button">Làm mới</button>
                </div>
            </form>
        </section>

        <section id="patientRegistrationResult" class="result-card mt-4 d-none"></section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/patient-registration.js?v=20260710-encodingfix"></script>
</body>
</html>
