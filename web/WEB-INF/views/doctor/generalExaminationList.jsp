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
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
</head>
<body class="doctor-app">
<c:set var="activeDoctorPage" value="general-examinations" />
<%@ include file="/WEB-INF/views/components/doctor/sidebar.jspf" %>
<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small">BƯỚC 2 TRONG QUY TRÌNH KHÁM</div>
                <h1 class="doctor-title h3 mb-1">Khám tổng quát</h1>
                <p class="doctor-muted mb-0">Xem thông tin bệnh nhân, triệu chứng và chỉ định xét nghiệm.</p>
            </div>
            <div class="input-group" style="max-width:320px">
                <span class="input-group-text bg-white border-end-0"><i class="bi bi-search"></i></span>
                <input id="generalSearch" class="form-control doctor-filter border-start-0" placeholder="Tìm bệnh nhân hoặc mã hồ sơ">
            </div>
        </div>
    </section>
    <section class="doctor-card">
        <c:choose>
            <c:when test="${empty generalExaminationRecords}">
                <div class="doctor-empty"><i class="bi bi-person-check fs-1 d-block mb-2"></i>Không có hồ sơ chờ khám tổng quát.</div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table doctor-table align-middle mb-0">
                        <thead><tr><th>Hồ sơ</th><th>Bệnh nhân</th><th>Ngày tiếp nhận</th><th>Trạng thái</th><th class="text-end">Thao tác</th></tr></thead>
                        <tbody id="generalBody">
                        <c:forEach var="r" items="${generalExaminationRecords}">
                            <tr data-search="${r.healthRecordId} ${r.patientName}">
                                <td class="fw-bold">#${r.healthRecordId}</td>
                                <td><div class="fw-semibold">${r.patientName}</div><small class="doctor-muted">Bệnh nhân #${r.patientId}</small></td>
                                <td><fmt:formatDate value="${r.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td><span class="doctor-badge badge-accepted">${r.statusDisplayText}</span></td>
                                <td class="text-end">
                                    <a class="btn btn-sm btn-doctor" href="${pageContext.request.contextPath}/doctor/records/general-detail?record_id=${r.healthRecordId}">
                                        <i class="bi bi-person-vcard"></i> Mở khám tổng quát
                                    </a>
                                    <button class="btn btn-sm btn-outline-warning text-white ms-1" type="button" onclick="openTransferModalRow(${r.healthRecordId}, '${r.patientName}')">
                                        <i class="bi bi-arrow-left-right"></i> Chuyển ca
                                    </button>
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

<!-- Modal Chuyển ca -->
<div class="modal fade" id="transferModalList" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content doctor-card border-0" style="background: #0F172A; color: #F8FAFC;">
            <div class="modal-header border-bottom border-secondary border-opacity-25">
                <h5 class="modal-title fw-bold text-white"><i class="bi bi-arrow-left-right text-primary me-2"></i> Chuyển giao hồ sơ cho Bác sĩ ca tiếp theo</h5>
                <button type="button" class="btn-close btn-close-white" onclick="closeTransferModalList()" data-bs-dismiss="modal"></button>
            </div>
            <form action="${pageContext.request.contextPath}/doctor/records/transfer" method="post">
                <input type="hidden" id="modalRecordId" name="record_id" value="">
                <div class="modal-body">
                    <div class="mb-2 text-info small fw-bold" id="modalPatientInfo"></div>
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">CHỌN BÁC SĨ CA TIẾP THEO / TIẾP NHẬN</label>
                        <select name="to_doctor_id" class="form-select" required>
                            <option value="">-- Chọn bác sĩ nhận ca --</option>
                            <c:choose>
                                <c:when test="${not empty availableDoctors}">
                                    <c:forEach var="doc" items="${availableDoctors}">
                                        <option value="${doc.doctorId}">${doc.fullName} (${empty doc.department ? 'Bác sĩ chuyên khoa' : doc.department})</option>
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <option value="" disabled>Không có bác sĩ khác khả dụng</option>
                                </c:otherwise>
                            </c:choose>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">LÝ DO CHUYỂN GIAO CA</label>
                        <textarea name="reason" class="form-control" rows="3" placeholder="Nhập lý do chuyển giao ca..."></textarea>
                    </div>
                </div>
                <div class="modal-footer border-top border-secondary border-opacity-25">
                    <button type="button" class="btn btn-outline-secondary" onclick="closeTransferModalList()" data-bs-dismiss="modal">Hủy</button>
                    <button type="submit" class="btn btn-doctor"><i class="bi bi-send-check me-1"></i> Xác nhận chuyển ca</button>
                </div>
            </form>
        </div>
    </div>
</div>

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

function openTransferModalRow(recordId, patientName) {
    document.getElementById("modalRecordId").value = recordId;
    document.getElementById("modalPatientInfo").textContent = "Hồ sơ #" + recordId + " - Bệnh nhân: " + patientName;
    const modalEl = document.getElementById("transferModalList");
    if (!modalEl) return;
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const bsModal = bootstrap.Modal.getOrCreateInstance(modalEl);
            bsModal.show();
            return;
        }
    } catch (e) {}
    modalEl.classList.add("show");
    modalEl.style.display = "block";
    document.body.classList.add("modal-open");
}

function closeTransferModalList() {
    const modalEl = document.getElementById("transferModalList");
    if (!modalEl) return;
    try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const bsModal = bootstrap.Modal.getInstance(modalEl);
            if (bsModal) bsModal.hide();
        }
    } catch (e) {}
    modalEl.classList.remove("show");
    modalEl.style.display = "none";
    document.body.classList.remove("modal-open");
}
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
