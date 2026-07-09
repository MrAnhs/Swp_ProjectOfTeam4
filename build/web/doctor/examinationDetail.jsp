<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Hồ sơ khám</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/css/doctor-module.css" rel="stylesheet">
    <style>
        .record-hero { background: #0f766e; color: #fff; }
        .record-hero .doctor-muted { color: rgba(255,255,255,.78); }
        .workflow-steps { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
        .workflow-step { border: 1px solid var(--doctor-border); border-radius: 8px; padding: 12px; background: #fff; }
        .workflow-step.active { border-color: var(--doctor-primary); background: #f0fdfa; }
        .info-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
        .info-item { border: 1px solid var(--doctor-border); border-radius: 8px; padding: 14px; background: #f8fafc; }
        .info-label { color: var(--doctor-muted); font-size: .75rem; font-weight: 800; text-transform: uppercase; }
        .info-value { margin-top: 4px; font-weight: 700; overflow-wrap: anywhere; }
        .metric-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
        .metric-box { border: 1px solid var(--doctor-border); border-radius: 8px; padding: 12px; background: #f8fafc; }
        @media (max-width: 900px) {
            .workflow-steps, .info-grid, .metric-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 560px) {
            .workflow-steps, .info-grid, .metric-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body class="doctor-app">
<c:set var="canEditDiagnosis" value="${record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="hasAIResult" value="${record.status == 'AI_Processed' || record.status == 'Editing' || record.status == 'Completed'}"/>
<c:set var="canRunAI" value="${hasCompletedLaboratoryRequest && hasRequiredAIData}"/>

<aside class="doctor-sidebar">
    <div class="doctor-brand">
        <span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span>
        <span>Cổng bác sĩ</span>
    </div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/DashboardServlet"><i class="bi bi-calendar2-check"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/GeneralExaminationListServlet"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/LaboratoryListServlet"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/ExaminationListServlet"><i class="bi bi-clipboard2-pulse-fill"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/CompletedRecordsServlet"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/PatientSearchServlet"><i class="bi bi-search"></i> Tra cứu</a>
        <a class="doctor-nav-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <c:if test="${not empty sessionScope.doctorMessage}">
        <div class="alert alert-info alert-dismissible fade show doctor-alert">
            ${sessionScope.doctorMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorMessage" scope="session"/>
    </c:if>

    <section class="doctor-card record-hero mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between gap-3 align-items-xl-center">
            <div>
                <div class="small opacity-75">Hồ sơ khám #${record.healthRecordId}</div>
                <h1 class="h3 fw-bold mb-1">${record.patientName}</h1>
                <div class="doctor-muted">Bệnh nhân #${record.patientId} · ${patient.age} tuổi · ${patient.gender}</div>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a class="btn btn-light" href="${pageContext.request.contextPath}/DashboardServlet">
                    <i class="bi bi-arrow-left"></i> Quay lại tiếp nhận
                </a>
                <c:if test="${canRunAI}">
                    <form action="${pageContext.request.contextPath}/ProcessAIServlet" method="post">
                        <input type="hidden" name="record_id" value="${record.healthRecordId}">
                        <button class="btn btn-warning" type="submit">
                            <i class="bi bi-robot"></i> Chạy AI
                        </button>
                    </form>
                </c:if>
            </div>
        </div>
    </section>

    <section class="workflow-steps mb-4">
        <div class="workflow-step active">
            <div class="fw-bold">1. Tiếp nhận</div>
            <div class="doctor-muted small">Tạo hồ sơ từ lịch khám</div>
        </div>
        <div class="workflow-step ${!hasLaboratoryRequest ? 'active' : ''}">
            <div class="fw-bold">2. Chỉ định xét nghiệm</div>
            <div class="doctor-muted small">Chọn loại xét nghiệm cần làm</div>
        </div>
        <div class="workflow-step ${hasLaboratoryRequest && !hasCompletedLaboratoryRequest ? 'active' : ''}">
            <div class="fw-bold">3. Chờ kết quả</div>
            <div class="doctor-muted small">Thanh toán và phòng xét nghiệm xử lý</div>
        </div>
        <div class="workflow-step ${hasCompletedLaboratoryRequest ? 'active' : ''}">
            <div class="fw-bold">4. Khám tổng quát</div>
            <div class="doctor-muted small">Đánh giá kết quả và kết luận</div>
        </div>
    </section>

    <section class="doctor-card mb-4">
        <div class="doctor-card-header">
            <div>
                <h2 class="doctor-section-title h5 mb-1">Thông tin bệnh nhân</h2>
                <div class="doctor-muted">Kiểm tra nhanh thông tin trước khi chỉ định xét nghiệm.</div>
            </div>
            <a class="btn btn-outline-primary" href="${pageContext.request.contextPath}/DoctorMedicalHistoryServlet?record_id=${record.healthRecordId}">
                <i class="bi bi-clock-history"></i> Lịch sử bệnh án
            </a>
        </div>
        <div class="info-grid">
            <div class="info-item"><div class="info-label">Mã bệnh nhân</div><div class="info-value">#${patient.patientId}</div></div>
            <div class="info-item"><div class="info-label">Họ tên</div><div class="info-value">${patient.fullName}</div></div>
            <div class="info-item"><div class="info-label">Tuổi</div><div class="info-value">${patient.age}</div></div>
            <div class="info-item"><div class="info-label">Giới tính</div><div class="info-value">${patient.gender}</div></div>
            <div class="info-item"><div class="info-label">Điện thoại</div><div class="info-value">${empty patient.phone ? 'Chưa cập nhật' : patient.phone}</div></div>
            <div class="info-item"><div class="info-label">Email</div><div class="info-value">${empty patient.email ? 'Chưa cập nhật' : patient.email}</div></div>
            <div class="info-item"><div class="info-label">Ngày sinh</div><div class="info-value"><fmt:formatDate value="${patient.dateOfBirth}" pattern="dd/MM/yyyy"/></div></div>
            <div class="info-item"><div class="info-label">Địa chỉ</div><div class="info-value">${empty patient.address ? 'Chưa cập nhật' : patient.address}</div></div>
        </div>
    </section>

    <section id="laboratoryOrder" class="doctor-card mb-4">
        <div class="doctor-card-header">
            <div>
                <h2 class="doctor-section-title h5 mb-1">Chỉ định xét nghiệm</h2>
                <div class="doctor-muted">Bác sĩ chọn một hoặc nhiều loại xét nghiệm cho bệnh nhân trước khi chuyển sang khám tổng quát.</div>
            </div>
            <span class="doctor-soft-badge"><i class="bi bi-receipt"></i> Tạo hóa đơn xét nghiệm</span>
        </div>

        <c:if test="${!hasPaidLaboratoryRequest && record.status != 'Completed'}">
            <form class="row g-3 mb-4 lab-multi-form" method="post"
                  action="${pageContext.request.contextPath}/LaboratoryRequestServlet">
                <input type="hidden" name="record_id" value="${record.healthRecordId}">
                <div class="col-12">
                    <label class="form-label fw-semibold">Loại xét nghiệm</label>
                    <div class="row g-2">
                        <c:forEach var="service" items="${laboratoryServices}">
                            <div class="col-md-6 col-xl-4">
                                <label class="lab-service-option">
                                    <input class="form-check-input" type="checkbox" name="service_id" value="${service.serviceId}">
                                    <span>
                                        <strong>${service.serviceNameDisplay}</strong>
                                        <small><fmt:formatNumber value="${service.price}" type="number" groupingUsed="true"/> VNĐ</small>
                                    </span>
                                </label>
                            </div>
                        </c:forEach>
                    </div>
                </div>
                <div class="col-lg-9">
                    <label class="form-label fw-semibold">Ghi chú cho phòng xét nghiệm</label>
                    <input class="form-control" name="request_note" maxlength="1000"
                           placeholder="Ví dụ: ưu tiên HbA1c, kiểm tra mỡ máu, chức năng thận...">
                </div>
                <div class="col-lg-3 d-flex align-items-end">
                    <button class="btn btn-doctor w-100" type="submit">
                        <i class="bi bi-send"></i> Gửi chỉ định
                    </button>
                </div>
            </form>
        </c:if>

        <c:choose>
            <c:when test="${empty laboratoryRequests}">
                <div class="doctor-empty py-4">Chưa có chỉ định xét nghiệm cho hồ sơ này.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Loại xét nghiệm</th>
                            <th>Giá</th>
                            <th>Thanh toán</th>
                            <th>Ngày yêu cầu</th>
                            <th>Trạng thái</th>
                            <th>Kết quả</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:forEach var="lab" items="${laboratoryRequests}">
                            <tr>
                                <td><strong>${lab.testTypeDisplay}</strong><br><small class="doctor-muted">${lab.requestNote}</small></td>
                                <td><fmt:formatNumber value="${lab.testPrice}" type="number" groupingUsed="true"/> VNĐ</td>
                                <td>${lab.paymentStatusDisplay}</td>
                                <td><fmt:formatDate value="${lab.requestedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td>
                                    <span class="doctor-badge ${lab.status == 'Completed' ? 'badge-completed' : (lab.status == 'Processing' ? 'badge-processing' : 'badge-requested')}">
                                        ${lab.statusDisplay}
                                    </span>
                                </td>
                                <td>${empty lab.result ? 'Chưa có' : lab.result}</td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </section>

    <c:if test="${!hasCompletedLaboratoryRequest && hasLaboratoryRequest}">
        <section class="doctor-card mb-4">
            <div class="d-flex align-items-center gap-3">
                <span class="doctor-stat-icon bg-warning-subtle text-warning"><i class="bi bi-hourglass-split"></i></span>
                <div>
                    <h2 class="doctor-section-title h5 mb-1">Đang chờ kết quả xét nghiệm</h2>
                    <div class="doctor-muted">Khi lễ tân xác nhận thanh toán và phòng xét nghiệm hoàn tất, hồ sơ sẽ chuyển sang bước khám tổng quát/khám chi tiết.</div>
                </div>
            </div>
        </section>
    </c:if>

    <c:if test="${hasCompletedLaboratoryRequest}">
        <section class="doctor-card mb-4">
            <div class="doctor-card-header">
                <div>
                    <h2 class="doctor-section-title h5 mb-1">Khám tổng quát và kết quả xét nghiệm</h2>
                    <div class="doctor-muted">Các chỉ số mới nhất từ phòng xét nghiệm.</div>
                </div>
                <c:if test="${!hasAIResult && hasRequiredAIData}">
                    <form action="${pageContext.request.contextPath}/ProcessAIServlet" method="post">
                        <input type="hidden" name="record_id" value="${record.healthRecordId}">
                        <button class="btn btn-warning" type="submit"><i class="bi bi-robot"></i> Chạy AI</button>
                    </form>
                </c:if>
            </div>
            <div class="metric-grid">
                <div class="metric-box"><div class="info-label">Urea</div><input id="metricUrea" class="form-control form-control-sm" type="number" step="0.01" value="${record.urea}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">Creatinine</div><input id="metricCr" class="form-control form-control-sm" type="number" step="0.01" value="${record.cr}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">HbA1c</div><input id="metricHba1c" class="form-control form-control-sm" type="number" step="0.01" value="${record.hba1c}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">Cholesterol</div><input id="metricChol" class="form-control form-control-sm" type="number" step="0.01" value="${record.chol}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">TG</div><input id="metricTg" class="form-control form-control-sm" type="number" step="0.01" value="${record.tg}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">HDL</div><input id="metricHdl" class="form-control form-control-sm" type="number" step="0.01" value="${record.hdl}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">LDL</div><input id="metricIdl" class="form-control form-control-sm" type="number" step="0.01" value="${record.ldl}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">VLDL</div><input id="metricVldl" class="form-control form-control-sm" type="number" step="0.01" value="${record.vldl}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
                <div class="metric-box"><div class="info-label">BMI</div><input id="metricBmi" class="form-control form-control-sm" type="number" step="0.01" value="${record.bmi}" ${!canEditDiagnosis ? 'disabled' : ''}></div>
            </div>
        </section>

        <c:if test="${hasAIResult}">
            <section class="doctor-card mb-4">
                <h2 class="doctor-section-title h5 mb-3">Kết luận của bác sĩ</h2>
                <div class="row g-3">
                    <div class="col-lg-7">
                        <label class="form-label fw-semibold">Ghi chú bác sĩ</label>
                        <textarea id="doctorNotes" class="form-control" rows="6" ${!canEditDiagnosis ? 'disabled' : ''}>${record.doctor_notes}</textarea>
                    </div>
                    <div class="col-lg-5">
                        <label class="form-label fw-semibold">Chẩn đoán cuối cùng</label>
                        <select id="finalDiagnosis" class="form-select mb-3" ${!canEditDiagnosis ? 'disabled' : ''}>
                            <option value="Bình thường" ${record.finalDiagnosis == 'Bình thường' ? 'selected' : ''}>Bình thường</option>
                            <option value="Tiền tiểu đường" ${record.finalDiagnosis == 'Tiền tiểu đường' ? 'selected' : ''}>Tiền tiểu đường</option>
                            <option value="Tiểu đường" ${record.finalDiagnosis == 'Tiểu đường' ? 'selected' : ''}>Tiểu đường</option>
                        </select>
                        <div class="form-check mb-3">
                            <input id="canView" class="form-check-input" type="checkbox"
                                   ${record.canPatientView ? 'checked' : ''} ${!canEditDiagnosis ? 'disabled' : ''}>
                            <label class="form-check-label" for="canView">Cho phép bệnh nhân xem kết quả</label>
                        </div>
                        <c:if test="${canEditDiagnosis}">
                            <button class="btn btn-doctor w-100" onclick="saveNotes(${record.healthRecordId})">
                                <i class="bi bi-save"></i> Lưu và hoàn thành
                            </button>
                        </c:if>
                    </div>
                </div>
            </section>
        </c:if>
    </c:if>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function metricValue(id) {
    const element = document.getElementById(id);
    return element ? element.value : "";
}

function saveNotes(recordId) {
    const body = new URLSearchParams({
        record_id: recordId,
        notes: document.getElementById("doctorNotes").value,
        diagnosis: document.getElementById("finalDiagnosis").value,
        can_view: document.getElementById("canView").checked,
        urea: metricValue("metricUrea"),
        cr: metricValue("metricCr"),
        hba1c: metricValue("metricHba1c"),
        chol: metricValue("metricChol"),
        tg: metricValue("metricTg"),
        hdl: metricValue("metricHdl"),
        idl: metricValue("metricIdl"),
        vldl: metricValue("metricVldl"),
        bmi: metricValue("metricBmi")
    });
    fetch("${pageContext.request.contextPath}/SaveNotesServlet", {
        method: "POST",
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body.toString()
    })
    .then(async response => {
        const data = await response.json();
        if (!response.ok || !data.success) {
            throw new Error(data.message || "Không thể lưu hồ sơ.");
        }
    })
    .then(() => window.location.href = "${pageContext.request.contextPath}/CompletedRecordsServlet")
    .catch(error => alert(error.message));
}

document.querySelectorAll(".lab-multi-form").forEach(form => {
    const options = form.querySelectorAll(".lab-service-option");
    options.forEach(option => {
        const checkbox = option.querySelector('input[name="service_id"]');
        const updateSelectedState = () => option.classList.toggle("is-selected", checkbox.checked);
        checkbox.addEventListener("change", updateSelectedState);
        updateSelectedState();
    });

    form.addEventListener("submit", event => {
        if (!form.querySelector('input[name="service_id"]:checked')) {
            event.preventDefault();
            alert("Vui lòng chọn ít nhất một loại xét nghiệm.");
        }
    });
});
</script>
</body>
</html>
