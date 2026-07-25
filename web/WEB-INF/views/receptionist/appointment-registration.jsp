<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
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
    <link href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-balanced" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tại quầy</div>
        <h1 class="page-title">Đăng ký khám</h1>
        <p class="page-subtitle">Tìm kiếm bệnh nhân, chọn ca khám của bác sĩ để đăng ký khám trực tiếp.</p>

        <!-- Notification Banner Container (Moved to Top for High Visibility) -->
        <section id="registrationResult" class="result-card my-3 d-none"></section>

        <section class="panel-card mt-4">
            <div class="row g-2 align-items-end mb-4 pb-4 border-bottom">
                <div class="col-md-8">
                    <label class="form-label fw-semibold" for="patientLookupKeyword">Tìm bệnh nhân có sẵn</label>
                    <input id="patientLookupKeyword" class="form-control" placeholder="Nhập số điện thoại hoặc họ tên chính xác">
                </div>
                <div class="col-md-4">
                    <button id="patientLookupBtn" class="btn btn-outline-primary w-100" type="button"><i class="bi bi-search me-1"></i>Tìm và điền thông tin</button>
                </div>
                <div class="col-12"><small class="text-muted">Nhập số điện thoại để tìm kiếm bệnh nhân đã đăng ký trên hệ thống.</small></div>
            </div>

            <form id="appointmentRegistrationForm" class="row g-3">
                <!-- Patient Info Section (Image 3) - Hidden by default until patient phone is found -->
                <div id="patientFieldsContainer" class="col-12 row g-3 d-none m-0 p-0 border-bottom pb-4 mb-3">
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
                </div>

                <!-- Doctor & Schedule Filter Bar (Clean Light Theme) -->
                <div class="col-12">
                    <div class="p-3 mb-3 rounded-3" style="background-color: #f8fafc; border: 1px solid #e2e8f0;">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label class="form-label text-dark fw-semibold small mb-1" for="filterDepartment">Khoa khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-white border-secondary border-opacity-50 text-success"><i class="bi bi-hospital"></i></span>
                                    <select id="filterDepartment" class="form-select bg-white text-dark border-secondary border-opacity-50">
                                        <option value="">Tất cả khoa khám</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-dark fw-semibold small mb-1" for="filterDate">Ngày khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-white border-secondary border-opacity-50 text-success"><i class="bi bi-calendar-event"></i></span>
                                    <input id="filterDate" type="date" class="form-control bg-white text-dark border-secondary border-opacity-50">
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-dark fw-semibold small mb-1" for="filterSession">Buổi khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-white border-secondary border-opacity-50 text-success"><i class="bi bi-clock"></i></span>
                                    <select id="filterSession" class="form-select bg-white text-dark border-secondary border-opacity-50">
                                        <option value="all">Tất cả các buổi</option>
                                        <option value="morning">Buổi sáng</option>
                                        <option value="afternoon">Buổi chiều</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-dark fw-semibold small mb-1" for="searchDoctorName">Tìm theo tên bác sĩ</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-white border-secondary border-opacity-50 text-success"><i class="bi bi-search"></i></span>
                                    <input id="searchDoctorName" type="search" class="form-control bg-white text-dark border-secondary border-opacity-50" placeholder="Nhập tên bác sĩ..." autocomplete="off">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>

            <!-- Doctor Results Section with Cards -->
            <section class="doctor-results mt-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h3 class="h4 mb-1 fw-bold text-dark">Bác sĩ có lịch phù hợp</h3>
                        <p id="bookingFilterDescription" class="text-muted mb-0">Vui lòng chọn khoa khám và ngày khám để hệ thống tìm lịch phù hợp.</p>
                    </div>
                    <span id="bookingDoctorCount" class="badge text-bg-success px-3 py-2 fs-6">
                        <i class="bi bi-people me-1"></i>Chưa chọn khoa
                    </span>
                </div>

                <div id="doctorCardsList" class="doctor-booking-list">
                    <div class="text-center py-4 text-muted">
                        <div class="spinner-border text-primary mb-2" role="status"></div>
                        <div>Đang tải danh sách bác sĩ...</div>
                    </div>
                </div>
            </section>
        </section>
    </main>
</div>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260709-fontfix2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/appointment-registration.js?v=20260723-v13"></script>
</body>
</html>
