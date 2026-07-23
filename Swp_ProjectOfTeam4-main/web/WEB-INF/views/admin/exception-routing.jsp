<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="currentAction" value="exception" />

<%--
    Trang Điều phối khẩn cấp:
    - Xử lý ca khám bị kẹt/ngoại lệ vận hành
    - Tái phân bác sĩ thủ công theo chuyên khoa khả dụng
--%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Điều phối khẩn cấp và xử lý sự cố - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-4">
    <div class="admin-layout row g-3">
        <div class="col-lg-3 admin-sidebar-col">
            <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
        </div>
        <div class="col-lg-9 admin-content-col">
            <div class="admin-page-header mb-3">
                <h3 class="mb-1">Điều phối khẩn cấp và xử lý sự cố</h3>
                <p class="text-secondary mb-0">Quản lý hàng đợi kẹt và tái phân bác sĩ thủ công</p>
            </div>

    <c:if test="${not empty sessionScope.successMessage}">
        <div class="alert alert-success">${sessionScope.successMessage}</div>
        <% session.removeAttribute("successMessage"); %>
    </c:if>
    <c:if test="${not empty sessionScope.errorMessage}">
        <div class="alert alert-danger">${sessionScope.errorMessage}</div>
        <% session.removeAttribute("errorMessage"); %>
    </c:if>

    <div class="card mb-4">
        <div class="card-header fw-semibold">Danh sách ca bệnh đang kẹt trong hàng đợi</div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                <tr>
                    <th>Mã lịch hẹn</th>
                    <th>Bệnh nhân</th>
                    <th>Bác sĩ hiện tại</th>
                    <th>Chuyên khoa</th>
                    <th>Trạng thái</th>
                    <th>Thời gian hẹn</th>
                    <th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="q" items="${queueItems}">
                    <tr>
                        <td>${q.appointmentId}</td>
                        <td>${q.patientName}</td>
                        <td>${q.currentDoctorName}</td>
                        <td>${q.department}</td>
                        <td>
                            <c:choose>
                                <c:when test="${q.appointmentStatus eq 'Waiting'}">
                                    <span class="badge text-bg-warning">Chờ đợi</span>
                                </c:when>
                                <c:when test="${q.appointmentStatus eq 'Checked_In'}">
                                    <span class="badge text-bg-primary">Đã check-in</span>
                                </c:when>
                                <c:when test="${q.appointmentStatus eq 'In_Progress'}">
                                    <span class="badge text-bg-info">Đang khám</span>
                                </c:when>
                                <c:when test="${q.appointmentStatus eq 'Absent'}">
                                    <span class="badge text-bg-secondary">Không đến</span>
                                </c:when>
                                <c:when test="${q.appointmentStatus eq 'Completed'}">
                                    <span class="badge text-bg-success">Hoàn tất</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge text-bg-secondary">${q.appointmentStatus}</span>
                                </c:otherwise>
                            </c:choose>
                        </td>
                        <td>${q.appointmentTime}</td>
                        <td>
                            <a class="btn btn-sm btn-outline-primary"
                               href="${pageContext.request.contextPath}/admin?action=exception&appointmentId=${q.appointmentId}&doctorId=${q.currentDoctorId}">
                                Tái điều phối khẩn cấp
                            </a>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
    </div>

    <c:if test="${not empty selectedQueueItem}">
        <div class="card">
            <div class="card-header fw-semibold">Danh sách bác sĩ thay thế khả dụng</div>
            <div class="card-body">
                <p class="mb-3">Đang xử lý lịch hẹn <strong>#${selectedQueueItem.appointmentId}</strong> của bệnh nhân <strong>${selectedQueueItem.patientName}</strong>.</p>
                <form method="post" action="${pageContext.request.contextPath}/admin" class="row g-3">
                    <input type="hidden" name="action" value="emergencyReassign">
                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                    <input type="hidden" name="appointmentId" value="${selectedQueueItem.appointmentId}">
                    <div class="col-md-8">
                        <label class="form-label">Chọn bác sĩ tái điều phối (có thể chọn nhiều)</label>
                        <select class="form-select" name="targetDoctorId" multiple required size="5">
                            <c:forEach var="d" items="${candidateDoctors}">
                                <option value="${d.doctorId}">${d.fullName} - ${d.department}</option>
                            </c:forEach>
                        </select>
                        <small class="text-muted">Ctrl + Click để chọn nhiều bác sĩ. Bệnh nhân sẽ được phân bác sĩ đầu tiên trong danh sách.</small>
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <button type="submit" class="btn btn-danger w-100">Xác nhận tái điều phối</button>
                    </div>
                </form>
            </div>
        </div>
    </c:if>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>



