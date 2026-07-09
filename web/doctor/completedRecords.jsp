<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Hồ sơ đã hoàn thành</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
        <link href="${pageContext.request.contextPath}/css/doctor-module.css" rel="stylesheet">
    </head>
    <body class="doctor-app">
        <aside class="doctor-sidebar">
            <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
            <nav class="doctor-nav">
                <a href="${pageContext.request.contextPath}/DashboardServlet"><i class="bi bi-grid"></i> Tiếp nhận hồ sơ</a>
                <a href="${pageContext.request.contextPath}/GeneralExaminationListServlet"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
                <a href="${pageContext.request.contextPath}/LaboratoryListServlet"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
                <a href="${pageContext.request.contextPath}/ExaminationListServlet"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
                <a class="active" href="${pageContext.request.contextPath}/CompletedRecordsServlet"><i class="bi bi-archive"></i> Đã hoàn thành</a>
                
                <a href="${pageContext.request.contextPath}/PatientSearchServlet"><i class="bi bi-search"></i> Tra cứu</a>
                <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
            </nav>
        </aside>
        <main class="doctor-main">
            <section class="doctor-topbar mb-4">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
                    <div>
                        <div class="doctor-muted small mb-1">HỒ SƠ ĐÃ HOÀN THÀNH</div>
                        <h1 class="doctor-title h3 mb-1">Hồ sơ đã hoàn thành</h1>
                        <p class="doctor-muted mb-0">Bác sĩ phụ trách có thể mở hồ sơ để chỉnh sửa lại kết luận và chỉ số khi cần.</p>
                    </div>
                    <div class="input-group" style="max-width:320px">
                        <span class="input-group-text bg-white border-end-0"><i class="bi bi-search"></i></span>
                        <input id="completedSearch" class="form-control doctor-filter border-start-0" placeholder="Tìm bệnh nhân, chẩn đoán...">
                    </div>
                </div>
            </section>

            <c:if test="${not empty sessionScope.doctorMessage}">
                <div class="alert alert-info alert-dismissible fade show">
                    ${sessionScope.doctorMessage}<button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <c:remove var="doctorMessage" scope="session"/>
            </c:if>

            <section class="doctor-card">
                <c:choose>
                    <c:when test="${empty completedRecords}">
                        <div class="doctor-empty"><i class="bi bi-archive fs-1 d-block mb-2"></i>Chưa có hồ sơ hoàn thành.</div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-responsive">
                            <table class="table doctor-table align-middle mb-0">
                                <thead><tr><th>Hồ sơ</th><th>Bệnh nhân</th><th>Ngày hoàn thành</th><th>Phân tích AI</th><th>Chẩn đoán</th><th class="text-end">Thao tác</th></tr></thead>
                                <tbody id="completedBody">
                                    <c:forEach var="r" items="${completedRecords}">
                                        <tr data-search="${r.healthRecordId} ${r.patientName} ${r.finalDiagnosis}">
                                            <td class="fw-bold">#${r.healthRecordId}</td>
                                            <td>${r.patientName}</td>
                                            <td><fmt:formatDate value="${r.processedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                            <td>
                                                <div class="small">Tiểu đường: <strong><fmt:formatNumber value="${r.diabetes_probability}" type="percent"/></strong></div>
                                                <div class="small doctor-muted">Tiền ĐTĐ: <fmt:formatNumber value="${r.pre_diabetes_probability}" type="percent"/> · Bình thường: <fmt:formatNumber value="${r.normal_probability}" type="percent"/></div>
                                            </td>
                                            <td><span class="doctor-badge badge-completed">${empty r.finalDiagnosis ? 'Chưa kết luận' : r.finalDiagnosis}</span></td>
                                            <td class="text-end text-nowrap">
                                                <a class="btn btn-sm btn-doctor" href="${pageContext.request.contextPath}/DetailServlet?record_id=${r.healthRecordId}"><i class="bi bi-pencil-square"></i> Chỉnh sửa</a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                        <div id="completedEmpty" class="doctor-empty mt-3 d-none">Không tìm thấy hồ sơ phù hợp.</div>
                    </c:otherwise>
                </c:choose>
            </section>

            <section class="doctor-card mt-4">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <span class="doctor-stat-icon bg-info-subtle text-info"><i class="bi bi-eyedropper"></i></span>
                    <div>
                        <h2 class="doctor-section-title h5 mb-1">Yêu cầu xét nghiệm đã hoàn thành</h2>
                        <div class="doctor-muted">Kết quả xét nghiệm của các hồ sơ do bác sĩ phụ trách.</div>
                    </div>
                </div>
                <c:choose>
                    <c:when test="${empty completedLaboratoryRequests}">
                        <div class="doctor-empty">Chưa có yêu cầu xét nghiệm hoàn thành.</div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-responsive">
                            <table class="table doctor-table align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th>Mã yêu cầu</th>
                                        <th>Hồ sơ</th>
                                        <th>Loại xét nghiệm</th>
                                        <th>Giá</th>
                                        <th>Ngày hoàn thành</th>
                                        <th>Kết quả</th>
                                        <th class="text-end">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="lab" items="${completedLaboratoryRequests}">
                                        <tr>
                                            <td class="fw-bold">#${lab.laboratoryRequestId}</td>
                                            <td>#${lab.healthRecordId}</td>
                                            <td>${lab.testTypeDisplay}</td>
                                            <td class="fw-semibold"><fmt:formatNumber value="${lab.testPrice}" type="number" groupingUsed="true"/> VNĐ</td>
                                            <td><fmt:formatDate value="${lab.completedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                            <td>
                                                <c:if test="${not empty lab.result}"><div>${lab.result}</div></c:if>
                                                <c:choose>
                                                    <c:when test="${lab.hasMeasurements}">
                                                        <small class="doctor-muted">
                                                            <c:if test="${not empty lab.hba1c}">Đường huyết: ${lab.hba1c} · </c:if>
                                                            <c:if test="${not empty lab.urea}">Urea: ${lab.urea} · </c:if>
                                                            <c:if test="${not empty lab.cr}">Creatinine: ${lab.cr} · </c:if>
                                                            <c:if test="${not empty lab.chol}">Cholesterol: ${lab.chol} · </c:if>
                                                            <c:if test="${not empty lab.tg}">Triglyceride: ${lab.tg} · </c:if>
                                                            <c:if test="${not empty lab.hdl}">HDL: ${lab.hdl} · </c:if>
                                                            <c:if test="${not empty lab.idl}">LDL: ${lab.idl} · </c:if>
                                                            <c:if test="${not empty lab.vldl}">VLDL: ${lab.vldl} · </c:if>
                                                            <c:if test="${not empty lab.bmi}">BMI: ${lab.bmi}</c:if>
                                                            </small>
                                                    </c:when>
                                                    <c:otherwise><span class="doctor-muted">Chưa nhập chỉ số kết quả</span></c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td class="text-end">
                                                <a class="btn btn-sm btn-outline-primary"
                                                   href="${pageContext.request.contextPath}/DetailServlet?record_id=${lab.healthRecordId}">
                                                    <i class="bi bi-eye"></i> Xem hồ sơ
                                                </a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
            </section>
        </main>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
        <script>
                                                    const completedRows = Array.from(document.querySelectorAll("#completedBody tr"));
                                                    document.getElementById("completedSearch")?.addEventListener("input", event => {
                                                        const keyword = event.target.value.trim().toLowerCase();
                                                        let visible = 0;
                                                        completedRows.forEach(row => {
                                                            const matches = row.dataset.search.toLowerCase().includes(keyword);
                                                            row.classList.toggle("d-none", !matches);
                                                            if (matches)
                                                                visible++;
                                                        });
                                                        document.getElementById("completedEmpty")?.classList.toggle("d-none", visible !== 0);
                                                    });
        </script>
    </body>
</html>
