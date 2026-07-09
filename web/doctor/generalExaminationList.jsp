<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Khám tổng quát</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/doctor-module.css" rel="stylesheet">
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/DashboardServlet"><i class="bi bi-calendar2-check"></i> Tiếp nhận hồ sơ</a>
        <a class="active" href="${pageContext.request.contextPath}/GeneralExaminationListServlet"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/LaboratoryListServlet"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/ExaminationListServlet"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/CompletedRecordsServlet"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/PatientSearchServlet"><i class="bi bi-search"></i> Tra cứu</a>
        <a class="doctor-nav-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <section class="doctor-hero mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-eyebrow">Bước sau chỉ định xét nghiệm</div>
                <h1 class="doctor-title mb-1">Khám tổng quát</h1>
                <p class="doctor-muted mb-0">Chỉ hiển thị hồ sơ đã có chỉ định xét nghiệm. Hồ sơ mới tiếp nhận cần chọn xét nghiệm trước.</p>
            </div>
            <div class="doctor-search input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input id="generalSearch" class="form-control" placeholder="Tìm bệnh nhân hoặc mã hồ sơ">
            </div>
        </div>
    </section>

    <section class="doctor-card">
        <c:choose>
            <c:when test="${empty generalExaminationRecords}">
                <div class="doctor-empty">
                    <i class="bi bi-person-check fs-1 d-block mb-3"></i>
                    <div class="fw-semibold text-dark mb-1">Chưa có hồ sơ sẵn sàng khám tổng quát</div>
                    <div>Hãy tiếp nhận bệnh nhân và tạo chỉ định xét nghiệm trước.</div>
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Hồ sơ</th>
                            <th>Bệnh nhân</th>
                            <th>Ngày tiếp nhận</th>
                            <th>Trạng thái</th>
                            <th class="text-end">Thao tác</th>
                        </tr>
                        </thead>
                        <tbody id="generalBody">
                        <c:forEach var="r" items="${generalExaminationRecords}">
                            <tr data-search="${r.healthRecordId} ${r.patientName}">
                                <td class="fw-bold">#${r.healthRecordId}</td>
                                <td>
                                    <div class="fw-semibold">${r.patientName}</div>
                                    <small class="doctor-muted">Bệnh nhân #${r.patientId}</small>
                                </td>
                                <td><fmt:formatDate value="${r.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td><span class="doctor-badge badge-accepted">${r.statusDisplayText}</span></td>
                                <td class="text-end">
                                    <a class="btn btn-sm btn-doctor" href="${pageContext.request.contextPath}/DetailServlet?record_id=${r.healthRecordId}">
                                        <i class="bi bi-person-vcard"></i> Mở khám tổng quát
                                    </a>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
                <div id="generalEmpty" class="doctor-empty mt-3 d-none">Không tìm thấy hồ sơ phù hợp.</div>
            </c:otherwise>
        </c:choose>
    </section>
</main>

<script>
const rows = Array.from(document.querySelectorAll("#generalBody tr"));
document.getElementById("generalSearch")?.addEventListener("input", event => {
    const keyword = event.target.value.trim().toLowerCase();
    let visible = 0;
    rows.forEach(row => {
        const match = row.dataset.search.toLowerCase().includes(keyword);
        row.classList.toggle("d-none", !match);
        if (match) visible++;
    });
    document.getElementById("generalEmpty")?.classList.toggle("d-none", visible !== 0);
});
</script>
</body>
</html>
