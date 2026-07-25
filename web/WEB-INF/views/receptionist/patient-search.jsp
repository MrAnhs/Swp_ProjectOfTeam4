<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="currentPage" value="patient-search" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tìm bệnh nhân</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/receptionist/receptionist.css?v=20260725-uidesign2" rel="stylesheet">
</head>
<body class="receptionist-page">
<div class="receptionist-shell">
    <%@ include file="/WEB-INF/views/components/receptionist/sidebar.jspf" %>
    <main class="receptionist-main">
        <div class="page-kicker">Tra cứu</div>
        <h1 class="page-title">Tìm bệnh nhân</h1>
        <p class="page-subtitle">Nhập số điện thoại để xem thông tin bệnh nhân và lịch hẹn gần nhất.</p>

        <section class="panel-card mt-4">
            <div class="row g-3 align-items-end">
                <div class="col-md-8">
                    <label class="form-label fw-semibold" for="patientSearchPhone">Số điện thoại</label>
                    <input id="patientSearchPhone" class="form-control form-control-lg" placeholder="Ví dụ: 0912345678">
                </div>
                <div class="col-md-4 d-grid">
                    <button id="patientSearchBtn" class="btn btn-primary btn-lg" type="button">
                        <i class="bi bi-search me-1"></i>Tìm kiếm
                    </button>
                </div>
            </div>
        </section>

        <section id="patientSearchResult" class="result-card mt-4 d-none"></section>
        <section id="patientSearchEmpty" class="empty-state mt-4">Chưa có dữ liệu tra cứu.</section>
    </main>
</div>

<!-- Modal Xác Nhận Hủy Lịch Khám -->
<div class="modal fade" id="confirmCancelModal" tabindex="-1" aria-labelledby="confirmCancelModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-danger text-white border-0">
                <h5 class="modal-title fw-bold" id="confirmCancelModalLabel">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i>Xác Nhận Hủy Lịch Khám
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <p id="cancelModalMessage" class="fs-6 mb-3">
                    Bạn có chắc chắn muốn hủy lịch khám này không?
                </p>
                <div class="mb-3">
                    <label for="cancelReasonInput" class="form-label fw-semibold text-secondary small">Lý do hủy (Không bắt buộc)</label>
                    <input type="text" id="cancelReasonInput" class="form-control" placeholder="Nhập lý do hủy lịch...">
                </div>
                <div class="alert alert-warning small mb-0">
                    <i class="bi bi-info-circle me-1"></i>Slot khám sẽ được nhả lại cho Bác sĩ và thông báo sẽ tự động gửi tới Bệnh nhân.
                </div>
            </div>
            <div class="modal-footer bg-light border-0">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy bỏ</button>
                <button type="button" id="confirmCancelSubmitBtn" class="btn btn-danger px-4">
                    <i class="bi bi-check-circle me-1"></i>Xác Nhận Hủy
                </button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    window.ReceptionistConfig = {
        contextPath: '${pageContext.request.contextPath}',
        apiBase: '${pageContext.request.contextPath}/receptionist/api'
    };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/receptionist-utils.js?v=20260725-uidesign2"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/receptionist/patient-search.js?v=20260725-uidesign2"></script>
</body>
</html>
