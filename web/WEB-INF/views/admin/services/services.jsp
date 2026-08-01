<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<fmt:setLocale value="vi_VN" />



<c:set var="currentAction" value="manageServices" />

<%--
    Trang Quản trị danh mục dịch vụ y tế:
    - CRUD dịch vụ khám/xét nghiệm
    - Quản lý trạng thái Hoạt động/Ngừng hoạt động và đơn giá
--%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Quản trị Danh mục Y tế - DiabetesCare Admin</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">

    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
    <style>
        .table-responsive {
            overflow: visible !important;
        }
        .table-actions .dropdown-menu {
            border: none;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(15, 118, 110, 0.12), 0 1px 8px rgba(0, 0, 0, 0.05);
            padding: 6px;
            min-width: 170px;
            z-index: 1050;
        }
        .table-actions .dropdown-item {
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 0.85rem;
            font-weight: 500;
            display: flex;
            align-items: center;
            width: 100%;
            background: none;
            border: none;
            text-align: left;
        }
        .table-actions .dropdown-item:hover {
            background-color: #f1f5f9;
        }
    </style>
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
                <p class="text-secondary mb-0">Quản lý danh mục dịch vụ y tế</p>
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
        <div class="card-header fw-semibold">Thêm dịch vụ mới</div>
        <div class="card-body">
            <form class="row g-3" method="post" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="createService">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <div class="col-md-4">
                    <label class="form-label">Tên dịch vụ</label>
                    <input class="form-control" name="serviceName" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Loại dịch vụ</label>
                    <select class="form-select" name="serviceType" required>
                        <option value="Examination">Khám bệnh</option>
                        <option value="Lab_Test">Xét nghiệm</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Đơn giá</label>
                    <input class="form-control" type="number" min="0" step="0.01" name="price" required>
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
        <div class="card-header fw-semibold">Danh sách dịch vụ</div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                <tr>
                    <th>ID</th>
                    <th>Tên dịch vụ</th>
                    <th>Loại</th>
                    <th>Đơn giá</th>
                    <th>Trạng thái</th>
                    <th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="s" items="${services}">
                    <tr>
                        <td>${s.serviceId}</td>
                        <td>${s.serviceName}</td>
                        <td>${s.serviceType == 'Examination' ? 'Khám bệnh' : (s.serviceType == 'Lab_Test' ? 'Xét nghiệm' : s.serviceType)}</td>
                        <td><fmt:formatNumber value="${s.price}" type="number" maxFractionDigits="0" groupingUsed="true" /> VNĐ</td>
                        <td>
                            <span class="badge ${s.status == 'Active' ? 'text-bg-success' : 'text-bg-secondary'}">
                                ${s.status == 'Active' ? 'Hoạt động' : 'Ngừng hoạt động'}
                            </span>
                        </td>
                        <td>
                            <div class="dropdown table-actions">
                                <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác dịch vụ">
                                    <i class="bi bi-three-dots-vertical"></i>
                                </button>
                                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                                    <li>
                                        <button type="button"
                                                class="dropdown-item btn-edit-service"
                                                data-bs-toggle="modal"
                                                data-bs-target="#editServiceModal"
                                                data-service-id="${s.serviceId}"
                                                data-service-name="${s.serviceName}"
                                                data-service-type="${s.serviceType}"
                                                data-price="${s.price}"
                                                data-status="${s.status}">
                                            <i class="bi bi-pencil-square me-2 text-primary"></i>Chỉnh sửa
                                        </button>
                                    </li>
                                    <li>
                                        <form method="post" action="${pageContext.request.contextPath}/admin" class="d-inline">
                                            <input type="hidden" name="action" value="updateServiceStatus">
                                            <input type="hidden" name="serviceId" value="${s.serviceId}">
                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                            <input type="hidden" name="status" value="${s.status == 'Active' ? 'Inactive' : 'Active'}">
                                            <button type="submit" class="dropdown-item ${s.status == 'Active' ? 'text-warning' : 'text-success'}">
                                                <i class="bi ${s.status == 'Active' ? 'bi-pause-circle me-2 text-warning' : 'bi-play-circle me-2 text-success'}"></i>
                                                ${s.status == 'Active' ? 'Ngừng hoạt động' : 'Kích hoạt lại'}
                                            </button>
                                        </form>
                                    </li>
                                </ul>
                            </div>
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

<div class="modal fade" id="editServiceModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="post" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="updateService">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <input type="hidden" name="serviceId" id="editServiceId">

                <div class="modal-header">
                    <h5 class="modal-title">Chỉnh sửa dịch vụ y tế</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Tên dịch vụ</label>
                        <input class="form-control" name="serviceName" id="editServiceName" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Loại dịch vụ</label>
                        <select class="form-select" name="serviceType" id="editServiceType" required>
                            <option value="Examination">Khám bệnh</option>
                            <option value="Lab_Test">Xét nghiệm</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Đơn giá</label>
                        <input class="form-control" type="number" min="0" step="0.01" name="price" id="editServicePrice" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Trạng thái</label>
                        <select class="form-select" name="status" id="editServiceStatus" required>
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
    window.AdminConfig = window.AdminConfig || {};
    window.AdminConfig.contextPath = '${pageContext.request.contextPath}';
    window.AdminConfig.csrfToken = '${sessionScope.csrfToken}';
    window.AdminConfig.adminEndpoint = '${pageContext.request.contextPath}/admin';
    window.AdminConfig.loginUrl = '${pageContext.request.contextPath}/login.jsp';
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/services.js?v=20260709-fontfix2"></script>
</body>
</html>




