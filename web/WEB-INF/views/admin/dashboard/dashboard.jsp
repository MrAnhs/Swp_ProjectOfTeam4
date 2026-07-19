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

                    <div class="mb-4">
                        <h3 class="dashboard-title mb-1">Tổng quan quản trị</h3>
                        <p class="text-secondary mb-0">Theo dõi KPI chính của hệ thống S-COMS.</p>
                            <!-- Row 1: KPI sức khỏe vận hành hôm nay -->
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
                                    <div class="kpi-value kpi-money">
                                        <fmt:formatNumber value="${sumRevenueToday}" type="number" maxFractionDigits="0" groupingUsed="true" /> đ
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-xl-3">
                            <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('completedAppointmentsToday')" style="cursor: pointer;">
                                <div class="card-body">
                                    <span class="kpi-icon icon-visits"><i class="fa-solid fa-clipboard-check"></i></span>
                                    <div class="kpi-label">Lượt khám hoàn thành</div>
                                    <div class="kpi-value">${completedAppointmentsToday}</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Row 2: KPI chi tiết trạng thái khám chữa bệnh -->
                    <div class="row g-3 mb-4">
                        <div class="col-md-6 col-xl-3">
                            <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('waiting')" style="cursor: pointer;">
                                <div class="card-body">
                                    <span class="kpi-icon icon-waiting"><i class="fa-solid fa-hourglass-half"></i></span>
                                    <div class="kpi-label">Bệnh nhân đang chờ khám</div>
                                    <div class="kpi-value">${patientsWaiting}</div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-xl-3">
                            <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('inProgress')" style="cursor: pointer;">
                                <div class="card-body">
                                    <span class="kpi-icon icon-inprogress"><i class="fa-solid fa-user-injured"></i></span>
                                    <div class="kpi-label">Bệnh nhân đang khám</div>
                                    <div class="kpi-value">${patientsInProgress}</div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-xl-3">
                            <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('doctorSchedule')" style="cursor: pointer;">
                                <div class="card-body">
                                    <span class="kpi-icon icon-doctor"><i class="fa-solid fa-user-doctor"></i></span>
                                    <div class="kpi-label">Số bác sĩ đang trực</div>
                                    <div class="kpi-value">${todayScheduleCounts.doctor}</div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-xl-3">
                            <div class="card kpi-card h-100" role="link" tabindex="0" onclick="openDashboardModal('activeRooms')" style="cursor: pointer;">
                                <div class="card-body">
                                    <span class="kpi-icon icon-hospital"><i class="fa-solid fa-hospital"></i></span>
                                    <div class="kpi-label">Phòng khám đang hoạt động</div>
                                    <div class="kpi-value">${activeRooms}</div>
                                </div>
                            </div>
                        </div>
                    </div>



                    <!-- Row 4: Lịch trực & Trạng thái lịch hẹn -->
                    <div class="row g-3 mb-4">
                        <div class="col-xl-6">
                            <div class="card dashboard-info-card h-100">
                                <div class="card-body">
                                    <div class="dashboard-info-title">Lịch trực hôm nay</div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('doctorSchedule')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon"><i class="fa-solid fa-user-doctor"></i></span>
                                            <span class="mini-stat-label">Bác sĩ khám</span>
                                        </div>
                                        <span class="mini-stat-value">${todayScheduleCounts.doctor}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('receptionistSchedule')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon"><i class="fa-solid fa-headset"></i></span>
                                            <span class="mini-stat-label">Lễ tân</span>
                                        </div>
                                        <span class="mini-stat-value">${todayScheduleCounts.receptionist}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('labSchedule')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon"><i class="fa-solid fa-flask-vial"></i></span>
                                            <span class="mini-stat-label">Bác sĩ xét nghiệm</span>
                                        </div>
                                        <span class="mini-stat-value">${todayScheduleCounts.lab}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('doctorSchedule')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon"><i class="fa-solid fa-calendar-day"></i></span>
                                            <span class="mini-stat-label">Tổng ca</span>
                                        </div>
                                        <span class="mini-stat-value">${todayScheduleCounts.total}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-xl-6">
                            <div class="card dashboard-info-card h-100">
                                <div class="card-body">
                                    <div class="dashboard-info-title">Trạng thái lịch hẹn hôm nay</div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('waiting')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon text-warning" style="background: rgba(245, 158, 11, 0.12);"><i class="fa-solid fa-hourglass-start"></i></span>
                                            <span class="mini-stat-label">Waiting (Đang chờ)</span>
                                        </div>
                                        <span class="mini-stat-value">${appointmentStatusSummary.waiting}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('todayAppointments')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon text-primary" style="background: rgba(59, 130, 246, 0.12);"><i class="fa-solid fa-calendar-check"></i></span>
                                            <span class="mini-stat-label">Confirmed (Đã xác nhận)</span>
                                        </div>
                                        <span class="mini-stat-value">${appointmentStatusSummary.confirmed}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('inProgress')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon text-info" style="background: rgba(6, 182, 212, 0.12);"><i class="fa-solid fa-spinner"></i></span>
                                            <span class="mini-stat-label">In Progress (Đang khám)</span>
                                        </div>
                                        <span class="mini-stat-value">${appointmentStatusSummary.in_progress}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('completedAppointmentsToday')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon text-success" style="background: rgba(16, 185, 129, 0.12);"><i class="fa-solid fa-check-double"></i></span>
                                            <span class="mini-stat-label">Completed (Đã hoàn thành)</span>
                                        </div>
                                        <span class="mini-stat-value">${appointmentStatusSummary.completed}</span>
                                    </div>
                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('todayAppointments')" style="cursor: pointer;">
                                        <div class="mini-stat-main">
                                            <span class="mini-stat-icon text-danger" style="background: rgba(239, 68, 68, 0.12);"><i class="fa-solid fa-ban"></i></span>
                                            <span class="mini-stat-label">Cancelled (Đã hủy)</span>
                                        </div>
                                        <span class="mini-stat-value">${appointmentStatusSummary.cancelled}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Row 5: Hàng đợi & Hoạt động gần đây -->
                    <div class="row g-3">
                        <div class="col-xl-6">
                            <div class="card dashboard-info-card h-100">
                                <div class="card-body">
                                    <div class="dashboard-info-title">Tình trạng phòng khám / Hàng đợi hôm nay</div>
                                    <c:choose>
                                        <c:when test="${not empty roomQueueSummary}">
                                            <div class="room-queue-scroll">
                                                <c:forEach var="item" items="${roomQueueSummary}">
                                                    <div class="mini-stat" role="link" tabindex="0" onclick="openDashboardModal('room', '${item.roomId}')" style="cursor: pointer;">
                                                        <div class="mini-stat-main">
                                                            <span class="mini-stat-icon"><i class="fa-solid fa-hospital-user"></i></span>
                                                            <span class="mini-stat-label">${item.roomName} (${item.roomId})</span>
                                                        </div>
                                                        <span class="mini-stat-value badge text-bg-primary rounded-pill px-3 py-2">${item.queueCount} bệnh nhân</span>
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
                                            <div class="activity-list">
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

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
        <script>
            window.AdminConfig = window.AdminConfig || {};
            window.AdminConfig.contextPath = '${pageContext.request.contextPath}';

            document.addEventListener('DOMContentLoaded', function () {
                const collapseEl = document.getElementById('collapseActivities');
                const btnToggle = document.getElementById('btnToggleActivities');
                if (collapseEl && btnToggle) {
                    collapseEl.addEventListener('shown.bs.collapse', function () {
                        btnToggle.textContent = 'Thu gọn';
                    });
                    collapseEl.addEventListener('hidden.bs.collapse', function () {
                        btnToggle.textContent = 'Xem tất cả...';
                    });
                }
            });
        </script>

        <!-- Unified Dashboard Details Modal -->
        <div class="modal fade" id="dashboardDetailModal" tabindex="-1" aria-labelledby="dashboardDetailModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content shadow-lg border-0" style="border-radius: 16px;">
                    <div class="modal-header border-bottom-0 pb-0 pt-4 px-4 d-flex justify-content-between align-items-center">
                        <h5 class="modal-title fw-bold text-dark" id="dashboardDetailModalLabel">Chi tiết thông tin</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body px-4 py-3" style="max-height: 400px; overflow-y: auto;">
                        <div id="modalLoadingSpinner" class="text-center py-5">
                            <div class="spinner-border text-teal" role="status" style="color: #0f766e;">
                                <span class="visually-hidden">Đang tải...</span>
                            </div>
                            <p class="text-muted mt-2 mb-0">Đang tải dữ liệu...</p>
                        </div>
                        <div id="modalContentContainer"></div>
                    </div>
                    <div class="modal-footer border-top-0 pt-0 pb-4 px-4 justify-content-between">
                        <a id="btnModalDetailsLink" href="#" class="btn text-white fw-bold px-4 py-2" style="border-radius: 8px; background-color: #0f766e;">Xem chi tiết</a>
                        <button type="button" class="btn btn-outline-secondary fw-semibold px-4 py-2" data-bs-dismiss="modal" style="border-radius: 8px;">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <script>
            function openDashboardModal(type, id) {
                const modalEl = document.getElementById('dashboardDetailModal');
                const modal = new bootstrap.Modal(modalEl);
                
                const titleEl = document.getElementById('dashboardDetailModalLabel');
                const loadingEl = document.getElementById('modalLoadingSpinner');
                const contentEl = document.getElementById('modalContentContainer');
                const linkEl = document.getElementById('btnModalDetailsLink');
                
                titleEl.textContent = "Chi tiết thông tin";
                loadingEl.style.display = 'block';
                contentEl.innerHTML = '';
                linkEl.style.display = 'none';
                
                modal.show();
                
                const url = window.AdminConfig.contextPath + '/admin?action=dashboardModalData&type=' + type + (id ? '&id=' + encodeURIComponent(id) : '');
                
                fetch(url)
                    .then(response => {
                        if (!response.ok) throw new Error('Network response was not ok');
                        return response.json();
                    })
                    .then(data => {
                        loadingEl.style.display = 'none';
                        renderModalContent(type, id, data, titleEl, contentEl, linkEl);
                    })
                    .catch(err => {
                        console.error('Error loading modal data:', err);
                        loadingEl.style.display = 'none';
                        contentEl.innerHTML = '<div class="alert alert-danger mb-0">' +
                            '<i class="fa-solid fa-circle-xmark me-2"></i>Không thể tải dữ liệu chi tiết. Vui lòng thử lại sau.' +
                            '</div>';
                    });
            }

            function renderModalContent(type, id, data, titleEl, contentEl, linkEl) {
                let html = '';
                let linkUrl = '';
                
                const formatVND = (val) => {
                    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
                };

                const formatTime = (ts) => {
                    if (!ts) return 'Chưa có';
                    const date = new Date(ts);
                    return date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + date.toLocaleDateString('vi-VN');
                };

                const getStatusBadge = (status) => {
                    const st = String(status).toLowerCase();
                    if (st === 'waiting') return '<span class="badge bg-warning text-dark px-2 py-1">Waiting</span>';
                    if (st === 'confirmed') return '<span class="badge bg-primary px-2 py-1">Confirmed</span>';
                    if (st === 'in progress') return '<span class="badge bg-info px-2 py-1">In Progress</span>';
                    if (st === 'completed') return '<span class="badge bg-success px-2 py-1">Completed</span>';
                    if (st === 'cancelled') return '<span class="badge bg-danger px-2 py-1">Cancelled</span>';
                    return '<span class="badge bg-secondary px-2 py-1">' + status + '</span>';
                };

                const items = data.items || [];

                if (type === 'todayPatients') {
                    titleEl.textContent = 'Danh sách bệnh nhân khám hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=listUsers&role=Patient';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Không có bệnh nhân nào trong hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.fullName + '</td>' +
                                '<td>' + item.email + '</td>' +
                                '<td><span class="badge text-bg-light">' + item.appointmentId + '</span></td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Họ tên</th>' +
                            '<th>Email</th>' +
                            '<th>Mã ca khám</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'todayAppointments') {
                    titleEl.textContent = 'Danh sách lịch hẹn hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=schedule';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Không có lịch hẹn nào trong hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.patientName + '</td>' +
                                '<td>' + item.doctorName + '</td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '<td>' + getStatusBadge(item.status) + '</td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Bệnh nhân</th>' +
                            '<th>Bác sĩ khám</th>' +
                            '<th>Khung giờ</th>' +
                            '<th>Trạng thái</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'sumRevenueToday') {
                    titleEl.textContent = 'Chi tiết doanh thu hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=reports&granularity=day';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Chưa ghi nhận doanh thu nào trong hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item) => {
                            rowsHtml += '<tr>' +
                                '<td class="fw-semibold text-teal">' + item.invoiceId + '</td>' +
                                '<td>' + item.patientName + '</td>' +
                                '<td class="fw-bold text-success">' + formatVND(item.finalAmount) + '</td>' +
                                '<td>' + formatTime(item.createdAt) + '</td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>Mã HĐ</th>' +
                            '<th>Bệnh nhân</th>' +
                            '<th>Số tiền đã trả</th>' +
                            '<th>Thời gian thanh toán</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'completedAppointmentsToday') {
                    titleEl.textContent = 'Danh sách ca khám hoàn thành hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=reports&granularity=day';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Chưa có ca khám nào hoàn thành hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.patientName + '</td>' +
                                '<td>' + item.doctorName + '</td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Bệnh nhân</th>' +
                            '<th>Bác sĩ khám</th>' +
                            '<th>Khung giờ</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'waiting' || type === 'inProgress') {
                    const label = type === 'waiting' ? 'chờ khám' : 'đang khám';
                    titleEl.textContent = 'Danh sách bệnh nhân ' + label + ' hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=schedule';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Không có bệnh nhân nào ' + label + ' hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.patientName + '</td>' +
                                '<td>' + item.doctorName + '</td>' +
                                '<td><span class="badge bg-secondary-subtle text-secondary">' + (item.roomName || 'Chưa xếp') + '</span></td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Bệnh nhân</th>' +
                            '<th>Bác sĩ khám</th>' +
                            '<th>Phòng</th>' +
                            '<th>Khung giờ</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'doctorSchedule') {
                    titleEl.textContent = 'Danh sách bác sĩ trực hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=schedule';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Hôm nay không có ca trực bác sĩ nào.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.doctorName + '</td>' +
                                '<td><span class="badge bg-teal-subtle text-teal">' + (item.roomName || 'Chưa xếp') + '</span></td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '<td>' +
                                '<span class="badge ' + (item.status === 'Available' ? 'text-bg-success' : 'text-bg-danger') + '">' +
                                (item.status === 'Available' ? 'Khả dụng' : item.status) +
                                '</span>' +
                                '</td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Bác sĩ</th>' +
                            '<th>Phòng khám</th>' +
                            '<th>Khung giờ</th>' +
                            '<th>Trạng thái ca</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'activeRooms') {
                    titleEl.textContent = 'Danh sách phòng khám đang hoạt động';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=manageRooms';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Không có phòng khám nào đang hoạt động.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item) => {
                            rowsHtml += '<tr>' +
                                '<td class="fw-bold text-teal">' + item.roomId + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.roomName + '</td>' +
                                '<td>' + (item.location || 'Chưa rõ') + '</td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>Mã phòng</th>' +
                            '<th>Tên phòng</th>' +
                            '<th>Vị trí</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'receptionistSchedule' || type === 'labSchedule') {
                    const label = type === 'receptionistSchedule' ? 'lễ tân' : 'bác sĩ xét nghiệm';
                    titleEl.textContent = 'Danh sách lịch trực ' + label + ' hôm nay';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=schedule';
                    if (items.length === 0) {
                        html = '<p class="text-center text-muted py-4 mb-0">Không có lịch trực ' + label + ' hôm nay.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.staffName + '</td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '<td><span class="badge bg-secondary-subtle text-secondary">' + (item.roomName || 'Chưa xếp') + '</span></td>' +
                                '</tr>';
                        });
                        html = '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Nhân sự</th>' +
                            '<th>Khung giờ</th>' +
                            '<th>Vị trí phòng</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'room') {
                    titleEl.textContent = 'Chi tiết phòng khám: ' + (data.roomName || '') + ' (' + (data.roomId || id) + ')';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=manageRooms&search=' + encodeURIComponent(data.roomId || id);
                    html = '<div class="card bg-light border-0 mb-3" style="border-radius: 12px;">' +
                        '<div class="card-body py-3">' +
                        '<div class="row g-2">' +
                        '<div class="col-sm-6">' +
                        '<div class="text-muted small">Vị trí</div>' +
                        '<div class="fw-semibold text-dark">' + (data.location || 'Chưa thiết lập') + '</div>' +
                        '</div>' +
                        '<div class="col-sm-6">' +
                        '<div class="text-muted small">Bác sĩ trực hôm nay</div>' +
                        '<div class="fw-semibold text-teal">' + (data.doctorName || 'Chưa có bác sĩ') + '</div>' +
                        '</div>' +
                        '</div>' +
                        '</div>' +
                        '</div>' +
                        '<h6 class="fw-bold text-dark mb-2 mt-4"><i class="fa-solid fa-list-ol me-2"></i>Bệnh nhân trong hàng đợi hôm nay</h6>';
                    
                    if (items.length === 0) {
                        html += '<p class="text-center text-muted py-4 mb-0">Không có bệnh nhân nào đang chờ hoặc khám tại phòng này.</p>';
                    } else {
                        let rowsHtml = '';
                        items.forEach((item, idx) => {
                            rowsHtml += '<tr>' +
                                '<td>' + (idx + 1) + '</td>' +
                                '<td class="fw-semibold text-dark">' + item.patientName + '</td>' +
                                '<td><span class="badge text-bg-light"><i class="fa-regular fa-clock me-1"></i>' + item.timeSlot + '</span></td>' +
                                '<td>' + getStatusBadge(item.status) + '</td>' +
                                '</tr>';
                        });
                        html += '<div class="table-responsive">' +
                            '<table class="table table-hover align-middle mb-0">' +
                            '<thead class="table-light">' +
                            '<tr>' +
                            '<th>STT</th>' +
                            '<th>Bệnh nhân</th>' +
                            '<th>Khung giờ hẹn</th>' +
                            '<th>Trạng thái</th>' +
                            '</tr>' +
                            '</thead>' +
                            '<tbody>' +
                            rowsHtml +
                            '</tbody>' +
                            '</table>' +
                            '</div>';
                    }
                } else if (type === 'activity') {
                    titleEl.textContent = 'Chi tiết hoạt động gần đây';
                    linkUrl = window.AdminConfig.contextPath + '/admin?action=schedule';
                    if (data.activityTitle) {
                        html = '<div class="py-3">' +
                            '<h5 class="fw-bold text-dark mb-3">' + data.activityTitle + '</h5>' +
                            '<div class="text-muted mb-4" style="font-size: 1rem; line-height: 1.6;">' + data.activityDetail + '</div>' +
                            '<div class="d-flex align-items-center gap-2 text-secondary small">' +
                            '<i class="fa-regular fa-clock"></i>' +
                            '<span>Thời gian thực hiện: <b>' + formatTime(data.activityTime) + '</b></span>' +
                            '</div>' +
                            '</div>';
                    } else {
                        html = '<p class="text-center text-muted py-4 mb-0">Không tìm thấy chi tiết của hoạt động này.</p>';
                    }
                }

                contentEl.innerHTML = html;
                linkEl.href = linkUrl;
                linkEl.style.display = 'block';
            }
        </script>
    </body>
</html>



