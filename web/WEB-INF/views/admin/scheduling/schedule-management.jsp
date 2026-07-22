<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <fmt:setLocale value="vi_VN" />

            <c:set var="currentAction" value="schedule" />

            <%-- Trang Quản lý lịch trực bác sĩ: - Lọc, xem tải ca trực theo bác sĩ/khoa/ngày - Tạo ca thủ công và hủy
                ca - Tích hợp modal AI lập lịch (Gemini + fallback) --%>

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
                </head>

                <body class="bg-light">
                    <div class="container py-4">
                        <div class="admin-layout row g-3">
                            <div class="col-lg-3 admin-sidebar-col">
                                <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
                            </div>
                            <div class="col-lg-9 admin-content-col">
                                <div class="admin-page-header schedule-page-header d-flex justify-content-between align-items-center mb-3">
                                    <div>
                                        <h3 class="mb-1">Quản lý lịch trực</h3>
                                    </div>
                                    <div class="d-flex gap-2">
                                        <!-- Dropdown Lập lịch thông minh -->
                                        <div class="custom-dropdown-container">
                                            <button type="button" class="btn text-white fw-bold shadow-sm" id="aiScheduleGeminiBtn" style="background: linear-gradient(135deg, #7c3aed, #6d28d9); border: 1px solid #6d28d9;">
                                                <i class="fa-solid fa-wand-magic-sparkles me-2"></i>✦ Lập lịch AI thông minh
                                            </button>
                                            <div class="custom-dropdown-menu-list shadow border-0" id="aiScheduleGeminiMenu">
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="Doctor"><i class="fa-solid fa-user-doctor me-2 text-teal"></i>Lập lịch Bác sĩ khám</a>
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="Receptionist"><i class="fa-solid fa-headset me-2 text-primary"></i>Lập lịch Lễ tân</a>
                                                <a class="dropdown-item ai-universal-trigger py-2" href="#" data-bs-toggle="modal" data-bs-target="#aiScheduleModal" data-staff-type="doctor_lab"><i class="fa-solid fa-flask-vial me-2 text-warning"></i>Lập lịch Bác sĩ xét nghiệm</a>
                                            </div>
                                        </div>
                                        <!-- Dropdown Tạo ca trực -->
                                        <div class="custom-dropdown-container">
                                            <button type="button" class="btn btn-primary fw-bold" id="createScheduleToolbarBtn">
                                                <i class="fa-solid fa-plus me-2"></i>Tạo ca trực
                                            </button>
                                            <div class="custom-dropdown-menu-list shadow border-0" id="createScheduleToolbarMenu">
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createScheduleModal"><i class="fa-solid fa-user-doctor me-2 text-teal"></i>Ca trực Bác sĩ khám</a>
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createReceptionistScheduleModal"><i class="fa-solid fa-headset me-2 text-primary"></i>Ca trực Lễ tân</a>
                                                <a class="dropdown-item py-2" href="#" data-bs-toggle="modal" data-bs-target="#createLabScheduleModal"><i class="fa-solid fa-flask-vial me-2 text-warning"></i>Ca trực Bác sĩ xét nghiệm</a>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-3">
                                    <!-- View Switcher -->
                                    <div class="btn-group p-1 bg-white border rounded-pill shadow-sm" role="group" style="height: 42px; display: inline-flex; align-items: center;">
                                        <button type="button" id="viewModeCalendarBtn" class="btn btn-sm rounded-pill px-3 py-1 fw-bold text-white" style="font-size: 0.88rem; background-color: #7c3aed; transition: all 0.2s;">
                                            <i class="fa-solid fa-calendar-week me-1"></i>📅 Lịch theo tuần
                                        </button>
                                        <button type="button" id="viewModeListBtn" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent" style="font-size: 0.88rem; transition: all 0.2s;">
                                            <i class="fa-solid fa-list-check me-1"></i>📋 Danh sách chi tiết
                                        </button>
                                    </div>
                                </div>

                                <!-- Unified Filter Bar -->
                                <div class="card border-0 shadow-sm mb-3" style="border-radius: 16px;">
                                    <div class="card-body p-3">
                                        <form id="unifiedFilterForm" method="GET" action="${pageContext.request.contextPath}/admin" class="row g-2 align-items-center">
                                            <input type="hidden" name="action" value="schedule">
                                            <input type="hidden" id="selectedViewTab" name="viewTab" value="calendar">

                                            <!-- Vai trò -->
                                            <div class="col-md-2" id="unifiedRoleFilterContainer">
                                                <label class="form-label text-secondary small fw-bold mb-1">Vai trò</label>
                                                <select id="unifiedRoleFilter" name="roleFilter" class="form-select form-select-sm" style="border-radius: 8px;">
                                                    <option value="Doctor" selected>🩺 Bác sĩ khám</option>
                                                    <option value="Receptionist">🎧 Lễ tân</option>
                                                    <option value="doctor_lab">🧪 Bác sĩ xét nghiệm</option>
                                                    <option value="all">Tất cả vai trò</option>
                                                </select>
                                            </div>

                                            <!-- Chọn tuần / Ngày -->
                                            <div class="col-md-3" id="unifiedTimeFilterContainer">
                                                <label id="filterTimeLabel" class="form-label text-secondary small fw-bold mb-1">${param.viewTab == 'list' ? 'Chọn ngày' : 'Chọn tuần'}</label>

                                                <!-- Picker Tuần -->
                                                <div id="filterWeekPickerGroup" class="input-group input-group-sm flex-nowrap ${param.viewTab == 'list' ? 'd-none' : ''}" style="flex-wrap: nowrap !important; ${param.viewTab == 'list' ? 'display: none !important;' : 'display: flex !important;'}">
                                                    <button type="button" id="unifiedPrevWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần trước" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;"><i class="fa-solid fa-chevron-left"></i></button>
                                                    <input type="date" id="unifiedWeekPicker" name="weekDate" class="form-control text-center px-1" style="font-size: 0.85rem;">
                                                    <button type="button" id="unifiedTodayBtn" class="btn btn-outline-secondary px-2 fw-semibold" style="font-size: 0.82rem; white-space: nowrap;" title="Hôm nay">Hôm nay</button>
                                                    <button type="button" id="unifiedNextWeekBtn" class="btn btn-outline-secondary px-2" title="Tuần sau" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;"><i class="fa-solid fa-chevron-right"></i></button>
                                                </div>

                                                <!-- Picker Ngày -->
                                                <input type="date" id="unifiedDatePicker" name="workDate" class="form-control form-control-sm ${param.viewTab == 'list' ? '' : 'd-none'} px-2" style="border-radius: 8px; font-size: 0.88rem; ${param.viewTab == 'list' ? 'display: block !important;' : 'display: none !important;'}">
                                            </div>

                                            <!-- Phòng / Chuyên khoa -->
                                            <div class="col-md-3" id="unifiedRoomFilterContainer">
                                                <label class="form-label text-secondary small fw-bold mb-1">Phòng / Chuyên khoa</label>
                                                <select id="unifiedRoomFilter" name="roomId" class="form-select form-select-sm" style="border-radius: 8px;">
                                                    <option value="all" selected>Tất cả phòng / khoa</option>
                                                    <c:forEach var="r" items="${rooms}">
                                                        <option value="room_${r.roomId}">${r.roomName} (${r.roomId})</option>
                                                    </c:forEach>
                                                </select>
                                            </div>

                                            <!-- Tìm kiếm -->
                                            <div class="col-md-3">
                                                <label class="form-label text-secondary small fw-bold mb-1">Tìm kiếm nhân sự</label>
                                                <div class="input-group input-group-sm">
                                                    <span class="input-group-text bg-white border-end-0" style="border-top-left-radius: 8px; border-bottom-left-radius: 8px;"><i class="fa-solid fa-magnifying-glass text-muted"></i></span>
                                                    <input type="text" id="unifiedSearchInput" name="search" class="form-control border-start-0" placeholder="Tên nhân sự..." value="${param.search}" style="border-top-right-radius: 8px; border-bottom-right-radius: 8px;">
                                                </div>
                                            </div>

                                            <!-- Nút Lọc & Reset -->
                                            <div class="col-md-1 d-flex align-items-end gap-1" style="margin-top: 24px;">
                                                <button type="submit" class="btn btn-sm text-white fw-bold w-100 py-1" style="background-color: #0d9488; border-radius: 8px;" title="Áp dụng bộ lọc">
                                                    <i class="fa-solid fa-filter"></i>
                                                </button>
                                                <button type="button" id="unifiedFilterResetBtn" class="btn btn-sm btn-outline-secondary py-1" style="border-radius: 8px;" title="Đặt lại">
                                                    <i class="fa-solid fa-rotate-left"></i>
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>

                                <div class="tab-content" id="scheduleRoleTabContent">
                                    <!-- Detailed List Pane (Danh sách chi tiết) -->
                                    <div class="schedule-role-pane" id="detailedListPane" style="display: none;">
                                        <!-- Bộ 3 Tab Role chuyên nghiệp 1-Click cho chế độ Danh sách chi tiết -->
                                        <div id="detailedListRoleSwitch" class="card border-0 shadow-sm p-2 mb-3 bg-white" style="border-radius: 12px;">
                                            <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                                                <span class="fw-bold text-dark small ms-2"><i class="fa-solid fa-users-gear me-2 text-primary"></i>Chọn vai trò nhân sự:</span>
                                                <div class="btn-group p-1 bg-light rounded-pill border" role="group">
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-bold detailed-role-tab active text-white bg-primary" data-role="Doctor" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-user-doctor me-1"></i>🩺 Bác sĩ khám
                                                    </button>
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent detailed-role-tab" data-role="Receptionist" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-headset me-1"></i>🎧 Lễ tân
                                                    </button>
                                                    <button type="button" class="btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent detailed-role-tab" data-role="doctor_lab" style="font-size: 0.86rem; transition: all 0.2s;">
                                                        <i class="fa-solid fa-flask-vial me-1"></i>🧪 Bác sĩ xét nghiệm
                                                    </button>
                                                </div>
                                            </div>
                                        </div>

                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/doctor-role-pane.jsp" %>
                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/receptionist-role-pane.jsp" %>
                                        <%@ include file="/WEB-INF/views/admin/scheduling/includes/lab-role-pane.jsp" %>
                                    </div>

                                    <!-- Weekly Calendar Pane (Lịch theo tuần) -->
                                    <div class="schedule-role-pane" id="weeklyCalendarPane">
                                        <!-- Alert Cảnh báo xung đột nếu có -->
                                        <div id="calendarConflictAlert"
                                            class="alert alert-danger d-none mb-3 py-2 px-3 align-items-center justify-content-between flex-wrap gap-2"
                                            style="border-radius: 12px;">
                                            <div class="d-flex align-items-center gap-2">
                                                <i class="bi bi-exclamation-triangle-fill fs-5 text-danger me-1"></i>
                                                <span id="calendarConflictSummaryText" class="fw-semibold">Phát hiện xung đột trùng ca hoặc trùng phòng làm việc! Thẻ bị trùng đang được khoanh viền đỏ ⚠</span>
                                            </div>
                                            <button type="button" class="btn btn-sm btn-danger fw-bold px-3 py-1" onclick="openResolveConflictModal()" style="border-radius: 8px;">
                                                <i class="fa-solid fa-wand-magic-sparkles me-1"></i>Tháo gỡ xung đột
                                            </button>
                                        </div>

                                        <!-- Weekly Grid Calendar -->
                                        <div class="card border-0 shadow-sm mb-4"
                                            style="border-radius: 16px; overflow: hidden;">
                                            <div class="table-responsive">
                                                <table class="table table-bordered align-middle text-center mb-0 calendar-table">
                                                    <thead class="table-light">
                                                        <tr id="calendarWeekHeadRow">
                                                            <th style="width: 120px;" class="bg-light align-middle">Ca / Giờ</th>
                                                            <th class="cal-head-col" data-day="1">Thứ 2<br><small class="text-muted fw-normal" id="date-head-mon">-</small></th>
                                                            <th class="cal-head-col" data-day="2">Thứ 3<br><small class="text-muted fw-normal" id="date-head-tue">-</small></th>
                                                            <th class="cal-head-col" data-day="3">Thứ 4<br><small class="text-muted fw-normal" id="date-head-wed">-</small></th>
                                                            <th class="cal-head-col" data-day="4">Thứ 5<br><small class="text-muted fw-normal" id="date-head-thu">-</small></th>
                                                            <th class="cal-head-col" data-day="5">Thứ 6<br><small class="text-muted fw-normal" id="date-head-fri">-</small></th>
                                                            <th class="cal-head-col" data-day="6">Thứ 7<br><small class="text-muted fw-normal" id="date-head-sat">-</small></th>
                                                            <th class="cal-head-col" data-day="0">Chủ nhật<br><small class="text-muted fw-normal" id="date-head-sun">-</small></th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <tr>
                                                            <td class="bg-light text-primary fw-bold text-center align-middle">
                                                                <i class="bi bi-sun fs-5 d-block mb-1 text-warning"></i>
                                                                Sáng<br><small class="text-muted fw-normal">07:00 - 11:30</small>
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
                                                            <td class="bg-light text-warning fw-bold text-center align-middle">
                                                                <i class="bi bi-sunset fs-5 d-block mb-1 text-primary"></i>
                                                                Chiều<br><small class="text-muted fw-normal">13:30 - 17:30</small>
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
                                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                            </div>
                                            <div class="modal-body">
                                                <div id="transferAlert" class="alert d-none" role="alert"></div>
                                                <div class="mb-3">
                                                    <label class="form-label">Ca đang chọn</label>
                                                    <div id="transferSelectedInfo" class="fw-semibold"></div>
                                                </div>
                                                <div class="mb-3">
                                                    <label class="form-label">Chọn bác sĩ nhận ca</label>
                                                    <select id="transferTargetDoctor" class="form-select"></select>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>
                                                <button type="button" id="transferConfirmBtn" class="btn btn-primary">Xác nhận chuyển giao</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <c:if test="${not empty sessionScope.successMessage}">
                                    <div class="alert alert-success">${sessionScope.successMessage}</div>
                                    <% session.removeAttribute("successMessage"); %>
                                </c:if>
                                <c:if test="${not empty sessionScope.errorMessage}">
                                    <div class="alert alert-danger">${sessionScope.errorMessage}</div>
                                    <% session.removeAttribute("errorMessage"); %>
                                </c:if>

                                <div id="aiScheduleLoading" class="alert ai-schedule-loading d-none align-items-center gap-2 mb-3">
                                    <span class="spinner-grow spinner-grow-sm text-purple" aria-hidden="true"></span>
                                    <span class="fw-semibold">AI đang phân tích dữ liệu hiệu suất và tự động phân bổ ca trực...</span>
                                    <span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
                                </div>

                                <%@ include file="/WEB-INF/views/admin/scheduling/includes/schedule-modals.jsp" %>

                            </div>
                        </div>
                    </div>

                        document.addEventListener('DOMContentLoaded', function () {
                            // Logic Toggle Custom Dropdowns
                            (function() {
                                function initCustomDropdown(btnId, menuId) {
                                    const btn = document.getElementById(btnId);
                                    const menu = document.getElementById(menuId);
                                    if (!btn || !menu) return;
                                    btn.addEventListener('click', function(e) {
                                        e.stopPropagation();
                                        // Ẩn dropdown kia nếu đang mở
                                        const otherMenuId = btnId === 'aiScheduleGeminiBtn' ? 'createScheduleToolbarMenu' : 'aiScheduleGeminiMenu';
                                        const otherMenu = document.getElementById(otherMenuId);
                                        if (otherMenu) otherMenu.classList.remove('show');
                                        
                                        menu.classList.toggle('show');
                                    });
                                }
                                initCustomDropdown('aiScheduleGeminiBtn', 'aiScheduleGeminiMenu');
                                initCustomDropdown('createScheduleToolbarBtn', 'createScheduleToolbarMenu');

                                document.addEventListener('click', function() {
                                    const m1 = document.getElementById('aiScheduleGeminiMenu');
                                    const m2 = document.getElementById('createScheduleToolbarMenu');
                                    if (m1) m1.classList.remove('show');
                                    if (m2) m2.classList.remove('show');
                                });

                                const menus = ['aiScheduleGeminiMenu', 'createScheduleToolbarMenu'];
                                menus.forEach(id => {
                                    const el = document.getElementById(id);
                                    if (el) {
                                        el.addEventListener('click', function(e) {
                                            if (e.target.closest('.dropdown-item')) {
                                                el.classList.remove('show');
                                            } else {
                                                e.stopPropagation();
                                            }
                                        });
                                    }
                                });
                            })();

                            var roleTabs = Array.prototype.slice.call(document.querySelectorAll('#scheduleRoleTabs [data-role-target]'));
                            var tabByHash = {
                                '#doctorRolePane': '#doctor-role-tab',
                                '#receptionistRolePane': '#receptionist-role-tab',
                                '#labRolePane': '#lab-role-tab'
                            };

            <div id="aiScheduleLoading" class="alert ai-schedule-loading d-none align-items-center gap-2 mb-3">
                <span class="spinner-grow spinner-grow-sm text-purple" aria-hidden="true"></span>
                <span class="fw-semibold">AI đang phân tích dữ liệu hiệu suất và tự động phân bổ ca trực...</span><span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
            </div>

            <div class="tab-content" id="scheduleRoleTabContent">
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/doctor-role-pane.jsp" %>
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/receptionist-role-pane.jsp" %>
                  <%@ include file="/WEB-INF/views/admin/scheduling/includes/lab-role-pane.jsp" %>
               </div>
               <%@ include file="/WEB-INF/views/admin/scheduling/includes/schedule-modals.jsp" %>
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

    document.addEventListener('DOMContentLoaded', function () {
        var roleTabs = Array.prototype.slice.call(document.querySelectorAll('#scheduleRoleTabs [data-role-target]'));
        var tabByHash = {
            '#doctorRolePane': '#doctor-role-tab',
            '#receptionistRolePane': '#receptionist-role-tab',
            '#labRolePane': '#lab-role-tab'
        };

                                if (window.history && window.history.replaceState) {
                                    window.history.replaceState(null, '', window.location.pathname + window.location.search + targetSelector);
                                }
                            }
                            function limitScheduleTablesToTenRows() {
                                document.querySelectorAll('.schedule-list-scroll').forEach(function (wrap) {
                                    wrap.style.removeProperty('max-height');
                                    wrap.style.removeProperty('height');
                                    wrap.style.removeProperty('overflow');
                                    wrap.classList.add('is-scroll-limited');
                                });
                            }

                            forceSchedulePane(resolveInitialTab());
                            limitScheduleTablesToTenRows();
                            roleTabs.forEach(function (tab) {
                                tab.addEventListener('click', function () {
                                    forceSchedulePane(tab);
                                    limitScheduleTablesToTenRows();
                                });
                            });
                            window.addEventListener('resize', limitScheduleTablesToTenRows);
                        });
                    </script>
                    <script>
                        window.activeRoomsList = [];
                        <c:forEach var="r" items="${rooms}">
                        window.activeRoomsList.push({
                            roomId: "${r.roomId}",
                            roomName: "${r.roomName}",
                            department: "${r.department}",
                            status: "${r.status}"
                        });
                        </c:forEach>
                    </script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-common.js?v=20260722-v1"></script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-staff.js?v=20260722-v1"></script>
                    <script charset="UTF-8" src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-wizard.js?v=20260722-v1"></script>
                </body>

                </html>
