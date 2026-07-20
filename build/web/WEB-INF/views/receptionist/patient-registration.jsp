<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="patient-register" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng ký bệnh nhân</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tạo hồ sơ</div>
        <h1 class="page-title">Đăng ký bệnh nhân</h1>
        <p class="page-subtitle">Tạo hồ sơ bệnh nhân mới, sau đó chuyển thẳng sang đăng ký khám.</p>

        <section class="panel-card mt-4">
            <form id="patientRegistrationForm" class="row g-3">
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Họ tên</label>
                    <input id="patientRegisterName" name="patientName" class="form-control" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Số điện thoại</label>
                    <input id="patientRegisterPhone" name="patientPhone" class="form-control" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Email</label>
                    <input id="patientRegisterEmail" name="patientEmail" type="email" class="form-control" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Ngày sinh</label>
                    <input id="patientRegisterDob" name="patientDob" type="date" class="form-control" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Giới tính</label>
                    <select id="patientRegisterGender" name="patientGender" class="form-select">
                        <option value="Male">Nam</option>
                        <option value="Female">Nữ</option>
                        <option value="Other">Khác</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-semibold">Địa chỉ</label>
                    <input id="patientRegisterAddress" name="patientAddress" class="form-control">
                </div>
                <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary btn-lg" type="submit">
                        <i class="bi bi-person-plus me-1"></i>Tạo tài khoản và gửi email
                    </button>
                    <button class="btn btn-outline-secondary btn-lg" id="resetPatientRegistrationBtn" type="button">Làm mới</button>
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
