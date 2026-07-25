<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
                <fmt:setLocale value="vi_VN" />
                <c:set var="currentAction" value="schedule" />

                <%-- Trang Quản lý lịch trực bác sĩ: Lọc, xem tải ca trực, tạo ca thủ công & tích hợp modal AI lập lịch
                    --%>

                    <!DOCTYPE html>
                    <html lang="vi">

                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Quản lý Lịch trực Bác sĩ - S-COMS</title>
                        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
                            rel="stylesheet">
                        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css"
                            rel="stylesheet">

                        <link rel="stylesheet"
                            href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
                        <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css"
                            rel="stylesheet">
                        <style>
                            .shift-card {
                                background: #ffffff;
                                border: 1px solid #e2e8f0;
                                border-left: 4px solid #7c3aed;
                                border-radius: 8px;
                                padding: 6px 8px;
                                margin-bottom: 6px;
                                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
                                cursor: pointer;
                                transition: all 0.2s ease-in-out;
                            }

                            .shift-card:hover {
                                transform: translateY(-2px);
                                box-shadow: 0 4px 8px rgba(124, 58, 237, 0.15);
                            }

                            .shift-card.role-Doctor,
                            .shift-card.role-doctor {
                                border-left-color: #7c3aed;
                                background: #fdf4ff;
                            }

                            .shift-card.role-Reception,
                            .shift-card.role-Receptionist,
                            .shift-card.role-receptionist {
                                border-left-color: #0284c7;
                                background: #f0f9ff;
                            }

                            .shift-card.role-Lab,
                            .shift-card.role-doctor_lab {
                                border-left-color: #d97706;
                                background: #fffbeb;
                            }

                            .shift-card.is-conflict {
                                border: 1px solid #ef4444 !important;
                                border-left: 4px solid #dc2626 !important;
                                background: #fef2f2 !important;
                            }

                            .cal-cell {
                                min-height: 100px;
                                vertical-align: top;
                                padding: 6px !important;
                                background-color: #fafafa;
                            }

                            .cal-cell:hover {
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
                                    <div
                                        class="admin-page-header schedule-page-header d-flex justify-content-between align-items-center mb-3">
                                        <div>
                                            <h3 class="mb-1">Quản lý lịch trực</h3>
                                        </div>
                                        <div class="d-flex gap-2">
                                            <!-- Dropdown Lập lịch thông minh -->
                                            <div class="custom-dropdown-container">
                                                <button type="button" class="btn text-white fw-bold shadow-sm"
                                                    id="aiScheduleGeminiBtn"
                                                    style="background: linear-gradient(135deg, #7c3aed, #6d28d9); border: 1px solid #6d28d9;">
                                                    <i class="fa-solid fa-wand-magic-sparkles me-2"></i>✦ Lập
                                                    lịch AI thông minh
                                                </button>
                                                <div class="custom-dropdown-menu-list shadow border-0"
                                                    id="aiScheduleGeminiMenu">
                                                    <a class="dropdown-item ai-universal-trigger py-2" href="#"
                                                        data-bs-toggle="modal" data-bs-target="#aiScheduleModal"
                                                        data-staff-type="Doctor"><i
                                                            class="fa-solid fa-user-doctor me-2 text-teal"></i>Lập
                                                        lịch Bác sĩ khám</a>
                                                    <a class="dropdown-item ai-universal-trigger py-2" href="#"
                                                        data-bs-toggle="modal" data-bs-target="#aiScheduleModal"
                                                        data-staff-type="Receptionist"><i
                                                            class="fa-solid fa-headset me-2 text-primary"></i>Lập
                                                        lịch Lễ tân</a>
                                                    <a class="dropdown-item ai-universal-trigger py-2" href="#"
                                                        data-bs-toggle="modal" data-bs-target="#aiScheduleModal"
                                                        data-staff-type="doctor_lab"><i
                                                            class="fa-solid fa-flask-vial me-2 text-warning"></i>Lập
                                                        lịch Bác sĩ xét nghiệm</a>
                                                </div>
                                            </div>
                                            <!-- Dropdown Tạo ca trực -->
                                            <div class="custom-dropdown-container">
                                                <button type="button" class="btn btn-primary fw-bold"
                                                    id="createScheduleToolbarBtn">
                                                    <i class="fa-solid fa-plus me-2"></i>Tạo ca trực
                                                </button>
                                                <div class="custom-dropdown-menu-list shadow border-0"
                                                    id="createScheduleToolbarMenu">
                                                    <a class="dropdown-item py-2" href="#" data-bs-toggle="modal"
                                                        data-bs-target="#createScheduleModal"><i
                                                            class="fa-solid fa-user-doctor me-2 text-teal"></i>Ca
                                                        trực Bác sĩ khám</a>
                                                    <a class="dropdown-item py-2" href="#" data-bs-toggle="modal"
                                                        data-bs-target="#createReceptionistScheduleModal"><i
                                                            class="fa-solid fa-headset me-2 text-primary"></i>Ca
                                                        trực Lễ tân</a>
                                                    <a class="dropdown-item py-2" href="#" data-bs-toggle="modal"
                                                        data-bs-target="#createLabScheduleModal"><i
                                                            class="fa-solid fa-flask-vial me-2 text-warning"></i>Ca
                                                        trực Bác sĩ xét nghiệm</a>
                                                </div>
                                            </div>
                                         </div>
                                     </div>

                                     <c:if test="${not empty sessionScope.successMessage}">
                                         <div class="alert alert-success alert-dismissible fade show border-0 shadow-sm rounded-3 mb-3" role="alert">
                                             <i class="fa-solid fa-circle-check me-2"></i><c:out value="${sessionScope.successMessage}" />
                                             <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                                         </div>
                                         <c:remove var="successMessage" scope="session" />
                                     </c:if>
                                     <c:if test="${not empty sessionScope.errorMessage}">
                                         <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm rounded-3 mb-3" role="alert">
                                             <i class="fa-solid fa-triangle-exclamation me-2"></i><c:out value="${sessionScope.errorMessage}" />
                                             <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                                         </div>
                                         <c:remove var="errorMessage" scope="session" />
                                     </c:if>

                                     <!-- Unified Filter Bar -->
                                    <div class="card border-0 shadow-sm mb-3" style="border-radius: 16px;">
                                        <div class="card-body p-3">
                                            <div id="unifiedFilterForm" class="row g-2 align-items-center">
                                                <!-- Vai trò -->
                                                <c:set var="currentRoleFilter"
                                                    value="${empty param.roleFilter ? 'Doctor' : param.roleFilter}" />
                                                <div class="col-md-3" id="unifiedRoleFilterContainer">
                                                    <label class="form-label text-secondary small fw-bold mb-1">Vai trò nhân sự</label>
                                                    <select id="unifiedRoleFilter" name="roleFilter"
                                                        class="form-select form-select-sm" style="border-radius: 8px; font-weight: 600;">
                                                        <option value="Doctor" ${currentRoleFilter=='Doctor'
                                                            ? 'selected' : '' }>🩺 Bác sĩ khám</option>
                                                        <option value="Receptionist" ${currentRoleFilter=='Receptionist'
                                                            ? 'selected' : '' }>🎧 Lễ tân</option>
                                                        <option value="doctor_lab" ${currentRoleFilter=='doctor_lab'
                                                            ? 'selected' : '' }>🧪 Bác sĩ xét nghiệm</option>
                                                        <option value="all" ${currentRoleFilter=='all' ? 'selected' : ''
                                                            }>Tất cả vai trò</option>
                                                    </select>
                                                </div>

                                                <!-- Chọn tuần -->
                                                <div class="col-md-4" id="unifiedTimeFilterContainer">
                                                    <label id="filterTimeLabel" class="form-label text-secondary small fw-bold mb-1">Chọn tuần trực</label>

                                                    <jsp:useBean id="nowDate" class="java.util.Date" />
                                                    <fmt:formatDate var="todayIso" value="${nowDate}" pattern="yyyy-MM-dd" />
                                                    <c:set var="currentWeekDate" value="${empty param.weekDate ? todayIso : param.weekDate}" />

                                                    <!-- Picker Tuần -->
                                                    <div id="filterWeekPickerGroup" class="input-group input-group-sm flex-nowrap" style="flex-wrap: nowrap !important; display: flex !important;">
                                                        <button type="button" id="unifiedPrevWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần trước" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;">
                                                            <i class="fa-solid fa-chevron-left"></i>
                                                        </button>
                                                        <input type="date" id="unifiedWeekPicker" name="weekDate" value="${currentWeekDate}" class="form-control text-center px-1 fw-semibold" style="font-size: 0.85rem;">
                                                        <button type="button" id="unifiedTodayBtn" class="btn btn-sm btn-primary px-3 fw-bold shadow-sm" style="font-size: 0.82rem; white-space: nowrap; background: linear-gradient(135deg, #0d6efd 0%, #0b5ed7 100%); border: none;" title="Về tuần hôm nay">
                                                            <i class="fa-solid fa-calendar-day me-1"></i>Hôm nay
                                                        </button>
                                                        <button type="button" id="unifiedNextWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần sau" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;">
                                                            <i class="fa-solid fa-chevron-right"></i>
                                                        </button>
                                                    </div>
                                                </div>

                                                <!-- Tìm kiếm -->
                                                <div class="col-md-3" id="unifiedSearchContainer">
                                                    <label class="form-label text-secondary small fw-bold mb-1">Tìm kiếm nhân sự</label>
                                                    <div class="input-group input-group-sm">
                                                        <span class="input-group-text bg-white border-end-0" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;"><i class="fa-solid fa-magnifying-glass text-muted"></i></span>
                                                        <input type="text" id="unifiedSearchInput" name="search" class="form-control border-start-0" placeholder="Tên nhân sự..." value="${not empty searchFilter ? searchFilter : param.search}" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;">
                                                    </div>
                                                </div>

                                                <!-- Nút Reset -->
                                                <div class="col-md-2 d-flex align-items-end" id="unifiedFilterActionContainer" style="margin-top: 24px;">
                                                    <button type="button" id="unifiedFilterResetBtn" class="btn btn-sm btn-outline-secondary w-100 py-1 fw-semibold" style="border-radius: 8px;" title="Đặt lại bộ lọc">
                                                        <i class="fa-solid fa-rotate-left me-1"></i>Đặt lại
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="tab-content" id="scheduleRoleTabContent">
                                        <!-- Alert Cảnh báo xung đột nếu có -->
                                        <div id="calendarConflictAlert"
                                            class="alert alert-danger d-none mb-3 py-2 px-3 align-items-center justify-content-between flex-wrap gap-2"
                                            style="border-radius: 12px;">
                                            <div class="d-flex align-items-center gap-2">
                                                <i class="bi bi-exclamation-triangle-fill fs-5 text-danger me-1"></i>
                                                <span id="calendarConflictSummaryText" class="fw-semibold">Phát hiện
                                                    xung đột trùng ca hoặc
                                                    trùng phòng làm việc! Thẻ bị trùng đang được khoanh viền
                                                    đỏ ⚠</span>
                                            </div>
                                            <button type="button" class="btn btn-sm btn-danger fw-bold px-3 py-1"
                                                onclick="openResolveConflictModal()" style="border-radius: 8px;">
                                                <i class="fa-solid fa-wand-magic-sparkles me-1"></i>Tháo gỡ
                                                xung đột
                                            </button>
                                        </div>

                                        <!-- Weekly Grid Calendar -->
                                        <div class="card border-0 shadow-sm mb-4"
                                            style="border-radius: 16px; overflow: hidden;">
                                            <div class="table-responsive">
                                                <table
                                                    class="table table-bordered align-middle text-center mb-0 calendar-table">
                                                    <thead class="table-light">
                                                        <tr id="calendarWeekHeadRow">
                                                            <th style="width: 120px;" class="bg-light align-middle">Ca /
                                                                Giờ</th>
                                                            <th class="cal-head-col" data-day="1">Thứ
                                                                2<br><small class="text-muted fw-normal"
                                                                    id="date-head-mon">-</small></th>
                                                            <th class="cal-head-col" data-day="2">Thứ
                                                                3<br><small class="text-muted fw-normal"
                                                                    id="date-head-tue">-</small></th>
                                                            <th class="cal-head-col" data-day="3">Thứ
                                                                4<br><small class="text-muted fw-normal"
                                                                    id="date-head-wed">-</small></th>
                                                            <th class="cal-head-col" data-day="4">Thứ
                                                                5<br><small class="text-muted fw-normal"
                                                                    id="date-head-thu">-</small></th>
                                                            <th class="cal-head-col" data-day="5">Thứ
                                                                6<br><small class="text-muted fw-normal"
                                                                    id="date-head-fri">-</small></th>
                                                            <th class="cal-head-col" data-day="6">Thứ
                                                                7<br><small class="text-muted fw-normal"
                                                                    id="date-head-sat">-</small></th>
                                                            <th class="cal-head-col" data-day="0">Chủ
                                                                nhật<br><small class="text-muted fw-normal"
                                                                    id="date-head-sun">-</small></th>
                                                        </tr>
                                                        <script>
                                                            (function syncHeadersInline() {
                                                                try {
                                                                    const picker = document.getElementById('unifiedWeekPicker') || document.getElementById('calendarWeekPicker');
                                                                    let raw = picker ? picker.value : '';
                                                                    let baseDate = new Date();
                                                                    if (raw) {
                                                                        if (/^\d{4}-\d{2}-\d{2}/.test(raw)) {
                                                                            const p = raw.split('-');
                                                                            baseDate = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]));
                                                                        } else if (/^\d{1,2}\/\d{1,2}\/\d{4}/.test(raw)) {
                                                                            const p = raw.split('/');
                                                                            baseDate = new Date(Number(p[2]), Number(p[1]) - 1, Number(p[0]));
                                                                        }
                                                                    }
                                                                    const day = baseDate.getDay();
                                                                    const diff = baseDate.getDate() - day + (day === 0 ? -6 : 1);
                                                                    const monday = new Date(baseDate.getFullYear(), baseDate.getMonth(), diff);
                                                                    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                                                                    days.forEach((key, idx) => {
                                                                        const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + idx);
                                                                        const el = document.getElementById('date-head-' + key);
                                                                        if (el) el.textContent = String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0');
                                                                    });
                                                                } catch (e) { }
                                                            })();
                                                        </script>
                                                    </thead>
                                                    <tbody>
                                                        <tr>
                                                            <td
                                                                class="bg-light text-primary fw-bold text-center align-middle">
                                                                <i class="bi bi-sun fs-5 d-block mb-1 text-warning"></i>
                                                                Sáng<br><small class="text-muted fw-normal">07:00 -
                                                                    11:30</small>
                                                            </td>
                                                            <td class="cal-cell" id="cell-mon-0800"></td>
                                                            <td class="cal-cell" id="cell-tue-0800"></td>
                                                            <td class="cal-cell" id="cell-wed-0800"></td>
                                                            <td class="cal-cell" id="cell-thu-0800"></td>
                                                            <td class="cal-cell" id="cell-fri-0800"></td>
                                                            <td class="cal-cell" id="cell-sat-0800"></td>
                                                            <td class="cal-cell" id="cell-sun-0800"></td>
                                                        </tr>
                                                        <tr>
                                                            <td
                                                                class="bg-light text-warning fw-bold text-center align-middle">
                                                                <i
                                                                    class="bi bi-sunset fs-5 d-block mb-1 text-primary"></i>
                                                                Chiều<br><small class="text-muted fw-normal">13:30 -
                                                                    17:30</small>
                                                            </td>
                                                            <td class="cal-cell" id="cell-mon-1300"></td>
                                                            <td class="cal-cell" id="cell-tue-1300"></td>
                                                            <td class="cal-cell" id="cell-wed-1300"></td>
                                                            <td class="cal-cell" id="cell-thu-1300"></td>
                                                            <td class="cal-cell" id="cell-fri-1300"></td>
                                                            <td class="cal-cell" id="cell-sat-1300"></td>
                                                            <td class="cal-cell" id="cell-sun-1300"></td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div><!-- /.tab-content -->

                                <!-- Modal Chuyển giao ca trực -->
                                <div class="modal fade" id="transferScheduleModal" tabindex="-1" aria-hidden="true">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <h5 class="modal-title">Chuyển giao ca trực</h5>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal"
                                                    aria-label="Close"></button>
                                            </div>
                                            <div class="modal-body">
                                                <div id="transferAlert" class="alert d-none" role="alert">
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">Ca đang chọn</label>
                                                    <div id="transferSelectedInfo" class="fw-semibold">
                                                    </div>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">Chọn bác sĩ nhận ca</label>
                                                    <select id="transferTargetDoctor" class="form-select"></select>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-outline-secondary"
                                                    data-bs-dismiss="modal">Hủy</button>
                                                <button type="button" id="transferConfirmBtn"
                                                    class="btn btn-primary">Xác nhận chuyển giao</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <c:if test="${not empty sessionScope.successMessage}">
                                    <div class="alert alert-success">${sessionScope.successMessage}</div>
                                    <c:remove var="successMessage" scope="session" />
                                </c:if>
                                <c:if test="${not empty sessionScope.errorMessage}">
                                    <div class="alert alert-danger">${sessionScope.errorMessage}</div>
                                    <c:remove var="errorMessage" scope="session" />
                                </c:if>

                                <div id="aiScheduleLoading"
                                    class="alert ai-schedule-loading d-none align-items-center gap-2 mb-3">
                                    <span class="spinner-grow spinner-grow-sm text-purple" aria-hidden="true"></span>
                                    <span class="fw-semibold">AI đang phân tích dữ liệu hiệu suất và tự động
                                        phân bổ ca trực...</span>
                                    <span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
                                </div>

                                <%@ include file="/WEB-INF/views/admin/scheduling/includes/schedule-modals.jsp" %>

                            </div>
                        </div>
                        </div>

                        <script
                            src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
                        <script id="activeRoomsData" type="application/json">
                                [
                                    <c:forEach var="r" items="${rooms}" varStatus="loop">
                                    {
                                        "roomId": "${r.roomId}",
                                        "roomName": "${r.roomName}",
                                        "department": "${r.department}",
                                        "status": "${r.status}"
                                    }${!loop.last ? ',' : ''}
                                    </c:forEach>
                                ]
                                </script>
                        <script>
                            window.AdminConfig = window.AdminConfig || {};
                            window.AdminConfig.contextPath = '${pageContext.request.contextPath}';
                            window.AdminConfig.csrfToken = '${sessionScope.csrfToken}';
                            window.AdminConfig.adminEndpoint = '${pageContext.request.contextPath}/admin';
                            window.AdminConfig.loginUrl = '${pageContext.request.contextPath}/login.jsp';

                            window.adminContextPath = window.AdminConfig.contextPath;
                            window.adminCsrfToken = window.AdminConfig.csrfToken;
                            window.adminEndpoint = window.AdminConfig.adminEndpoint;
                            window.adminLoginUrl = window.AdminConfig.loginUrl;

                            try {
                                const rawRoomsEl = document.getElementById('activeRoomsData');
                                window.activeRoomsList = rawRoomsEl && rawRoomsEl.textContent.trim() ? JSON.parse(rawRoomsEl.textContent) : [];
                            } catch (e) {
                                window.activeRoomsList = [];
                            }
                        </script>
                        <script>
                            document.addEventListener('DOMContentLoaded', function () {
                                function initCustomDropdown(btnId, menuId) {
                                    const btn = document.getElementById(btnId);
                                    const menu = document.getElementById(menuId);
                                    if (!btn || !menu) return;
                                    btn.addEventListener('click', function (e) {
                                        e.stopPropagation();
                                        const otherMenuId = btnId === 'aiScheduleGeminiBtn' ? 'createScheduleToolbarMenu' : 'aiScheduleGeminiMenu';
                                        const otherMenu = document.getElementById(otherMenuId);
                                        if (otherMenu) otherMenu.classList.remove('show');
                                        menu.classList.toggle('show');
                                    });
                                }
                                initCustomDropdown('aiScheduleGeminiBtn', 'aiScheduleGeminiMenu');
                                initCustomDropdown('createScheduleToolbarBtn', 'createScheduleToolbarMenu');

                                document.addEventListener('click', function () {
                                    const m1 = document.getElementById('aiScheduleGeminiMenu');
                                    const m2 = document.getElementById('createScheduleToolbarMenu');
                                    if (m1) m1.classList.remove('show');
                                    if (m2) m2.classList.remove('show');
                                });

                                const menus = ['aiScheduleGeminiMenu', 'createScheduleToolbarMenu'];
                                menus.forEach(id => {
                                    const el = document.getElementById(id);
                                    if (el) {
                                        el.addEventListener('click', function (e) {
                                            if (e.target.closest('.dropdown-item')) {
                                                el.classList.remove('show');
                                            } else {
                                                e.stopPropagation();
                                            }
                                        });
                                    }
                                });
                            });
                        </script>
                        <script charset="UTF-8"
                            src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-common.js?v=20260725-recshiftfix2"></script>
                        <script charset="UTF-8"
                            src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-wizard.js?v=20260725-recshiftfix2"></script>
                        <script charset="UTF-8"
                            src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-doctor.js?v=20260725-recshiftfix2"></script>
                        <script charset="UTF-8"
                            src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-staff.js?v=20260725-recshiftfix2"></script>
                    </body>

                    </html>