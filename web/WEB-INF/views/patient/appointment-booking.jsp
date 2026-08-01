<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta name="app-context-path" content="${pageContext.request.contextPath}">
    <title>Đặt lịch khám - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260801">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260801">
</head>
<body class="master-ui-body master-ui-dark">
    <c:set var="activePatientPage" value="book-appointment" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <header class="page-header">
            <div>
                <p class="page-eyebrow">L&#7883;ch kh&#225;m</p>
                <h1>&#272;&#7863;t l&#7883;ch kh&#225;m</h1>
                <p>Ch&#7885;n khoa, ng&#224;y kh&#225;m, bu&#7893;i kh&#225;m v&#224; b&#225;c s&#297; ph&#249; h&#7907;p v&#7899;i nhu c&#7847;u c&#7911;a b&#7841;n.</p>
            </div>
        </header>

        <section class="page-card booking-page-card">
            <div class="booking-workflow-header">
                <div>
                    <span class="booking-workflow-label">&#272;&#7862;T L&#7882;CH TR&#7920;C TUY&#7870;N</span>
                    <h2>Ch&#7885;n l&#7883;ch kh&#225;m c&#7911;a b&#7841;n</h2>
                    <p>H&#7879; th&#7889;ng ch&#7881; hi&#7875;n th&#7883; b&#225;c s&#297; c&#243; ca kh&#225;m c&#242;n ch&#7895; trong khoa &#273;&#227; ch&#7885;n.</p>
                </div>
                <ol class="booking-steps" aria-label="C&#225;c b&#432;&#7899;c &#273;&#7863;t l&#7883;ch">
                    <li id="bookingStepDate" class="active"><span>1</span> Ch&#7885;n khoa/ng&#224;y</li>
                    <li id="bookingStepTime"><span>2</span> Ch&#7885;n gi&#7901;</li>
                    <li id="bookingStepConfirm"><span>3</span> X&#225;c nh&#7853;n</li>
                </ol>
            </div>

            <div id="appointmentBookingForm" class="record-form booking-form">
                <div>
                    <section class="booking-filter-panel" aria-label="B&#7897; l&#7885;c l&#7883;ch kh&#225;m">
                        <label class="booking-filter-field">
                            <span>Khoa kh&#225;m</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-hospital"></i>
                                <select id="bookingDepartment" required>
                                    <option value="">&#272;ang t&#7843;i khoa kh&#225;m...</option>
                                </select>
                            </span>
                        </label>
                        <label class="booking-filter-field">
                            <span>Ng&#224;y kh&#225;m</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-calendar3"></i>
                                <input id="bookingDate" type="date" required>
                            </span>
                        </label>
                        <label class="booking-filter-field">
                            <span>Bu&#7893;i kh&#225;m</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-clock"></i>
                                <select id="bookingSession">
                                    <option value="all">T&#7845;t c&#7843; c&#225;c bu&#7893;i</option>
                                    <option value="morning">Bu&#7893;i s&#225;ng</option>
                                    <option value="afternoon">Bu&#7893;i chi&#7873;u</option>
                                </select>
                            </span>
                        </label>
                        <label class="booking-filter-field booking-filter-field--search">
                            <span>T&#236;m theo t&#234;n b&#225;c s&#297;</span>
                            <span class="booking-filter-control">
                                <i class="bi bi-search"></i>
                                <input id="bookingDoctorName" type="search" placeholder="Nh&#7853;p t&#234;n b&#225;c s&#297;..." autocomplete="off">
                            </span>
                        </label>
                    </section>

                    <section class="doctor-results">
                        <div class="doctor-results__summary">
                            <div>
                                <h2>B&#225;c s&#297; c&#243; l&#7883;ch ph&#249; h&#7907;p</h2>
                                <p id="bookingFilterDescription">Vui l&#242;ng ch&#7885;n khoa kh&#225;m &#273;&#7875; b&#7855;t &#273;&#7847;u l&#7885;c l&#7883;ch.</p>
                            </div>
                            <span id="bookingDoctorCount" class="doctor-count">
                                <i class="bi bi-hospital"></i>
                                Ch&#432;a ch&#7885;n khoa
                            </span>
                        </div>

                        <div id="bookingDoctorList" class="doctor-booking-list loading-state">
                            Vui l&#242;ng ch&#7885;n khoa kh&#225;m tr&#432;&#7899;c &#273;&#7875; h&#7879; th&#7889;ng t&#236;m l&#7883;ch ph&#249; h&#7907;p.
                        </div>
                    </section>
                </div>
            </div>
        </section>

        <section id="bookingResult" class="page-card booking-result" hidden></section>
    </main>

    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/app-config.js?v=20260721-ui2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/core/api-client.js?v=20260721-ui2"></script>
    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/patient/appointment-booking.js?v=20260721-ui2"></script>
</body>
</html>