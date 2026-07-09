<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tiếp nhận hồ sơ</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/doctor-module.css" rel="stylesheet">
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand">
        <span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span>
        <span>Cổng bác sĩ</span>
    </div>
    <nav class="doctor-nav">
        <a class="active" href="${pageContext.request.contextPath}/DashboardServlet"><i class="bi bi-calendar2-check"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/GeneralExaminationListServlet"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/LaboratoryListServlet"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/ExaminationListServlet"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/CompletedRecordsServlet"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/PatientSearchServlet"><i class="bi bi-search"></i> Tra cứu</a>
        <a class="doctor-nav-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <section class="doctor-hero mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between gap-4 align-items-xl-center">
            <div>
                <div class="doctor-eyebrow">Bác sĩ #${doctorId}</div>
                <h1 class="doctor-title mb-2">Tiếp nhận hồ sơ bệnh nhân</h1>
                <p class="doctor-muted mb-0">
                    Tiếp nhận lịch khám, tạo hồ sơ và chuyển sang bước chỉ định xét nghiệm cho bệnh nhân.
                </p>
            </div>
            <div class="doctor-search input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input id="queueSearch" class="form-control"
                       placeholder="Tìm tên bệnh nhân, mã lịch hoặc số thứ tự">
            </div>
        </div>
    </section>

    <c:if test="${not empty sessionScope.doctorMessage}">
        <div class="alert alert-info alert-dismissible fade show doctor-alert">
            ${sessionScope.doctorMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorMessage" scope="session"/>
    </c:if>

    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="doctor-stat">
                <div>
                    <div class="doctor-muted small">Lịch đang mở</div>
                    <div class="h2 fw-bold mb-0">${appointmentQueue.size()}</div>
                </div>
                <div class="doctor-stat-icon bg-info-subtle text-info"><i class="bi bi-calendar2-week"></i></div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="doctor-stat">
                <div>
                    <div class="doctor-muted small">Hồ sơ đã hoàn thành</div>
                    <div class="h2 fw-bold mb-0">${completedRecords.size()}</div>
                </div>
                <div class="doctor-stat-icon bg-success-subtle text-success"><i class="bi bi-check2-circle"></i></div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="doctor-stat">
                <div>
                    <div class="doctor-muted small">Bác sĩ có thể chuyển hồ sơ</div>
                    <div class="h2 fw-bold mb-0">${doctorList.size()}</div>
                </div>
                <div class="doctor-stat-icon bg-warning-subtle text-warning"><i class="bi bi-arrow-left-right"></i></div>
            </div>
        </div>
    </div>

    <section class="doctor-card">
        <div class="doctor-card-header">
            <div>
                <h2 class="doctor-section-title h5 mb-1">Danh sách lịch khám</h2>
                <div class="doctor-muted">Bấm tiếp nhận để tạo hồ sơ và mở màn chỉ định xét nghiệm.</div>
            </div>
            <span class="doctor-soft-badge"><i class="bi bi-shield-check"></i> Chỉ hiển thị lịch của bạn</span>
        </div>

        <c:choose>
            <c:when test="${empty appointmentQueue}">
                <div class="doctor-empty">
                    <i class="bi bi-calendar2-x fs-1 d-block mb-3"></i>
                    <div class="fw-semibold text-dark mb-1">Chưa có lịch khám đang mở</div>
                    <div>Lịch sẽ xuất hiện khi bệnh nhân đặt lịch hoặc lễ tân đăng ký lịch cho bác sĩ này.</div>
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Mã lịch</th>
                            <th>Bệnh nhân</th>
                            <th>Thời gian</th>
                            <th>Số thứ tự</th>
                            <th>Hình thức</th>
                            <th>Trạng thái</th>
                            <th class="text-end">Thao tác</th>
                        </tr>
                        </thead>
                        <tbody id="queueBody">
                        <c:forEach var="appointment" items="${appointmentQueue}">
                            <tr data-search="${appointment.appointmentId} ${appointment.patientId} ${appointment.patientName} ${appointment.queueNumber}">
                                <td class="fw-bold">#${appointment.appointmentId}</td>
                                <td>
                                    <div class="fw-semibold">${appointment.patientName}</div>
                                    <small class="doctor-muted">Bệnh nhân #${appointment.patientId}</small>
                                </td>
                                <td>
                                    <div class="fw-semibold"><fmt:formatDate value="${appointment.appointmentTime}" pattern="dd/MM/yyyy"/></div>
                                    <small class="doctor-muted"><fmt:formatDate value="${appointment.appointmentTime}" pattern="HH:mm"/></small>
                                </td>
                                <td><span class="doctor-badge badge-assigned">STT ${appointment.queueNumber}</span></td>
                                <td>${appointment.bookingType == 'Online' ? 'Trực tuyến' : 'Tại quầy'}</td>
                                <td>
                                    <c:choose>
                                        <c:when test="${appointment.status == 'In_Progress'}">
                                            <span class="doctor-badge badge-processing">Đang khám</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="doctor-badge badge-requested">Chờ tiếp nhận</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end">
                                    <form action="${pageContext.request.contextPath}/AcceptRecordServlet" method="post" class="d-inline">
                                        <input type="hidden" name="appointment_id" value="${appointment.appointmentId}">
                                        <button class="btn btn-sm btn-doctor" type="submit">
                                            <i class="bi bi-folder2-open"></i>
                                            ${appointment.status == 'In_Progress' ? 'Mở hồ sơ xét nghiệm' : 'Tiếp nhận và chỉ định'}
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div id="filterEmpty" class="doctor-empty mt-3 d-none">
                    Không tìm thấy lịch khám phù hợp.
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
