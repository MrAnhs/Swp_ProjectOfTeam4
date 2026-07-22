<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:if test="${empty users and empty errorMessage}">
    <c:redirect url="/admin?action=listUsers"/>
</c:if>

<c:set var="currentAction" value="listUsers" />

<%--
    Trang Quản lý tài khoản:
    - Lọc danh sách account theo role/status
    - Tạo user mới, khóa/mở tài khoản, cập nhật thông tin chi tiết
--%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý tài khoản và phân quyền - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">

    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
    <style>
        tr.account-row { cursor: pointer; }
        tr.account-row,
        tr.account-row-placeholder {
            height: 58px;
        }
        tr.account-row-placeholder td {
            border-bottom-color: #e5edf6;
            color: transparent;
            user-select: none;
        }
        .account-table-footer {
            border-top: 1px solid #e5edf6;
            padding: 0.85rem 1rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            flex-wrap: wrap;
        }
        .account-pagination {
            margin: 0;
        }
        .account-pagination .page-link {
            min-width: 38px;
            text-align: center;
            border-radius: 999px;
            margin-inline: 0.12rem;
            font-weight: 700;
        }
        .account-page-summary {
            color: #64748b;
            font-weight: 600;
        }

        /* Custom styled dropdown table actions matching schedule-management */
        .table-actions .dropdown-menu {
            border: none;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(15, 118, 110, 0.12), 0 1px 8px rgba(0, 0, 0, 0.05);
            padding: 6px;
            min-width: 170px;
            animation: fadeInDropdown 0.2s ease-out;
            z-index: 1050;
        }

        @keyframes fadeInDropdown {
            from {
                opacity: 0;
                transform: translateY(5px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
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

        .table-actions .dropdown-item i {
            font-size: 1rem;
            width: 20px;
        }

        .table-actions .dropdown-item:hover {
            background-color: #f1f5f9;
            color: #0f766e;
        }

        .table-actions .dropdown-item:hover i {
            color: #0f766e !important;
        }

        .table-actions .dropdown-item.text-danger:hover {
            background-color: #fef2f2;
            color: #dc3545;
        }

        .table-actions .dropdown-item.text-danger:hover i {
            color: #dc3545 !important;
        }

        .table-responsive {
            overflow: visible !important;
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
                <p class="text-secondary mb-0">FR-ADM-01: Quản lý tài khoản</p>
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
        <div class="card-header fw-semibold">Tạo tài khoản nhân sự</div>
        <div class="card-body">
            <form class="row g-3" method="post" action="${pageContext.request.contextPath}/admin" id="createAccountForm">
                <input type="hidden" name="action" value="createAccount">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <div class="col-md-3"><label class="form-label">Họ và tên</label><input class="form-control" name="fullName" required></div>
                <div class="col-md-3"><label class="form-label">Email</label><input type="email" class="form-control" name="email" required></div>
                <div class="col-md-2"><label class="form-label">Mật khẩu</label><input type="password" class="form-control" name="password" required></div>
                <div class="col-md-2">
                    <label class="form-label">Vai trò hệ thống</label>
                    <select class="form-select" name="role" id="createRoleSelect" required>
                        <option value="Doctor">Bác sĩ khám</option>
                        <option value="doctor_lab">Bác sĩ xét nghiệm</option>
                        <option value="Receptionist">Nhân viên Lễ tân</option>
                        <option value="Admin">Quản trị viên</option>
                    </select>
                </div>
                <div class="col-md-2" id="specializationContainer">
                    <label class="form-label">Chuyên khoa</label>
                    <input class="form-control" name="specialization" id="specializationInput" placeholder="VD: Nội tiết, Xét nghiệm,...">
                </div>
                <div class="col-md-2 d-flex align-items-end" id="createSubmitBtnCol"><button class="btn btn-primary w-100" type="submit">Tạo</button></div>
            </form>
        </div>
    </div>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const roleSelect = document.getElementById('createRoleSelect');
            const specContainer = document.getElementById('specializationContainer');
            const specInput = document.getElementById('specializationInput');
            function toggleSpec() {
                if (!roleSelect || !specContainer) return;
                const val = roleSelect.value;
                if (val === 'Doctor' || val === 'doctor_lab') {
                    specContainer.style.display = 'block';
                    if (specInput) specInput.required = true;
                } else {
                    specContainer.style.display = 'none';
                    if (specInput) { specInput.required = false; specInput.value = ''; }
                }
            }
            if (roleSelect) {
                roleSelect.addEventListener('change', toggleSpec);
                toggleSpec();
            }
        });
    </script>

    <div class="card">
        <div class="card-header fw-semibold">Danh sách tài khoản</div>
        <div class="card-body border-bottom">
            <form class="row g-2 align-items-end" method="get" action="${pageContext.request.contextPath}/admin">
                <input type="hidden" name="action" value="listUsers">
                <div class="col-md-4">
                    <label class="form-label mb-1">Lọc theo vai trò</label>
                    <select class="form-select" name="role">
                        <option value="" ${empty selectedRole ? 'selected' : ''}>Tất cả vai trò</option>
                        <option value="Patient" ${selectedRole == 'Patient' ? 'selected' : ''}>Bệnh nhân</option>
                        <option value="Doctor" ${selectedRole == 'Doctor' ? 'selected' : ''}>Bác sĩ</option>
                        <option value="doctor_lab" ${selectedRole == 'doctor_lab' ? 'selected' : ''}>Bác sĩ xét nghiệm</option>
                        <option value="Receptionist" ${selectedRole == 'Receptionist' ? 'selected' : ''}>Lễ tân</option>
                        <option value="Admin" ${selectedRole == 'Admin' ? 'selected' : ''}>Quản trị viên</option>
                    </select>
                </div>
                <div class="col-md-3 d-flex gap-2">
                    <button class="btn btn-primary" type="submit">Lọc</button>
                    <a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/admin?action=listUsers">Xóa lọc</a>
                </div>
            </form>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="accountTable">
                <thead class="table-light">
                <tr>
                    <th>ID</th><th>Họ tên</th><th>Email</th><th>Vai trò</th><th>Trạng thái</th><th>Ngày tạo</th><th>Thao tác</th>
                </tr>
                </thead>
                <tbody id="accountTableBody">
                <c:forEach var="u" items="${users}">
                    <tr class="account-row" data-account-id="${u.id}">
                        <td>${u.id}</td>
                        <td>${u.fullName}</td>
                        <td>${u.email}</td>
                        <td>
                            <c:choose>
                                <c:when test="${u.role == 'Patient'}"><span class="badge text-bg-info">Bệnh nhân</span></c:when>
                                <c:when test="${u.role == 'Doctor'}"><span class="badge text-bg-primary">Bác sĩ</span></c:when>
                                <c:when test="${u.role == 'doctor_lab'}"><span class="badge text-bg-success">Bác sĩ xét nghiệm</span></c:when>
                                <c:when test="${u.role == 'Receptionist'}"><span class="badge text-bg-secondary">Lễ tân</span></c:when>
                                <c:when test="${u.role == 'Admin'}"><span class="badge text-bg-dark">Quản trị viên</span></c:when>
                                <c:otherwise><span class="badge text-bg-light">${u.role}</span></c:otherwise>
                            </c:choose>
                        </td>
                        <td>
                            <c:choose>
                                <c:when test="${u.status == 'Active'}"><span class="badge text-bg-success">Hoạt động</span></c:when>
                                <c:when test="${u.status == 'Locked'}"><span class="badge text-bg-warning">Đã khóa</span></c:when>
                                <c:otherwise><span class="badge text-bg-secondary">${u.status}</span></c:otherwise>
                            </c:choose>
                        </td>
                        <td>${u.createdAt}</td>
                        <td>
                            <div class="dropdown table-actions">
                                <button type="button" class="btn btn-sm btn-outline-secondary rounded-circle" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác tài khoản">
                                    <i class="bi bi-three-dots-vertical"></i>
                                </button>
                                <ul class="dropdown-menu dropdown-menu-end">
                                    <li>
                                        <button type="button" class="dropdown-item edit-account-btn" data-account-id="${u.id}">
                                            <i class="bi bi-pencil-square me-2 text-primary"></i>Sửa thông tin
                                        </button>
                                    </li>
                                    <li>
                                        <button type="button" class="dropdown-item change-password-btn" data-account-id="${u.id}" data-account-name="${u.fullName}">
                                            <i class="bi bi-key me-2 text-warning"></i>Đổi mật khẩu
                                        </button>
                                    </li>
                                    <li><hr class="dropdown-divider"></li>
                                    <c:choose>
                                        <c:when test="${u.status == 'Locked'}">
                                            <li>
                                                <form class="confirm-action-form" data-confirm-message="Bạn có chắc muốn kích hoạt lại tài khoản này?" method="post" action="${pageContext.request.contextPath}/admin">
                                                    <input type="hidden" name="action" value="reactivateAccount">
                                                    <input type="hidden" name="accountId" value="${u.id}">
                                                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                    <button class="dropdown-item text-success" type="submit">
                                                        <i class="bi bi-check2-circle me-2"></i>Kích hoạt lại
                                                    </button>
                                                </form>
                                            </li>
                                            <c:if test="${u.role != 'Doctor'}">
                                                <li>
                                                    <form class="confirm-action-form" data-confirm-message="Bạn có chắc muốn xóa tài khoản này? Hành động không thể hoàn tác." method="post" action="${pageContext.request.contextPath}/admin">
                                                        <input type="hidden" name="action" value="deleteAccount">
                                                        <input type="hidden" name="accountId" value="${u.id}">
                                                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                        <button class="dropdown-item text-danger" type="submit">
                                                            <i class="bi bi-trash me-2"></i>Xóa tài khoản
                                                        </button>
                                                    </form>
                                                </li>
                                            </c:if>
                                        </c:when>
                                        <c:otherwise>
                                            <li>
                                                <c:choose>
                                                    <c:when test="${u.role == 'Doctor'}">
                                                        <form class="confirm-action-form" data-confirm-message="Bạn có chắc muốn vô hiệu hóa tài khoản bác sĩ này?" method="post" action="${pageContext.request.contextPath}/admin">
                                                            <input type="hidden" name="action" value="lockAccount">
                                                            <input type="hidden" name="accountId" value="${u.id}">
                                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                            <button class="dropdown-item text-warning" type="submit">
                                                                <i class="bi bi-lock me-2"></i>Vô hiệu hóa
                                                            </button>
                                                        </form>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <form class="confirm-action-form" data-confirm-message="Bạn có chắc muốn khóa tài khoản này?" method="post" action="${pageContext.request.contextPath}/admin">
                                                            <input type="hidden" name="action" value="lockAccount">
                                                            <input type="hidden" name="accountId" value="${u.id}">
                                                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                            <button class="dropdown-item text-warning" type="submit">
                                                                <i class="bi bi-lock me-2"></i>Khóa tài khoản
                                                            </button>
                                                        </form>
                                                    </c:otherwise>
                                                </c:choose>
                                            </li>
                                            <c:if test="${u.role != 'Doctor'}">
                                                <li>
                                                    <form class="confirm-action-form" data-confirm-message="Bạn có chắc muốn xóa tài khoản này? Hành động không thể hoàn tác." method="post" action="${pageContext.request.contextPath}/admin">
                                                        <input type="hidden" name="action" value="deleteAccount">
                                                        <input type="hidden" name="accountId" value="${u.id}">
                                                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                        <button class="dropdown-item text-danger" type="submit">
                                                            <i class="bi bi-trash me-2"></i>Xóa tài khoản
                                                        </button>
                                                    </form>
                                                </li>
                                            </c:if>
                                        </c:otherwise>
                                    </c:choose>
                                </ul>
                            </div>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
        <div class="account-table-footer" id="accountTableFooter" hidden>
            <div class="account-page-summary" id="accountPageSummary"></div>
            <nav aria-label="Phân trang danh sách tài khoản">
                <ul class="pagination account-pagination" id="accountPagination"></ul>
            </nav>
        </div>
    </div>
        </div>
    </div>
</div>

<div class="modal fade" id="viewAccountModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Thông tin tài khoản</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="alert alert-light border" id="viewRoleInfo">Vai trò: -</div>
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label text-secondary">Họ và tên</label>
                        <div class="form-control bg-light" id="viewFullName">-</div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label text-secondary">Email</label>
                        <div class="form-control bg-light" id="viewEmail">-</div>
                    </div>
                    <div class="col-md-6 d-none" id="viewPhoneWrap">
                        <label class="form-label text-secondary">Số điện thoại</label>
                        <div class="form-control bg-light" id="viewPhone">-</div>
                    </div>
                    <div class="col-md-6 d-none" id="viewDepartmentWrap">
                        <label class="form-label text-secondary">Chuyên khoa</label>
                        <div class="form-control bg-light" id="viewDepartment">-</div>
                    </div>
                    <div class="col-12 d-none" id="viewAddressWrap">
                        <label class="form-label text-secondary">Địa chỉ</label>
                        <div class="form-control bg-light" id="viewAddress">-</div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="actionConfirmModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
            <div class="modal-header">
                <h5 class="modal-title" id="actionConfirmTitle">Xác nhận thao tác</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p class="mb-0" id="actionConfirmMessage">Bạn có chắc muốn tiếp tục?</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                <button type="button" class="btn btn-warning" id="actionConfirmSubmitBtn">Xác nhận</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="editAccountModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <form method="post" action="${pageContext.request.contextPath}/admin" id="editAccountForm">
                <input type="hidden" name="action" value="updateAccountProfile">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <input type="hidden" name="accountId" id="editAccountId">

                <div class="modal-header">
                    <h5 class="modal-title">Chỉnh sửa hồ sơ tài khoản</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">
                    <div class="alert alert-light border" id="editRoleInfo">Vai trò: -</div>

                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">Họ và tên</label>
                            <input class="form-control" name="fullName" id="editFullName" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Email</label>
                            <input type="email" class="form-control" name="email" id="editEmail" required>
                        </div>

                        <div class="col-md-6 d-none" id="editPhoneWrap">
                            <label class="form-label">Số điện thoại</label>
                            <input class="form-control" name="phone" id="editPhone">
                        </div>

                        <div class="col-md-6 d-none" id="editDepartmentWrap">
                            <label class="form-label">Chuyên khoa (Bác sĩ)</label>
                            <select class="form-select" name="department" id="editDepartment">
                                <option value="Endocrinology">Nội tiết - Tiểu đường</option>
                                <option value="Cardiology">Tim mạch</option>
                                <option value="Nephrology">Thận học</option>
                                <option value="General">Tổng quát</option>
                            </select>
                        </div>

                        <div class="col-12 d-none" id="editAddressWrap">
                            <label class="form-label">Địa chỉ (Bệnh nhân)</label>
                            <input class="form-control" name="address" id="editAddress">
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="changePasswordModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <form method="post" action="${pageContext.request.contextPath}/admin" id="changePasswordForm">
                <input type="hidden" name="action" value="updateAccountPassword">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <input type="hidden" name="accountId" id="pwdAccountId">

                <div class="modal-header">
                    <h5 class="modal-title">Đổi mật khẩu tài khoản</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">
                    <div class="alert alert-warning py-2 mb-3">
                        <i class="fa-solid fa-triangle-exclamation me-2"></i>
                        Đang thao tác đổi mật khẩu cho tài khoản: <strong id="pwdAccountName">-</strong>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-bold">Mật khẩu mới</label>
                        <input type="password" class="form-control" name="newPassword" id="newPassword" placeholder="Nhập từ 6 đến 50 ký tự..." minlength="6" maxlength="50" required>
                        <div class="form-text text-muted">Mật khẩu sẽ được mã hóa an toàn khi lưu trữ.</div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                    <button type="submit" class="btn btn-warning fw-bold text-dark">✓ Xác nhận đổi mật khẩu</button>
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
<script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/users.js?v=20260709-fontfix2"></script>
</body>
</html>




