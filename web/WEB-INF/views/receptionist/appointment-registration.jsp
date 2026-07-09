<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="appointment" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng ký khám tại quầy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tại quầy</div>
        <h1 class="page-title">Đăng ký khám</h1>
        <p class="page-subtitle">Tạo bệnh nhân nếu chưa có, chọn bác sĩ và ca khám còn chỗ.</p>

        <section class="panel-card mt-4">
            <form id="appointmentRegistrationForm" class="row g-3">
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Họ tên bệnh nhân</label>
                    <input id="registerPatientName" name="patientName" class="form-control" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Số điện thoại</label>
                    <input id="registerPatientPhone" name="patientPhone" class="form-control" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Email</label>
                    <input id="registerPatientEmail" name="patientEmail" type="email" class="form-control">
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Ngày sinh</label>
                    <input id="registerPatientDob" name="patientDob" type="date" class="form-control" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Giới tính</label>
                    <select id="registerPatientGender" name="patientGender" class="form-select">
                        <option value="Male">Nam</option>
                        <option value="Female">Nữ</option>
                        <option value="Other">Khác</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-semibold">Địa chỉ</label>
                    <input id="registerPatientAddress" name="patientAddress" class="form-control">
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Bác sĩ</label>
                    <select id="registerDoctor" name="doctorId" class="form-select" required>
                        <option value="">Đang tải danh sách bác sĩ...</option>
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Ca khám</label>
                    <select id="registerScheduleSlot" name="scheduleId" class="form-select" required>
                        <option value="">Chọn bác sĩ trước</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-semibold">Ghi chú</label>
                    <textarea id="registerNote" name="note" class="form-control" rows="3"></textarea>
                </div>
                <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary btn-lg" type="submit">
                        <i class="bi bi-calendar-check me-1"></i>Đăng ký khám
                    </button>
                    <button class="btn btn-outline-secondary btn-lg" id="resetRegistrationBtn" type="button">Làm mới</button>
                </div>
            </form>
        </section>

        <section id="registrationResult" class="result-card mt-4 d-none"></section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/pages/receptionist/appointment-registration.js"></script>
</body>
</html>
