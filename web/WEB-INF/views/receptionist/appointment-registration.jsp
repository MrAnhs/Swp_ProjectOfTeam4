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

        <section id="registrationResult" class="result-card mt-4 d-none"></section>

        <section class="panel-card mt-4">
            <div class="row g-2 align-items-end mb-4 pb-4 border-bottom">
                <div class="col-md-8">
                    <label class="form-label fw-semibold" for="patientLookupKeyword">Tìm bệnh nhân có sẵn</label>
                    <input id="patientLookupKeyword" class="form-control" placeholder="Nhập số điện thoại hoặc họ tên chính xác">
                </div>
                <div class="col-md-4">
                    <button id="patientLookupBtn" class="btn btn-outline-primary w-100" type="button"><i class="bi bi-search me-1"></i>Tìm bệnh nhân</button>
                </div>
                <div class="col-12"><small class="text-muted">Bệnh nhân mới tạo từ màn hình Đăng ký bệnh nhân sẽ được điền tự động.</small></div>
            </div>
            <form id="appointmentRegistrationForm" class="row g-3">
                <!-- Hidden inputs for patient details -->
                <input type="hidden" id="registerPatientName" name="patientName">
                <input type="hidden" id="registerPatientPhone" name="patientPhone">
                <input type="hidden" id="registerPatientEmail" name="patientEmail">
                <input type="hidden" id="registerPatientDob" name="patientDob">
                <input type="hidden" id="registerPatientGender" name="patientGender">
                <input type="hidden" id="registerPatientAddress" name="patientAddress">
                <input type="hidden" id="registerVisitType" name="visitType" value="New">
                <input type="hidden" id="registerDoctor" name="doctorId" required>
                <input type="hidden" id="registerScheduleSlot" name="scheduleId" required>
                <input type="hidden" id="registerNote" name="note" value="">

                <!-- Selected Patient Card -->
                <div id="selectedPatientCard" class="col-12 d-none">
                    <div class="card bg-light border-light shadow-sm mb-3">
                        <div class="card-body p-3">
                            <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                                <h4 class="h6 mb-0 text-uppercase fw-bold text-secondary">
                                    <i class="bi bi-person-check-fill me-1"></i> Bệnh nhân đã chọn
                                </h4>
                            </div>
                            <div class="row text-dark" style="font-size: 14px;">
                                <div class="col-md-4 mb-1"><strong>Họ tên:</strong> <span id="previewName">-</span></div>
                                <div class="col-md-4 mb-1"><strong>Số điện thoại:</strong> <span id="previewPhone">-</span></div>
                                <div class="col-md-4 mb-1"><strong>Ngày sinh:</strong> <span id="previewDob">-</span></div>
                                <div class="col-md-4 mb-1"><strong>Giới tính:</strong> <span id="previewGender">-</span></div>
                                <div class="col-md-8 mb-1"><strong>Địa chỉ:</strong> <span id="previewAddress">-</span></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Doctor & Schedule Selection Area (Visual like Patient Booking) -->
                <div id="bookingSelectionArea" class="col-12">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h3 class="h5 mb-0 fw-bold text-dark">
                            <i class="bi bi-calendar2-week-fill me-1"></i> Chọn bác sĩ & ca khám
                        </h3>
                    </div>
                    <div class="row g-2 align-items-end mb-4 bg-light p-3 rounded-3 border m-0">
                        <div class="col-md-3">
                            <label class="form-label fw-semibold small text-secondary">Khoa khám</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text bg-white"><i class="bi bi-hospital text-primary"></i></span>
                                <select id="filterDepartment" class="form-select">
                                    <option value="">Tất cả các khoa</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold small text-secondary">Ngày khám</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text bg-white"><i class="bi bi-calendar3 text-primary"></i></span>
                                <input id="filterDate" type="date" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold small text-secondary">Buổi khám</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text bg-white"><i class="bi bi-clock text-primary"></i></span>
                                <select id="filterSession" class="form-select">
                                    <option value="all">Tất cả các buổi</option>
                                    <option value="morning">Buổi sáng</option>
                                    <option value="afternoon">Buổi chiều</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold small text-secondary">Tìm theo tên bác sĩ</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text bg-white"><i class="bi bi-search text-primary"></i></span>
                                <input id="searchDoctorName" class="form-control" placeholder="Nhập tên bác sĩ...">
                            </div>
                        </div>
                    </div>

                    <!-- Doctor search results summary -->
                    <div class="d-flex justify-content-between align-items-center mb-3 mt-4 px-2">
                        <div>
                            <h4 class="h6 mb-1 fw-bold text-dark" id="bookingFilterTitle">Bác sĩ có lịch phù hợp</h4>
                            <p class="text-muted mb-0 small" id="bookingFilterDescription">Vui lòng chọn bộ lọc lịch khám.</p>
                        </div>
                        <span id="bookingDoctorCount" class="badge bg-info text-dark p-2">
                            <i class="bi bi-people-fill me-1"></i> Chưa chọn khoa
                        </span>
                    </div>

                    <!-- Doctors and Slots List -->
                    <div id="doctorCardsList" class="row g-3 m-0">
                        <!-- Dynamically rendered doctor cards -->
                    </div>


                </div>
            </form>
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
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/appointment-registration.js?v=20260710-encodingfix"></script>
</body>
</html>
