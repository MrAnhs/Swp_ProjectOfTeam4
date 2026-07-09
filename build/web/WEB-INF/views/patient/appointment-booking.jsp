<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Đặt lịch khám - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css">
</head>
<body>
    <c:set var="activePatientPage" value="book-appointment" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">Lịch khám</p>
                <h1>Đặt lịch khám</h1>
                <p>Tìm bác sĩ có lịch trống và chọn giờ khám phù hợp với bạn.</p>
            </div>
        </header>

        <section class="page-card booking-page-card">
            <div class="booking-workflow-header">
                <div>
                    <span class="booking-workflow-label">ĐẶT LỊCH TRỰC TUYẾN</span>
                    <h2>Chọn lịch khám của bạn</h2>
                    <p>Chỉ những bác sĩ và giờ khám còn chỗ mới được hiển thị.</p>
                </div>
                <ol class="booking-steps" aria-label="Các bước đặt lịch">
                    <li id="bookingStepDate" class="active"><span>1</span> Chọn ngày</li>
                    <li id="bookingStepTime"><span>2</span> Chọn giờ</li>
                    <li id="bookingStepConfirm"><span>3</span> Xác nhận</li>
                </ol>
            </div>

            <div id="appointmentBookingForm" class="record-form booking-form">
                <div>
                    <section class="booking-filter-panel" aria-label="Bộ lọc lịch khám">
                        <label class="booking-filter-field">
                            <span>Ngày khám</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-calendar3"></i>
                                <input id="bookingDate" type="date" required>
                            </span>
                        </label>
                        <label class="booking-filter-field">
                            <span>Buổi khám</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-clock"></i>
                                <select id="bookingSession">
                                    <option value="all">Tất cả các buổi</option>
                                    <option value="morning">Buổi sáng</option>
                                    <option value="afternoon">Buổi chiều</option>
                                </select>
                            </span>
                        </label>
                        <label class="booking-filter-field booking-filter-field--search">
                            <span>Tìm theo tên bác sĩ</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-search"></i>
                                <input id="bookingDoctorName" type="search"
                                       placeholder="Nhập tên bác sĩ..." autocomplete="off">
                            </span>
                        </label>
                    </section>

                    <section class="doctor-results">
                        <div class="doctor-results__summary">
                            <div>
                                <h2>Bác sĩ có lịch phù hợp</h2>
                                <p id="bookingFilterDescription">Đang kiểm tra lịch khám...</p>
                            </div>
                            <span id="bookingDoctorCount" class="doctor-count">
                                <i class="bi bi-people"></i>
                                Đang tải
                            </span>
                        </div>

                        <div id="bookingDoctorList" class="doctor-booking-list loading-state">
                            Đang tải danh sách bác sĩ...
                        </div>
                    </section>
                </div>
            </div>
        </section>

        <section id="bookingResult" class="page-card booking-result" hidden></section>
    </main>

    <script src="${pageContext.request.contextPath}/assets/js/core/app-config.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/core/api-client.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-booking.js"></script>
</body>
</html>
