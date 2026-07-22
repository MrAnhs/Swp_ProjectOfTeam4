<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:setLocale value="vi_VN" />
<jsp:useBean id="now" class="java.util.Date" />
<fmt:formatDate value="${now}" pattern="yyyy-MM-dd" var="todayDateStr" />
<c:set var="currentAction" value="${empty param.action ? 'dashboard' : param.action}" />
<c:if test="${empty totalAccounts}">
    <c:redirect url="/admin" />
</c:if>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tổng quan quản trị - S-COMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/admin/dashboard.css" rel="stylesheet">
    <script>
        window.AdminConfig = {
            contextPath: '${pageContext.request.contextPath}',
            csrfToken: '${sessionScope.csrfToken}'
        };
    </script>
</head>
<body class="bg-light">
    <div class="container py-4">
        <div class="admin-layout row g-3">
            <div class="col-lg-3 admin-sidebar-col">
                <%@ include file="/WEB-INF/views/components/admin/sidebar.jspf" %>
            </div>

            <div class="col-lg-9 admin-content-col">
                <c:if test="${not empty sessionScope.successMessage}">
                    <div class="alert alert-success">${sessionScope.successMessage}</div>
                    <% session.removeAttribute("successMessage"); %>
                </c:if>
                <c:if test="${not empty sessionScope.errorMessage}">
                    <div class="alert alert-danger">${sessionScope.errorMessage}</div>
                    <% session.removeAttribute("errorMessage"); %>
                </c:if>

                <!-- Header & Quick Actions -->
                <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
                    <div>
                        <h3 class="dashboard-title mb-1">Tổng quan quản trị</h3>
                        <p class="text-secondary mb-0">Theo dõi KPI chính và hiệu suất vận hành hệ thống S-COMS.</p>
                    </div>
                    <div class="d-flex gap-2 flex-wrap">
                        <button type="button" class="btn text-white fw-bold shadow-sm px-3" onclick="openDashboardModal('doctorSchedule')" style="background: linear-gradient(135deg, #7c3aed, #6d28d9); border: 1px solid #6d28d9; border-radius: 10px;">
                            <i class="fa-solid fa-calendar-plus me-1"></i> Xếp lịch trực
                        </button>
                        <button type="button" class="btn btn-outline-primary fw-bold shadow-sm px-3" data-bs-toggle="modal" data-bs-target="#quickCreateAccountModal" style="border-radius: 10px;">
                            <i class="fa-solid fa-user-plus me-1"></i> Thêm tài khoản
                        </button>
                        <a href="${pageContext.request.contextPath}/admin?action=room" class="btn btn-outline-secondary fw-bold shadow-sm px-3" style="border-radius: 10px;">
                            <i class="fa-solid fa-hospital-user me-1"></i> Quản lý phòng
                        </a>
                    </div>
                </div>

                <!-- Row 1: KPI Cốt lõi trên 1 hàng duy nhất (4 thẻ) -->
                <div class="row g-3 mb-4">
                    <div class="col-md-6 col-xl-3">
                        <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('todayPatients')" style="cursor: pointer;">
                            <div class="card-body">
                                <span class="kpi-icon icon-accounts"><i class="fa-solid fa-users"></i></span>
                                <div class="kpi-label">Tổng bệnh nhân hôm nay</div>
                                <div class="kpi-value">${todayPatientsCount}</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 col-xl-3">
                        <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('todayAppointments')" style="cursor: pointer;">
                            <div class="card-body">
                                <span class="kpi-icon icon-services"><i class="fa-solid fa-calendar-check"></i></span>
                                <div class="kpi-label">Tổng lịch hẹn hôm nay</div>
                                <div class="kpi-value">${todayAppointmentsCount}</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 col-xl-3">
                        <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('sumRevenueToday')" style="cursor: pointer;">
                            <div class="card-body">
                                <span class="kpi-icon icon-revenue"><i class="fa-solid fa-wallet"></i></span>
                                <div class="kpi-label">Doanh thu hôm nay</div>
                                <div class="kpi-value kpi-money" title="<fmt:formatNumber value='${sumRevenueToday}' pattern='#,##0' /> VNĐ">
                                    <fmt:formatNumber value="${sumRevenueToday}" pattern="#,##0" /> VNĐ
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 col-xl-3">
                        <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('doctorSchedule')" style="cursor: pointer;">
                            <div class="card-body">
                                <span class="kpi-icon icon-doctor"><i class="fa-solid fa-user-doctor"></i></span>
                                <div class="kpi-label">Bác sĩ đang trực</div>
                                <div class="kpi-value">${todayScheduleCounts.doctor} <span class="fs-6 text-muted font-normal">/ ${activeRooms} phòng</span></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Lịch trực & Trạng thái lịch hẹn -->
                <div class="row g-3 mb-4">
                    <!-- Card Lịch trực hôm nay với Progress Bar -->
                    <div class="col-xl-6">
                        <div class="card dashboard-info-card h-100">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <div class="dashboard-info-title mb-0">Lịch trực hôm nay</div>
                                    <span class="badge bg-purple-subtle text-purple fw-bold px-3 py-2" style="border-radius: 8px;">Tổng: ${todayScheduleCounts.total} ca</span>
                                </div>
                                
                                <c:set var="doctorPercent" value="${todayScheduleCounts.total > 0 ? (todayScheduleCounts.doctor * 100 / todayScheduleCounts.total) : 0}" />
                                <c:set var="receptionistPercent" value="${todayScheduleCounts.total > 0 ? (todayScheduleCounts.receptionist * 100 / todayScheduleCounts.total) : 0}" />
                                <c:set var="labPercent" value="${todayScheduleCounts.total > 0 ? (todayScheduleCounts.lab * 100 / todayScheduleCounts.total) : 0}" />

                                <div class="mini-stat py-2" role="link" tabindex="0" onclick="openDashboardModal('doctorSchedule')" style="cursor: pointer;">
                                    <div class="mini-stat-main w-100">
                                        <span class="mini-stat-icon"><i class="fa-solid fa-user-doctor"></i></span>
                                        <div class="flex-fill min-w-0">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span class="mini-stat-label">Bác sĩ khám</span>
                                                <span class="fw-bold text-dark">${todayScheduleCounts.doctor} ca</span>
                                            </div>
                                            <div class="progress" style="height: 6px; border-radius: 4px;">
                                                <div class="progress-bar bg-teal" role="progressbar" data-percent="${doctorPercent}"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="mini-stat py-2" role="link" tabindex="0" onclick="openDashboardModal('receptionistSchedule')" style="cursor: pointer;">
                                    <div class="mini-stat-main w-100">
                                        <span class="mini-stat-icon" style="background: rgba(59, 130, 246, 0.12); color: #2563eb;"><i class="fa-solid fa-headset"></i></span>
                                        <div class="flex-fill min-w-0">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span class="mini-stat-label">Lễ tân</span>
                                                <span class="fw-bold text-dark">${todayScheduleCounts.receptionist} ca</span>
                                            </div>
                                            <div class="progress" style="height: 6px; border-radius: 4px;">
                                                <div class="progress-bar bg-primary" role="progressbar" data-percent="${receptionistPercent}"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="mini-stat py-2" role="link" tabindex="0" onclick="openDashboardModal('labSchedule')" style="cursor: pointer;">
                                    <div class="mini-stat-main w-100">
                                        <span class="mini-stat-icon" style="background: rgba(245, 158, 11, 0.12); color: #d97706;"><i class="fa-solid fa-flask-vial"></i></span>
                                        <div class="flex-fill min-w-0">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span class="mini-stat-label">Bác sĩ xét nghiệm</span>
                                                <span class="fw-bold text-dark">${todayScheduleCounts.lab} ca</span>
                                            </div>
                                            <div class="progress" style="height: 6px; border-radius: 4px;">
                                                <div class="progress-bar bg-warning" role="progressbar" data-percent="${labPercent}"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Card Trạng thái lịch hẹn hôm nay với Biểu đồ Donut mini & Statistics -->
                    <div class="col-xl-6">
                        <div class="card dashboard-info-card h-100">
                            <div class="card-body">
                                <div class="dashboard-info-title mb-2">Trạng thái lịch hẹn hôm nay</div>
                                <div class="row align-items-center g-2 flex-fill">
                                    <div class="col-sm-5 text-center position-relative d-flex justify-content-center align-items-center">
                                        <canvas id="appointmentStatusDonutChart" style="max-width: 145px; max-height: 145px;"></canvas>
                                    </div>
                                    <div class="col-sm-7">
                                        <div class="d-flex flex-column gap-1">
                                            <div class="d-flex justify-content-between align-items-center py-1 border-bottom fs-7" onclick="openDashboardModal('waiting')" style="cursor: pointer;">
                                                <span><i class="fa-solid fa-circle text-warning fs-8 me-2"></i>Waiting (Đang chờ)</span>
                                                <span class="fw-bold">${appointmentStatusSummary.waiting}</span>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-center py-1 border-bottom fs-7" onclick="openDashboardModal('todayAppointments')" style="cursor: pointer;">
                                                <span><i class="fa-solid fa-circle text-primary fs-8 me-2"></i>Confirmed (Đã xác nhận)</span>
                                                <span class="fw-bold">${appointmentStatusSummary.confirmed}</span>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-center py-1 border-bottom fs-7" onclick="openDashboardModal('inProgress')" style="cursor: pointer;">
                                                <span><i class="fa-solid fa-circle text-info fs-8 me-2"></i>In Progress (Đang khám)</span>
                                                <span class="fw-bold">${appointmentStatusSummary.in_progress}</span>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-center py-1 border-bottom fs-7" onclick="openDashboardModal('completedAppointmentsToday')" style="cursor: pointer;">
                                                <span><i class="fa-solid fa-circle text-success fs-8 me-2"></i>Completed (Đã xong)</span>
                                                <span class="fw-bold">${appointmentStatusSummary.completed}</span>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-center py-1 fs-7" onclick="openDashboardModal('todayAppointments')" style="cursor: pointer;">
                                                <span><i class="fa-solid fa-circle text-danger fs-8 me-2"></i>Cancelled (Đã hủy)</span>
                                                <span class="fw-bold">${appointmentStatusSummary.cancelled}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 3: Hàng đợi & Hoạt động gần đây -->
                <div class="row g-3">
                    <div class="col-xl-6">
                        <div class="card dashboard-info-card h-100">
                            <div class="card-body">
                                <div class="dashboard-info-title">Tình trạng phòng khám / Hàng đợi hôm nay</div>
                                <c:choose>
                                    <c:when test="${not empty roomQueueSummary}">
                                        <div class="room-queue-scroll">
                                            <c:forEach var="item" items="${roomQueueSummary}">
                                                <c:set var="formattedRoomName" value="${fn:replace(item.roomName, 'KhámTổng', 'Khám Tổng')}" />
                                                <div class="mini-stat py-2 room-stat-item" role="link" tabindex="0"
                                                     onclick="openDashboardModal('room', '${item.roomId}', this)"
                                                     data-room-id="${item.roomId}"
                                                     data-room-name="${formattedRoomName}"
                                                     data-staff-name="${not empty item.staffName ? item.staffName : 'Chưa phân bổ'}"
                                                     data-time-slot="${not empty item.timeSlot ? item.timeSlot : 'Chưa xếp ca'}"
                                                     data-queue-count="${item.queueCount}"
                                                     style="cursor: pointer;">
                                                    <div class="mini-stat-main">
                                                        <span class="mini-stat-icon"><i class="fa-solid fa-hospital-user"></i></span>
                                                        <div class="flex-fill min-w-0">
                                                            <div class="mini-stat-label fw-bold text-dark mb-0">${formattedRoomName} (${item.roomId})</div>
                                                            <div class="small text-muted d-flex align-items-center flex-wrap gap-1 mt-1" style="font-size: 0.78rem;">
                                                                <span class="text-purple fw-medium">
                                                                    <i class="fa-solid fa-user-doctor me-1"></i>Trực: <strong class="text-primary">${not empty item.staffName ? item.staffName : 'Chưa phân bổ'}</strong>
                                                                </span>
                                                                <c:if test="${not empty item.timeSlot}">
                                                                    <span class="badge bg-purple-subtle text-purple border ms-1 fw-semibold" style="font-size: 0.7rem;">${item.timeSlot}</span>
                                                                </c:if>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <span class="mini-stat-value badge rounded-pill px-3 py-2 ${item.queueCount > 0 ? (item.queueCount >= 5 ? 'text-bg-warning text-dark' : 'text-bg-primary') : 'bg-light text-muted border'}">${item.queueCount} bệnh nhân</span>
                                                </div>
                                            </c:forEach>
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="dashboard-empty">Không có phòng khám nào hoạt động hoặc có bệnh nhân</div>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>
                    <div class="col-xl-6">
                        <div class="card dashboard-info-card h-100">
                            <div class="card-body">
                                <div class="dashboard-info-title">Hoạt động gần đây</div>
                                <c:choose>
                                    <c:when test="${not empty recentAdminActivities}">
                                        <div class="activity-list activity-list-scroll">
                                            <c:forEach var="activity" items="${recentAdminActivities}" varStatus="status">
                                                <c:if test="${status.index < 5}">
                                                    <div class="activity-item" role="link" tabindex="0" onclick="openDashboardModal('activity', '${activity.time != null ? activity.time.time : activity.detail}')" style="cursor: pointer;">
                                                        <span class="activity-icon"><i class="fa-solid ${activity.icon}"></i></span>
                                                        <div class="min-w-0">
                                                            <div class="activity-title">${activity.title}</div>
                                                            <div class="activity-detail">${activity.detail}</div>
                                                            <div class="activity-time">
                                                                <c:choose>
                                                                    <c:when test="${not empty activity.time}">
                                                                        <fmt:formatDate value="${activity.time}" pattern="dd/MM/yyyy HH:mm" />
                                                                    </c:when>
                                                                    <c:otherwise>Chưa có thời gian</c:otherwise>
                                                                </c:choose>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </c:if>
                                            </c:forEach>
                                            
                                            <c:if test="${fn:length(recentAdminActivities) > 5}">
                                                <div class="collapse" id="collapseActivities">
                                                    <c:forEach var="activity" items="${recentAdminActivities}" varStatus="status">
                                                        <c:if test="${status.index >= 5}">
                                                            <div class="activity-item mt-2" role="link" tabindex="0" onclick="openDashboardModal('activity', '${activity.time != null ? activity.time.time : activity.detail}')" style="cursor: pointer;">
                                                                <span class="activity-icon"><i class="fa-solid ${activity.icon}"></i></span>
                                                                <div class="min-w-0">
                                                                    <div class="activity-title">${activity.title}</div>
                                                                    <div class="activity-detail">${activity.detail}</div>
                                                                    <div class="activity-time">
                                                                        <c:choose>
                                                                            <c:when test="${not empty activity.time}">
                                                                                <fmt:formatDate value="${activity.time}" pattern="dd/MM/yyyy HH:mm" />
                                                                            </c:when>
                                                                            <c:otherwise>Chưa có thời gian</c:otherwise>
                                                                        </c:choose>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </c:if>
                                                    </c:forEach>
                                                </div>
                                                <div class="text-center mt-3">
                                                    <a class="btn btn-link btn-sm text-decoration-none fw-bold" data-bs-toggle="collapse" href="#collapseActivities" role="button" aria-expanded="false" aria-controls="collapseActivities" id="btnToggleActivities">
                                                        Xem tất cả...
                                                    </a>
                                                </div>
                                            </c:if>
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="dashboard-empty">Chưa có hoạt động nào gần đây</div>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <!-- Modals cho Dashboard -->
    <div class="modal fade" id="dashboardQuickModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content border-0 shadow">
                <div class="modal-header">
                    <h5 class="modal-title fw-bold" id="dashboardQuickModalTitle">Chi tiết chỉ số</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" id="dashboardQuickModalContent"></div>
                <div class="modal-footer border-0 justify-content-end">
                    <button type="button" class="btn btn-secondary px-4" data-bs-dismiss="modal" style="border-radius: 8px;">Đóng</button>
                    <a href="#" id="dashboardQuickModalActionLink" style="display: none!important;"></a>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Schedule Modal -->
    <div class="modal fade" id="quickScheduleModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                <div class="modal-header border-0 pb-0 px-4 pt-4">
                    <div>
                        <h5 class="modal-title fw-bold text-dark mb-0" id="quickScheduleModalTitle">
                            <i class="fa-solid fa-calendar-day text-purple me-2"></i>Lịch trực hôm nay
                        </h5>
                        <p class="text-muted small mb-0 mt-1" id="quickScheduleModalSubtitle">Danh sách nhân sự đang trực</p>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body px-4 py-3">
                    <div id="quickScheduleModalLoading" class="text-center py-4">
                        <div class="spinner-border text-purple" role="status"></div>
                        <p class="text-muted mt-2 mb-0">Đang tải dữ liệu...</p>
                    </div>
                    <div id="quickScheduleModalEmpty" class="text-center py-4 d-none">
                        <i class="fa-solid fa-calendar-xmark fs-1 text-muted mb-2 d-block"></i>
                        <p class="text-muted mb-0">Không có lịch trực nào hôm nay.</p>
                    </div>
                    <div id="quickScheduleModalList" class="d-none">
                        <div class="table-responsive" style="max-height: 380px; overflow-y: auto;">
                            <table class="table table-hover align-middle mb-0" style="font-size: 0.88rem;">
                                <thead class="table-light sticky-top">
                                    <tr>
                                        <th>Nhân sự</th><th>Chuyên khoa</th><th>Khung giờ</th><th>Phòng</th><th>Trạng thái</th>
                                    </tr>
                                </thead>
                                <tbody id="quickScheduleModalTbody"></tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 px-4 pb-4 pt-2 justify-content-end">
                    <a id="quickScheduleModalFullLink" style="display: none!important;"></a>
                    <button type="button" class="btn btn-secondary px-4" data-bs-dismiss="modal" style="border-radius:10px;">Đóng</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Create Account Modal -->
    <div class="modal fade" id="quickCreateAccountModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-bold text-dark"><i class="fa-solid fa-user-plus text-primary me-2"></i>Thêm tài khoản nhân sự nhanh</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form method="POST" action="${pageContext.request.contextPath}/admin">
                    <input type="hidden" name="action" value="createAccount">
                    <div class="modal-body py-3">
                        <div class="mb-3">
                            <label class="form-label text-secondary small fw-bold">Họ và tên</label>
                            <input type="text" name="fullName" class="form-control" placeholder="Ví dụ: Nguyễn Văn A" required style="border-radius: 8px;">
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-secondary small fw-bold">Email đăng nhập</label>
                            <input type="email" name="email" class="form-control" placeholder="example@hospital.com" required style="border-radius: 8px;">
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-secondary small fw-bold">Mật khẩu khởi tạo</label>
                            <input type="password" name="password" class="form-control" placeholder="Tối thiểu 6 ký tự" required style="border-radius: 8px;">
                        </div>
                        <div class="mb-3">
                            <label class="form-label text-secondary small fw-bold">Vai trò hệ thống</label>
                            <select name="role" class="form-select" required style="border-radius: 8px;">
                                <option value="Doctor">🩺 Bác sĩ khám</option>
                                <option value="Receptionist">🎧 Lễ tân</option>
                                <option value="doctor_lab">🧪 Bác sĩ xét nghiệm</option>
                                <option value="Admin">🔑 Quản trị viên</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer border-0 pt-0">
                        <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal" style="border-radius: 8px;">Hủy</button>
                        <button type="submit" class="btn btn-primary px-4 fw-bold" style="border-radius: 8px;">Lưu & Tạo tài khoản</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <script src="${pageContext.request.contextPath}/assets/js/pages/admin/dashboard.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.progress-bar[data-percent]').forEach(function(bar) {
                const pct = Number(bar.getAttribute('data-percent')) || 0;
                bar.style.width = pct + '%';
            });

            const canvas = document.getElementById('appointmentStatusDonutChart');
            if (canvas) {
                const ctx = canvas.getContext('2d');
                const dataWaiting = Number('${appointmentStatusSummary.waiting}') || 0;
                const dataConfirmed = Number('${appointmentStatusSummary.confirmed}') || 0;
                const dataInProgress = Number('${appointmentStatusSummary.in_progress}') || 0;
                const dataCompleted = Number('${appointmentStatusSummary.completed}') || 0;
                const dataCancelled = Number('${appointmentStatusSummary.cancelled}') || 0;

                const total = dataWaiting + dataConfirmed + dataInProgress + dataCompleted + dataCancelled;

                new Chart(ctx, {
                    type: 'doughnut',
                    data: {
                        labels: ['Waiting (Đang chờ)', 'Confirmed (Đã xác nhận)', 'In Progress (Đang khám)', 'Completed (Hoàn thành)', 'Cancelled (Đã hủy)'],
                        datasets: [{
                            data: total > 0 ? [dataWaiting, dataConfirmed, dataInProgress, dataCompleted, dataCancelled] : [1],
                            backgroundColor: total > 0 
                                ? ['#f59e0b', '#3b82f6', '#06b6d4', '#10b981', '#ef4444'] 
                                : ['#e2e8f0'],
                            borderWidth: 2,
                            borderColor: '#ffffff',
                            hoverOffset: 4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        cutout: '68%',
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                enabled: total > 0,
                                callbacks: {
                                    label: function(context) {
                                        return ' ' + context.label + ': ' + context.raw + ' ca';
                                    }
                                }
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>
