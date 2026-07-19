<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<fmt:setLocale value="vi_VN" />

<c:set var="currentAction" value="manageRooms" />

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý Phòng Khám - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
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
                <p class="text-secondary mb-0">Quản lý danh sách phòng khám & phòng chức năng</p>
            </div>

            <c:if test="${not empty sessionScope.successMessage}">
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    <i class="fa-solid fa-circle-check me-2"></i>${sessionScope.successMessage}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% session.removeAttribute("successMessage"); %>
            </c:if>
            <c:if test="${not empty sessionScope.errorMessage}">
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="fa-solid fa-circle-xmark me-2"></i>${sessionScope.errorMessage}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% session.removeAttribute("errorMessage"); %>
            </c:if>

            <div class="card mb-4">
                <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
                    <span>Thêm phòng khám mới</span>
                </div>
                <div class="card-body">
                    <form class="row g-3" method="post" action="${pageContext.request.contextPath}/admin">
                        <input type="hidden" name="action" value="createRoom">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        
                        <div class="col-md-3">
                            <label class="form-label">Mã phòng</label>
                            <input class="form-control" name="roomId" placeholder="VD: P101, LAB-01" required>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Tên phòng khám</label>
                            <input class="form-control" name="roomName" placeholder="VD: Phòng khám Nội tiết 1" required>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Vị trí / Tầng</label>
                            <input class="form-control" name="location" placeholder="VD: Tầng 1, Nhà A">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Trạng thái</label>
                            <select class="form-select" name="status" required>
                                <option value="Active">Hoạt động</option>
                                <option value="Inactive">Ngừng hoạt động</option>
                            </select>
                        </div>
                        <div class="col-md-1 d-flex align-items-end">
                            <button class="btn btn-primary w-100" type="submit">Thêm</button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
                    <span>Danh sách phòng khám</span>
                    <form class="d-flex gap-2 align-items-center mb-0" method="get" action="${pageContext.request.contextPath}/admin">
                        <input type="hidden" name="action" value="manageRooms">
                        <input class="form-control form-control-sm" name="search" placeholder="Tìm kiếm phòng..." value="${param.search}">
                        <select class="form-select form-select-sm" name="status">
                            <option value="">Tất cả trạng thái</option>
                            <option value="Active" ${param.status == 'Active' ? 'selected' : ''}>Hoạt động</option>
                            <option value="Inactive" ${param.status == 'Inactive' ? 'selected' : ''}>Ngừng hoạt động</option>
                        </select>
                        <button type="submit" class="btn btn-sm btn-secondary">Lọc</button>
                    </form>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                        <tr>
                            <th>Mã phòng</th>
                            <th>Tên phòng</th>
                            <th>Vị trí</th>
                            <th>Trạng thái</th>
                            <th>Thao tác</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:choose>
                            <c:when test="${empty rooms}">
                                <tr>
                                    <td colspan="5" class="text-center text-secondary py-4">Không tìm thấy phòng khám nào phù hợp</td>
                                </tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="r" items="${rooms}">
                                    <tr>
                                        <td class="fw-bold text-dark">${r.roomId}</td>
                                        <td>${r.roomName}</td>
                                        <td>${r.location}</td>
                                        <td>
                                            <span class="badge ${r.status == 'Active' ? 'text-bg-success' : 'text-bg-secondary'}">
                                                ${r.status == 'Active' ? 'Hoạt động' : 'Ngừng hoạt động'}
                                            </span>
                                        </td>
                                        <td>
                                            <div class="d-flex gap-2">
                                                <button type="button"
                                                        class="btn btn-sm btn-outline-primary btn-edit-room"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#editRoomModal"
                                                        data-room-id="${r.roomId}"
                                                        data-room-name="${r.roomName}"
                                                        data-location="${r.location}"
                                                        data-status="${r.status}">
                                                    Chỉnh sửa
                                                </button>
                                                <form method="post" action="${pageContext.request.contextPath}/admin" onsubmit="return confirm('Xóa phòng khám ${r.roomId}? Nếu phòng đang có lịch phân trực, hệ thống sẽ tự động đổi sang trạng thái ngừng hoạt động.');">
                                                    <input type="hidden" name="action" value="deleteRoom">
                                                    <input type="hidden" name="roomId" value="${r.roomId}">
                                                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger">Xóa</button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="editRoomModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="post" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="updateRoom">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <input type="hidden" name="roomId" id="editRoomId">

                <div class="modal-header">
                    <h5 class="modal-title">Chỉnh sửa phòng khám</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Mã phòng</label>
                        <input class="form-control bg-light" id="editRoomIdDisplay" readonly>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tên phòng khám</label>
                        <input class="form-control" name="roomName" id="editRoomName" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Vị trí / Tầng</label>
                        <input class="form-control" name="location" id="editLocation">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Trạng thái</label>
                        <select class="form-select" name="status" id="editRoomStatus" required>
                            <option value="Active">Hoạt động</option>
                            <option value="Inactive">Ngừng hoạt động</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                    <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', () => {
        const editButtons = document.querySelectorAll('.btn-edit-room');
        editButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                const id = btn.getAttribute('data-room-id');
                const name = btn.getAttribute('data-room-name');
                const loc = btn.getAttribute('data-location');
                const status = btn.getAttribute('data-status');

                document.getElementById('editRoomId').value = id;
                document.getElementById('editRoomIdDisplay').value = id;
                document.getElementById('editRoomName').value = name;
                document.getElementById('editLocation').value = loc || '';
                document.getElementById('editRoomStatus').value = status;
            });
        });
    });
</script>
</body>
</html>
