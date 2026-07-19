<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tiếp nhận bệnh nhân</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css" rel="stylesheet">
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <nav class="doctor-nav">
        <a class="active" href="${pageContext.request.contextPath}/doctor/dashboard"><i class="bi bi-calendar2-check"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/doctor/general-examinations"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/doctor/laboratory-requests"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/doctor/examinations"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/doctor/completed-records"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/doctor/patients/search"><i class="bi bi-search"></i> Tra cứu</a>
        <a href="${pageContext.request.contextPath}/doctor/schedule"><i class="bi bi-calendar3"></i> Lịch trực</a>
        <a href="${pageContext.request.contextPath}/settings"><i class="bi bi-gear"></i> Cài đặt</a>
        <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small mb-1">BÁC SĨ #${doctorId}</div>
                <h1 class="doctor-title h3 mb-1">Tiếp nhận bệnh nhân</h1>
                <p class="doctor-muted mb-0">
                    Danh sách lấy trực tiếp từ lịch hẹn đã liên kết với bác sĩ hiện tại.
                </p>
            </div>
            <div class="input-group" style="max-width:340px">
                <span class="input-group-text bg-white border-end-0"><i class="bi bi-search"></i></span>
                <input id="queueSearch" class="form-control doctor-filter border-start-0"
                       placeholder="Tìm tên hoặc mã lịch hẹn">
            </div>
        </div>
    </section>

    <c:if test="${not empty sessionScope.doctorMessage}">
        <div class="alert alert-info alert-dismissible fade show">
            ${sessionScope.doctorMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorMessage" scope="session"/>
    </c:if>

    <div class="row g-3 mb-4">
        <div class="col-sm-6 col-xl-4">
            <div class="doctor-stat d-flex justify-content-between">
                <div>
                    <div class="doctor-muted small">Lịch hẹn chờ tiếp nhận</div>
                    <div class="h2 fw-bold mb-0">${appointmentQueue.size()}</div>
                </div>
                <div class="doctor-stat-icon bg-info-subtle text-info"><i class="bi bi-calendar2-check"></i></div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-4">
            <div class="doctor-stat d-flex justify-content-between">
                <div>
                    <div class="doctor-muted small">Hồ sơ đã hoàn thành</div>
                    <div class="h2 fw-bold mb-0">${completedRecords.size()}</div>
                </div>
                <div class="doctor-stat-icon bg-success-subtle text-success"><i class="bi bi-check2-circle"></i></div>
            </div>
        </div>
    </div>

    <section class="doctor-card">
        <div class="mb-4">
            <h2 class="doctor-section-title h5 mb-1">Lịch hẹn chờ khám</h2>
            <div class="doctor-muted">
                Nhấn tiếp nhận để tạo hoặc mở đúng hồ sơ sức khỏe của lịch hẹn.
            </div>
        </div>

        <c:choose>
            <c:when test="${empty appointmentQueue}">
                <div class="doctor-empty">
                    <i class="bi bi-calendar2-check fs-1 d-block mb-2"></i>
                    Không có lịch hẹn đang chờ tiếp nhận.
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Mã lịch hẹn</th>
                            <th>Bệnh nhân</th>
                            <th>Thời gian khám</th>
                            <th>Số thứ tự</th>
                            <th>Hình thức</th>
                            <th class="text-end">Thao tác</th>
                        </tr>
                        </thead>
                        <tbody id="queueBody">
                        <c:forEach var="appointment" items="${appointmentQueue}">
                            <tr data-search="${appointment.appointmentId} ${appointment.patientId} ${appointment.patientName}">
                                <td class="fw-bold">#${appointment.appointmentId}</td>
                                <td>
                                    <div class="fw-semibold">${appointment.patientName}</div>
                                    <small class="doctor-muted">Bệnh nhân #${appointment.patientId}</small>
                                </td>
                                <td><fmt:formatDate value="${appointment.appointmentTime}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td><span class="doctor-badge badge-assigned">${appointment.queueNumber}</span></td>
                                <td>${appointment.bookingType == 'Online' ? 'Trực tuyến' : 'Tại quầy'}</td>
                                <td class="text-end">
                                    <form action="${pageContext.request.contextPath}/doctor/appointments/accept"
                                          method="post" class="d-inline">
                                        <input type="hidden" name="appointment_id"
                                               value="${appointment.appointmentId}">
                                        <button class="btn btn-sm btn-success" type="submit">
                                            <i class="bi bi-check2-circle"></i> Tiếp nhận và mở khám
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div id="filterEmpty" class="doctor-empty mt-3 d-none">
                    Không tìm thấy lịch hẹn phù hợp.
                </div>
            </c:otherwise>
        </c:choose>
    </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const rows = Array.from(document.querySelectorAll("#queueBody tr"));
document.getElementById("queueSearch")?.addEventListener("input", event => {
    const keyword = event.target.value.trim().toLowerCase();
    let visible = 0;
    rows.forEach(row => {
        const matched = row.dataset.search.toLowerCase().includes(keyword);
        row.classList.toggle("d-none", !matched);
        if (matched) visible++;
    });
    document.getElementById("filterEmpty")?.classList.toggle("d-none", visible !== 0);
});
</script>
</body>
</html>
