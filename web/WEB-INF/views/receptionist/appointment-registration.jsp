<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="appointment" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đăng ký khám tại quầy - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260801" rel="stylesheet">
</head>
<body class="receptionist-page master-ui-body master-ui-dark">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker fw-bold text-uppercase" style="color: #2AB5A3;">Tại quầy</div>
        <h1 class="page-title fw-bold text-white">Đăng ký khám</h1>
        <p class="page-subtitle text-white-50">Tìm kiếm bệnh nhân, chọn ca khám của bác sĩ để đăng ký khám trực tiếp.</p>

        <%-- Vùng thông báo hiển thị kết quả sau khi đăng ký hoặc tìm kiếm --%>
        <section id="registrationResult" class="result-card my-3 d-none"></section>

        <%-- Phần bảng điều khiển chính chứa tìm kiếm bệnh nhân và form đăng ký --%>
        <section class="panel-card mt-4 p-4" style="background: rgba(15, 23, 42, 0.75) !important; border: 1px solid rgba(255, 255, 255, 0.08) !important; border-radius: 20px !important;">
            <%-- Vùng tìm kiếm nhanh hồ sơ bệnh nhân qua Số điện thoại hoặc Họ tên --%>
            <div class="row g-2 align-items-end mb-4 pb-4 border-bottom border-secondary border-opacity-25">
                <div class="col-md-8">
                    <label class="form-label fw-semibold text-white" for="patientLookupKeyword">Tìm bệnh nhân có sẵn</label>
                    <input id="patientLookupKeyword" class="form-control" placeholder="Nhập số điện thoại hoặc họ tên chính xác" style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                </div>
                <div class="col-md-4">
                    <button id="patientLookupBtn" class="master-btn-primary w-100" type="button" style="height: 44px; display: inline-flex; align-items: center; justify-content: center;">
                        <i class="bi bi-search me-1"></i>Tìm và điền thông tin
                    </button>
                </div>
                <div class="col-12"><small class="text-white-50" style="color: #94A3B8 !important;">Nhập số điện thoại để tìm kiếm bệnh nhân đã đăng ký trên hệ thống.</small></div>
            </div>

            <%-- Form nhập thông tin bệnh nhân và chọn lịch khám --%>
            <form id="appointmentRegistrationForm" class="row g-3">
                <%-- Khung thông tin cá nhân của bệnh nhân (Họ tên, SĐT, Ngày sinh, Giới tính, Địa chỉ) --%>
                <div id="patientFieldsContainer" class="col-12 row g-3 d-none m-0 p-0 border-bottom border-secondary border-opacity-25 pb-4 mb-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold text-white">Họ tên bệnh nhân</label>
                        <input id="registerPatientName" name="patientName" class="form-control" required style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold text-white">Số điện thoại</label>
                        <input id="registerPatientPhone" name="patientPhone" class="form-control" required style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold text-white">Email</label>
                        <input id="registerPatientEmail" name="patientEmail" type="email" class="form-control" style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold text-white">Ngày sinh</label>
                        <input id="registerPatientDob" name="patientDob" type="date" class="form-control" required style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold text-white">Giới tính</label>
                        <select id="registerPatientGender" name="patientGender" class="form-select" style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                            <option value="Male" class="bg-dark text-white">Nam</option>
                            <option value="Female" class="bg-dark text-white">Nữ</option>
                            <option value="Other" class="bg-dark text-white">Khác</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold text-white">Địa chỉ</label>
                        <input id="registerPatientAddress" name="patientAddress" class="form-control" style="background: rgba(255, 255, 255, 0.04) !important; border: 1px solid rgba(255, 255, 255, 0.12) !important; color: #FFFFFF !important;">
                    </div>
                </div>

                <%-- Thanh bộ lọc nhanh danh sách Bác sĩ theo Khoa, Ngày và Ca trực --%>
                <div class="col-12">
                    <div class="p-3 mb-3 rounded-4" style="background: rgba(30, 41, 59, 0.6) !important; border: 1px solid rgba(255, 255, 255, 0.08) !important;">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label class="form-label text-white-50 fw-semibold small mb-1" for="filterDepartment" style="color: #94A3B8 !important;">Khoa khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text border-0" style="background: rgba(15, 23, 42, 0.8); color: #2AB5A3;"><i class="bi bi-hospital"></i></span>
                                    <select id="filterDepartment" class="form-select border-0 text-white" style="background: rgba(15, 23, 42, 0.8);">
                                        <option value="" class="bg-dark text-white">Tất cả khoa khám</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-white-50 fw-semibold small mb-1" for="filterDate" style="color: #94A3B8 !important;">Ngày khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text border-0" style="background: rgba(15, 23, 42, 0.8); color: #2AB5A3;"><i class="bi bi-calendar-event"></i></span>
                                    <input id="filterDate" type="date" class="form-control border-0 text-white" style="background: rgba(15, 23, 42, 0.8);">
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-white-50 fw-semibold small mb-1" for="filterSession" style="color: #94A3B8 !important;">Buổi khám</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text border-0" style="background: rgba(15, 23, 42, 0.8); color: #2AB5A3;"><i class="bi bi-clock"></i></span>
                                    <select id="filterSession" class="form-select border-0 text-white" style="background: rgba(15, 23, 42, 0.8);">
                                        <option value="all" class="bg-dark text-white">Tất cả các buổi</option>
                                        <option value="morning" class="bg-dark text-white">Buổi sáng</option>
                                        <option value="afternoon" class="bg-dark text-white">Buổi chiều</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label text-white-50 fw-semibold small mb-1" for="searchDoctorName" style="color: #94A3B8 !important;">Tìm theo tên bác sĩ</label>
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text border-0" style="background: rgba(15, 23, 42, 0.8); color: #2AB5A3;"><i class="bi bi-search"></i></span>
                                    <input id="searchDoctorName" type="search" class="form-control border-0 text-white" placeholder="Nhập tên bác sĩ..." autocomplete="off" style="background: rgba(15, 23, 42, 0.8);">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>

            <%-- Khung hiển thị danh sách các thẻ Bác sĩ có lịch khám tương ứng --%>
            <section class="doctor-results mt-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h3 class="h4 mb-1 fw-bold text-white">Bác sĩ có lịch phù hợp</h3>
                        <p id="bookingFilterDescription" class="text-white-50 mb-0" style="color: #94A3B8 !important;">Vui lòng chọn khoa khám và ngày khám để hệ thống tìm lịch phù hợp.</p>
                    </div>
                    <span id="bookingDoctorCount" class="badge px-3 py-2 fs-6 rounded-pill" style="background: rgba(42, 181, 163, 0.2) !important; color: #2AB5A3 !important; border: 1px solid rgba(42, 181, 163, 0.4) !important;">
                        <i class="bi bi-people me-1"></i>Chưa chọn khoa
                    </span>
                </div>

                <div id="doctorCardsList" class="doctor-booking-list">
                    <div class="text-center py-4 text-white-50" style="color: #94A3B8 !important;">
                        <div class="spinner-border text-teal mb-2" role="status" style="color: #2AB5A3;"></div>
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
