<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="currentAction" value="exception" />

<%--
    Trang hồ sơ sức khỏe (ngoại lệ vận hành):
    - Hiển thị dữ liệu hồ sơ sức khỏe phục vụ điều phối khẩn
    - Hỗ trợ thao tác kiểm tra, rà soát trạng thái hồ sơ
--%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Điều phối khẩn cấp và xử lý sự cố - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-4 admin-page-shell">
    <div class="admin-layout row g-3">
        <div class="col-lg-3 admin-sidebar-col">
            <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
        </div>
        <div class="col-lg-9 admin-content-col">
            <div class="admin-page-header d-flex justify-content-between align-items-center mb-4">
                <div>
                    <div class="d-flex align-items-center gap-2 mb-2">
                        <span class="badge text-bg-danger"><i class="bi bi-exclamation-triangle me-1"></i> Ngoại lệ vận hành</span>
                        <span class="badge text-bg-light border text-secondary">BR-08</span>
                    </div>
                    <h3 class="mb-1">Điều phối khẩn cấp và xử lý sự cố</h3>
                    <p class="text-secondary mb-0">Chỉ dùng khi có xung đột lịch trực, bác sĩ nghỉ đột xuất hoặc dữ liệu xét nghiệm cần can thiệp.</p>
                </div>
                <div class="d-flex gap-2 flex-wrap">
                    <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin?action=exception">Mở điều phối</a>
                </div>
            </div>

    <div class="alert alert-warning d-flex gap-3 align-items-start mb-4">
        <i class="bi bi-info-circle fs-4"></i>
        <div>
            <strong>Nguyên tắc vận hành:</strong>
            luồng khám thông thường được điều khiển bằng trạng thái Appointment và lịch trực. Admin chỉ can thiệp khi có ngoại lệ hoặc quá tải, không phân luồng thủ công hàng loạt.
        </div>
    </div>

    <div class="row g-4">
        <div class="col-lg-7">
            <div class="card h-100">
                <div class="card-header fw-semibold">
                    <i class="bi bi-list-check me-2 text-primary"></i> Quy trình xử lý ngoại lệ
                </div>
                <div class="card-body">
                    <div class="d-grid gap-3">
                        <div class="d-flex gap-3">
                            <span class="badge text-bg-primary align-self-start">1</span>
                            <div>
                                <h6 class="mb-1">Xác nhận sự cố</h6>
                                <p class="text-secondary mb-0">Kiểm tra bác sĩ vắng, lịch bị trùng, hàng đợi quá tải hoặc hồ sơ xét nghiệm không khớp.</p>
                            </div>
                        </div>
                        <div class="d-flex gap-3">
                            <span class="badge text-bg-primary align-self-start">2</span>
                            <div>
                                <h6 class="mb-1">Điều chỉnh điểm nghẽn</h6>
                                <p class="text-secondary mb-0">Cập nhật lịch trực, chuyển trạng thái slot hoặc tái phân bác sĩ thay thế trong màn hình điều phối.</p>
                            </div>
                        </div>
                        <div class="d-flex gap-3">
                            <span class="badge text-bg-primary align-self-start">3</span>
                            <div>
                                <h6 class="mb-1">Ghi nhận và thông báo</h6>
                                <p class="text-secondary mb-0">Lưu lý do xử lý, thông báo cho lễ tân/bác sĩ và theo dõi lại dashboard vận hành trong ngày.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="card h-100">
                <div class="card-header fw-semibold">
                    <i class="bi bi-lightning-charge me-2 text-warning"></i> Truy cập nhanh
                </div>
                <div class="card-body d-grid gap-3">
                    <a class="btn btn-outline-primary text-start" href="${pageContext.request.contextPath}/admin?action=manageSchedules">
                        <i class="bi bi-calendar2-week me-2"></i> Mở quản lý lịch trực
                    </a>
                    <a class="btn btn-outline-secondary text-start" href="${pageContext.request.contextPath}/admin?action=reports">
                        <i class="bi bi-graph-up-arrow me-2"></i> Mở báo cáo tổng hợp
                    </a>
                    <a class="btn btn-outline-danger text-start" href="${pageContext.request.contextPath}/admin?action=exception">
                        <i class="bi bi-arrow-left-right me-2"></i> Điều phối ca đang kẹt
                    </a>
                    <a class="btn btn-primary text-start" href="${pageContext.request.contextPath}/admin">
                        <i class="bi bi-speedometer2 me-2"></i> Quay lại tổng quan quản trị
                    </a>
                </div>
            </div>
        </div>
    </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
