<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="currentAction" value="schedule" />

<c:if test="${empty schedules and empty errorMessage}">
    <c:redirect url="/admin?action=manageSchedules"/>
</c:if>

<%--
    Trang Schedules (legacy):
    - Màn cấu hình lịch trực cũ
    - Hiện vẫn giữ để tương thích điều hướng/hệ thống hiện tại
--%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cấu hình Lịch trực Bác sĩ - S-COMS</title>
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
                <h3 class="mb-1">Hệ thống Điều hành & Quản trị Danh mục S-COMS</h3>
                <p class="text-secondary mb-0">Cấu hình lịch trực bác sĩ và giám sát sức chứa</p>
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
        <div class="card-header fw-semibold">Thiết lập ca trực</div>
        <div class="card-body">
            <form class="row g-3" method="post" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="createSchedule">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <div class="col-md-4">
                    <label class="form-label">Bác sĩ</label>
                    <select class="form-select" name="doctorId" required>
                        <c:forEach var="d" items="${doctors}">
                            <option value="${d.doctorId}">${d.fullName}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Ngày làm việc</label>
                    <input type="date" class="form-control" name="workDate" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Khung giờ</label>
                    <input class="form-control" name="timeSlot" placeholder="07:00-09:00" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Số BN tối đa</label>
                    <input type="number" class="form-control" min="1" name="maxPatients" required>
                </div>
                <div class="col-md-1 d-flex align-items-end">
                    <button class="btn btn-primary w-100" type="submit">Thêm</button>
                </div>
            </form>
        </div>
    </div>

    <div class="card">
        <div class="card-header fw-semibold">Danh sách lịch trực</div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                <tr>
                    <th>ID</th>
                    <th>Bác sĩ</th>
                    <th>Ngày</th>
                    <th>Khung giờ</th>
                    <th>Giới hạn</th>
                    <th>Số ca đang xử lý</th>
                    <th>Trạng thái hiệu lực</th>
                    <th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="s" items="${schedules}">
                    <tr>
                        <td>${s.scheduleId}</td>
                        <td>${s.doctorName}</td>
                        <td>${s.workDate}</td>
                        <td>${s.timeSlot}</td>
                        <td>${s.maxPatients}</td>
                        <td>${s.activeAppointments}</td>
                        <td>
                            <span class="badge ${s.effectiveStatus == 'Full' ? 'text-bg-danger' : (s.effectiveStatus == 'Cancelled' ? 'text-bg-secondary' : 'text-bg-success')}">
                                ${s.effectiveStatus == 'Full' ? 'Đầy lịch' : (s.effectiveStatus == 'Cancelled' ? 'Đã hủy' : 'Còn chỗ')}
                            </span>
                        </td>
                        <td>
                            <form method="post" action="${pageContext.request.contextPath}/admin" onsubmit="return confirm('Xóa lịch trực này?');">
                                <input type="hidden" name="action" value="deleteSchedule">
                                <input type="hidden" name="scheduleId" value="${s.scheduleId}">
                                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                <button type="submit" class="btn btn-sm btn-outline-danger">Xóa</button>
                            </form>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
    </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>



