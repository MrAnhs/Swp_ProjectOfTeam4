<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phòng xét nghiệm - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor-lab/doctor-lab.css" rel="stylesheet">
</head>
<body class="lab-app">
<%@ include file="/WEB-INF/views/components/doctor-lab/sidebar.jspf" %>

<main class="lab-main">
    <section class="mb-4">
        <div class="lab-eyebrow">Phòng xét nghiệm</div>
        <h1 class="lab-title">Quản lý yêu cầu xét nghiệm</h1>
        <p class="lab-muted mb-0">
            Chỉ hiển thị các yêu cầu xét nghiệm đã được lễ tân xác nhận thanh toán.
        </p>
    </section>

    <c:if test="${not empty sessionScope.doctorLabMessage}">
        <div class="alert alert-success alert-dismissible fade show">
            ${sessionScope.doctorLabMessage}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorLabMessage" scope="session"/>
    </c:if>
    <c:if test="${not empty sessionScope.doctorLabError}">
        <div class="alert alert-danger alert-dismissible fade show">
            ${sessionScope.doctorLabError}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <c:remove var="doctorLabError" scope="session"/>
    </c:if>

    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="lab-stat">
                <div class="lab-stat-icon"><i class="bi bi-clipboard2-pulse"></i></div>
                <strong>${statusCounts.total}</strong>
                <span class="lab-muted">Tổng yêu cầu</span>
            </div>
        </div>
        <div class="col-md-3">
            <div class="lab-stat">
                <div class="lab-stat-icon"><i class="bi bi-hourglass-split"></i></div>
                <strong>${statusCounts.requested}</strong>
                <span class="lab-muted">Chờ xét nghiệm</span>
            </div>
        </div>
        <div class="col-md-3">
            <div class="lab-stat">
                <div class="lab-stat-icon"><i class="bi bi-activity"></i></div>
                <strong>${statusCounts.processing}</strong>
                <span class="lab-muted">Đang xử lý</span>
            </div>
        </div>
        <div class="col-md-3">
            <div class="lab-stat">
                <div class="lab-stat-icon"><i class="bi bi-check2-circle"></i></div>
                <strong>${statusCounts.completed}</strong>
                <span class="lab-muted">Hoàn thành</span>
            </div>
        </div>
    </div>

    <section class="lab-card mb-4">
        <form class="lab-filter" method="get" action="${pageContext.request.contextPath}/doctor-lab/dashboard">
            <div>
                <label class="form-label fw-bold">Trạng thái xét nghiệm</label>
                <select class="form-select" name="status">
                    <option value="All" ${selectedStatus == 'All' ? 'selected' : ''}>Tất cả</option>
                    <option value="Requested" ${selectedStatus == 'Requested' ? 'selected' : ''}>Chờ xét nghiệm</option>
                    <option value="Processing" ${selectedStatus == 'Processing' ? 'selected' : ''}>Đang xử lý</option>
                    <option value="Completed" ${selectedStatus == 'Completed' ? 'selected' : ''}>Hoàn thành</option>
                </select>
            </div>
            <button class="btn btn-success px-4" type="submit">
                <i class="bi bi-funnel"></i> Lọc danh sách
            </button>
        </form>
    </section>

    <section id="request-list" class="lab-card">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
            <div>
                <h2 class="h4 fw-bold mb-1">Danh sách yêu cầu xét nghiệm</h2>
                <div class="lab-muted">Danh sách chỉ hiển thị các yêu cầu xét nghiệm đã được xác nhận thanh toán.</div>
            </div>
        </div>

        <c:choose>
            <c:when test="${empty requests}">
                <div class="text-center py-5 lab-muted">
                    <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                    Chưa có yêu cầu xét nghiệm phù hợp.
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table lab-table align-middle">
                        <thead>
                        <tr>
                            <th>Mã yêu cầu</th>
                            <th>Bệnh nhân</th>
                            <th>Dịch vụ</th>
                            <th>Hóa đơn</th>
                            <th>Ngày yêu cầu</th>
                            <th>Trạng thái</th>
                            <th class="text-end">Thao tác</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:forEach var="item" items="${requests}">
                            <tr>
                                <td class="fw-bold">#${item.invoiceDetailId}</td>
                                <td>
                                    <div class="fw-semibold">${item.patientName}</div>
                                    <small class="lab-muted">BN #${item.patientId} · Hồ sơ #${item.healthRecordId}</small>
                                </td>
                                <td>
                                    <div class="fw-semibold">${item.serviceName}</div>
                                    <small class="lab-muted">${item.requestNote}</small>
                                </td>
                                <td>
                                    <div>#${item.invoiceId}</div>
                                    <small class="lab-muted">
                                        <fmt:formatNumber value="${item.price}" type="number" groupingUsed="true"/> VNĐ
                                    </small>
                                </td>
                                <td><fmt:formatDate value="${item.requestedAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                                <td>
                                    <span class="lab-badge ${item.labStatus == 'Requested' ? 'status-requested' : (item.labStatus == 'Processing' ? 'status-processing' : 'status-completed')}">
                                        ${item.statusDisplay}
                                    </span>
                                </td>
                                <td class="text-end">
                                    <c:if test="${item.labStatus == 'Requested'}">
                                        <form class="d-inline" method="post" action="${pageContext.request.contextPath}/doctor-lab/dashboard">
                                            <input type="hidden" name="action" value="start">
                                            <input type="hidden" name="invoiceDetailId" value="${item.invoiceDetailId}">
                                            <button class="btn btn-sm btn-outline-primary" type="submit">
                                                <i class="bi bi-play-circle"></i> Bắt đầu
                                            </button>
                                        </form>
                                    </c:if>
                                    <c:if test="${item.labStatus == 'Processing'}">
                                        <form class="d-inline" method="post" action="${pageContext.request.contextPath}/doctor-lab/dashboard">
                                            <input type="hidden" name="action" value="complete-random">
                                            <input type="hidden" name="invoiceDetailId" value="${item.invoiceDetailId}">
                                            <button class="btn btn-sm btn-success" type="submit">
                                                <i class="bi bi-shuffle"></i> Random kết quả
                                            </button>
                                        </form>
                                        <button class="btn btn-sm btn-outline-success" type="button"
                                                data-bs-toggle="collapse" data-bs-target="#manual${item.invoiceDetailId}">
                                            Nhập tay
                                        </button>
                                    </c:if>
                                    <c:if test="${item.labStatus == 'Completed'}">
                                        <span class="lab-muted">Đã hoàn tất</span>
                                    </c:if>
                                </td>
                            </tr>
                            <c:if test="${item.labStatus == 'Processing'}">
                                <tr class="collapse" id="manual${item.invoiceDetailId}">
                                    <td colspan="7">
                                        <form method="post" action="${pageContext.request.contextPath}/doctor-lab/dashboard">
                                            <input type="hidden" name="action" value="complete">
                                            <input type="hidden" name="invoiceDetailId" value="${item.invoiceDetailId}">
                                            <div class="metric-grid mb-3">
                                                <label>Urea<input class="form-control" type="number" step="0.01" name="urea"></label>
                                                <label>Creatinine<input class="form-control" type="number" step="0.01" name="cr"></label>
                                                <label>HbA1c<input class="form-control" type="number" step="0.01" name="hba1c"></label>
                                                <label>Cholesterol<input class="form-control" type="number" step="0.01" name="chol"></label>
                                                <label>Triglycerides<input class="form-control" type="number" step="0.01" name="tg"></label>
                                                <label>HDL<input class="form-control" type="number" step="0.01" name="hdl"></label>
                                                <label>LDL<input class="form-control" type="number" step="0.01" name="ldl"></label>
                                                <label>VLDL<input class="form-control" type="number" step="0.01" name="vldl"></label>
                                                <label>Cân nặng<input class="form-control" type="number" step="0.1" name="weight"></label>
                                                <label>Chiều cao<input class="form-control" type="number" step="0.1" name="height"></label>
                                                <label>BMI<input class="form-control" type="number" step="0.01" name="bmi"></label>
                                            </div>
                                            <button class="btn btn-success" type="submit">
                                                <i class="bi bi-save"></i> Lưu kết quả
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            </c:if>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </section>

    <section id="completed-list" class="mt-4 lab-card">
        <h2 class="h5 fw-bold mb-2">Ghi chú vận hành</h2>
        <p class="lab-muted mb-0">
            Phòng xét nghiệm không tạo hồ sơ sức khỏe mới. Kết quả xét nghiệm sẽ được đồng bộ vào hồ sơ
            đã được bác sĩ tạo trước đó.
        </p>
    </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
