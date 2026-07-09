<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:setLocale value="vi_VN" />
<c:set var="currentAction" value="${empty param.action ? 'dashboard' : param.action}" />
<%
    if (request.getAttribute("totalAccounts") == null) {
        response.sendRedirect(request.getContextPath() + "/admin");
        return;
    }
%>

<%--
    Trang Dashboard Admin:
    - Hiển thị KPI vận hành trong ngày
    - Theo dõi hàng đợi bác sĩ, ca trực hôm nay, biểu đồ tổng quan
    - Cung cấp quick modal để thao tác nhanh bằng AJAX
--%>

<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Bảng điều hành quản trị - S-COMS</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

        <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
        <style>
            .queue-monitor-card {
                border: 0;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
                overflow: hidden;
            }

            .queue-row {
                transition: background-color 0.2s ease, transform 0.2s ease;
            }

            .queue-row:hover {
                background-color: #f1f3f5;
                cursor: pointer;
            }

            .queue-load-badge,
            .queue-summary-badge {
                border-radius: 20px;
                font-weight: 600;
                padding: 0.45rem 0.8rem;
                letter-spacing: 0.01em;
            }

            .animate-pulse {
                animation: pulse-alert 1.4s ease-in-out infinite;
            }

            @keyframes pulse-alert {
                0% {
                    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.45);
                }
                70% {
                    box-shadow: 0 0 0 10px rgba(220, 53, 69, 0);
                }
                100% {
                    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0);
                }
            }

            .reserve-doctor-item {
                border: 1px solid #e9ecef;
                border-radius: 10px;
                padding: 0.85rem 1rem;
                margin-bottom: 0.75rem;
                transition: border-color 0.2s ease, background-color 0.2s ease;
            }

            .reserve-doctor-item:hover {
                border-color: #86b7fe;
                background-color: #f8fbff;
            }

            .kpi-card {
                border: 0;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
                opacity: 1;
                transform: none;
                transition: box-shadow 0.25s ease;
            }

            .kpi-card.is-visible {
                opacity: 1;
                transform: none;
            }

            .kpi-card:hover {
                box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
            }

            .dashboard-clickable-card {
                cursor: pointer;
            }

            .kpi-value {
                font-variant-numeric: tabular-nums;
                letter-spacing: 0.01em;
            }

            .quick-modal-table td,
            .quick-modal-table th {
                vertical-align: middle;
            }

            .quick-action-btn {
                min-width: 92px;
            }

            .daily-widget-card {
                border: 0;
                border-radius: 14px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
                background: #ffffff;
            }

            .daily-widget-clickable {
                cursor: pointer;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
            }

            .daily-widget-clickable:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 18px rgba(0, 0, 0, 0.09);
            }

            .daily-widget-title {
                font-size: 0.92rem;
                color: #5f6b7a;
                margin-bottom: 0.35rem;
            }

            .daily-widget-value {
                font-size: 1.6rem;
                line-height: 1.2;
                font-weight: 700;
                color: #1f2d3d;
                font-variant-numeric: tabular-nums;
            }

            .chart-panel {
                border: 0;
                border-radius: 14px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
                background: #ffffff;
            }

            .chart-panel .card-title {
                font-size: 0.98rem;
                font-weight: 600;
                margin-bottom: 0.75rem;
                color: #27384d;
            }

            .chart-canvas-wrap {
                position: relative;
                height: 260px;
            }


            .admin-dashboard-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 1rem;
            }

            .admin-dashboard-header .btn {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                min-height: 40px;
                white-space: nowrap;
                align-self: center;
            }

            .kpi-card .card-body,
            .daily-widget-card .card-body {
                position: relative;
                min-height: 118px;
                padding-right: 4.55rem;
            }

            .kpi-card h6,
            .daily-widget-title {
                padding-right: 0.25rem;
            }

            .kpi-value {
                white-space: nowrap;
            }

            .kpi-money {
                display: flex;
                align-items: baseline;
                gap: 0.35rem;
                white-space: nowrap;
                line-height: 1.12;
                font-size: clamp(1.08rem, 1.45vw, 1.45rem);
            }

            .kpi-money .currency {
                flex: 0 0 auto;
                font-size: 0.72rem;
                font-weight: 800;
                letter-spacing: 0.04em;
                color: #6c757d;
            }

            .kpi-icon-box {
                position: absolute;
                top: 1rem;
                right: 1rem;
                width: 46px;
                height: 46px;
                border-radius: 999px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-size: 1.15rem;
                box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.62);
            }

            .kpi-icon-users {
                color: #0f766e;
                background: rgba(15, 118, 110, 0.12);
            }
            .kpi-icon-active {
                color: #15803d;
                background: rgba(21, 128, 61, 0.12);
            }
            .kpi-icon-locked {
                color: #b45309;
                background: rgba(245, 158, 11, 0.16);
            }
            .kpi-icon-revenue {
                color: #7c3aed;
                background: rgba(124, 58, 237, 0.12);
            }
            .kpi-icon-service {
                color: #0369a1;
                background: rgba(3, 105, 161, 0.12);
            }
            .kpi-icon-visit {
                color: #be123c;
                background: rgba(225, 29, 72, 0.12);
            }
            .kpi-icon-waiting {
                color: #ea580c;
                background: rgba(234, 88, 12, 0.13);
            }
            .kpi-icon-bed {
                color: #2563eb;
                background: rgba(37, 99, 235, 0.12);
            }

            .chart-panel .card-body {
                padding-bottom: 1.35rem;
            }

            .chart-canvas-wrap {
                position: relative;
                height: 260px;
                min-height: 260px;
                width: 100%;
            }

            .chart-canvas-wrap canvas {
                display: block;
                width: 100% !important;
                height: 100% !important;
            }

            @media (max-width: 991.98px) {
                .admin-dashboard-header {
                    align-items: flex-start;
                    flex-direction: column;
                }

                .admin-dashboard-header .btn {
                    align-self: flex-start;
                }
            }

            @media (max-width: 575.98px) {
                .kpi-money {
                    font-size: 1.18rem;
                }
            }
            .status-badge-soft {
                border-radius: 12px;
                padding: 6px 12px;
                font-weight: 600;
                display: inline-block;
            }
            .chart-empty-state {
                position: absolute;
                inset: 0;
                display: flex;
                align-items: center;
                justify-content: center;
                text-align: center;
                color: #6c757d;
                font-weight: 600;
                font-size: 0.95rem;
            }

            .chart-empty-state i {
                font-size: 1.8rem;
                display: block;
                margin-bottom: 0.5rem;
                color: #adb5bd;
            }
            .queue-table-scroll {
                max-height: 350px;
                overflow-y: auto;
                overflow-x: auto;
                border-radius: 12px;
            }

            .queue-table-scroll table {
                margin-bottom: 0;
            }

            .queue-table-scroll thead th {
                position: sticky;
                top: 0;
                z-index: 5;
                background: #f8f9fa;
            }

            .queue-table-scroll tbody tr {
                height: 52px;
            }

        </style>
    </head>
    <body class="bg-light">
        <div class="container py-4">
            <div class="admin-dashboard-header mb-3">
                <div>
                    <h3 class="mb-1">Hệ thống Điều hành & Quản trị Danh mục S-COMS</h3>
                    <p class="text-secondary mb-0">Bảng điều hành quản trị theo chuẩn FR-ADM và BR-08</p>
                </div>
            </div>

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

            <div class="row g-3 mb-4">
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openAccountQuickModal('all')"><div class="card-body"><span class="kpi-icon-box kpi-icon-users"><i class="fa-solid fa-users"></i></span><h6>Tổng tài khoản</h6><h4 id="kpiTotalAccounts" class="kpi-value">${totalAccounts}</h4></div></div></div>
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openAccountQuickModal('active')"><div class="card-body"><span class="kpi-icon-box kpi-icon-active"><i class="fa-solid fa-user-check"></i></span><h6>Tài khoản hoạt động</h6><h4 id="kpiActiveAccounts" class="kpi-value">${activeAccounts}</h4></div></div></div>
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openLockedAccountsModal()"><div class="card-body"><span class="kpi-icon-box kpi-icon-locked"><i class="fa-solid fa-lock"></i></span><h6>Tài khoản đã khóa</h6><h4 id="kpiLockedAccounts" class="kpi-value">${lockedAccounts}</h4></div></div></div>
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openRevenueQuickModal()"><div class="card-body"><span class="kpi-icon-box kpi-icon-revenue"><i class="fa-solid fa-wallet"></i></span><h6>Doanh thu đã thanh toán</h6><h4 id="kpiRevenuePaid" class="kpi-value kpi-money"><span><fmt:formatNumber value="${sumPaidRevenue}" type="number" maxFractionDigits="0" groupingUsed="true" /></span><span class="currency">VNĐ</span></h4></div></div></div>
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openServiceQuickModal()"><div class="card-body"><span class="kpi-icon-box kpi-icon-service"><i class="fa-solid fa-stethoscope"></i></span><h6>Tổng dịch vụ y tế</h6><h4 id="kpiTotalServices" class="kpi-value">${totalServices}</h4></div></div></div>
                <div class="col-md-2"><div class="card h-100 kpi-card dashboard-clickable-card" onclick="openCompletedAppointmentsModal()"><div class="card-body"><span class="kpi-icon-box kpi-icon-visit"><i class="fa-solid fa-clipboard-check"></i></span><h6>Lượt khám hoàn tất</h6><h4 id="kpiCompletedAppointments" class="kpi-value">${completedAppointments}</h4></div></div></div>
            </div>

            <div class="row g-3 mb-3">
                <div class="col-md-4">
                    <div class="card daily-widget-card daily-widget-clickable h-100" onclick="openTodayAppointmentsModal()">
                        <div class="card-body">
                            <span class="kpi-icon-box kpi-icon-visit"><i class="fa-solid fa-calendar-check"></i></span>
                            <div class="daily-widget-title">Tổng số lượt khám trong ngày</div>
                            <div class="daily-widget-value" id="dailyTotalVisits"><c:out value="${todayAppointments}" default="0" /></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card daily-widget-card daily-widget-clickable h-100" onclick="openTodayWaitingModal()">
                        <div class="card-body">
                            <span class="kpi-icon-box kpi-icon-waiting"><i class="fa-solid fa-user-clock"></i></span>
                            <div class="daily-widget-title">Số bệnh nhân đã check-in</div>
                            <div class="daily-widget-value" id="dailyWaitingPatients"><c:out value="${waitingPatients}" default="0" /></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card daily-widget-card daily-widget-clickable h-100" onclick="openDoctorShiftModal()">
                        <div class="card-body">
                            <span class="kpi-icon-box kpi-icon-bed"><i class="fa-solid fa-bed-pulse"></i></span>
                            <div class="daily-widget-title">Danh sách ca trực hôm nay của Bác sĩ</div>
                            <div class="daily-widget-value" id="dailyAvailableBeds"><c:out value="${todayShiftsCount}" default="0" /></div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card mt-3 queue-monitor-card">
                <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
                    <span>Tình trạng hàng đợi phòng khám hôm nay</span>
                    <span class="badge bg-primary text-white queue-summary-badge">Tổng bệnh nhân đã check-in: ${totalWaitingToday}</span>
                </div>
                <div class="card-body">
                    <div class="table-responsive queue-table-scroll">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Bác sĩ trực</th>
                                    <th>Chuyên khoa</th>
                                    <th class="text-end">Số ca đang đợi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${empty todayQueueStatus}">
                                        <tr>
                                            <td colspan="3" class="text-center text-muted py-4">Không có lịch trực hôm nay.</td>
                                        </tr>
                                    </c:when>
                                    <c:otherwise>
                                        <c:forEach var="row" items="${todayQueueStatus}">
                                            <tr class="queue-row"
                                                data-doctor-name="${row.doctorName}"
                                                data-department="${row.department == 'Endocrinology' ? 'Nội tiết - Tiểu đường' : (row.department == 'Cardiology' ? 'Tim mạch' : (row.department == 'Nephrology' ? 'Thận học' : (row.department == 'General' ? 'Tổng quát' : row.department)))}"
                                                data-waiting-count="${row.waitingCount}"
                                                onclick="openDoctorQueueModal('${row.doctorId}', this.dataset.doctorName, this.dataset.department)">
                                                <td>${row.doctorName}</td>
                                                <td>${row.department == 'Endocrinology' ? 'Nội tiết - Tiểu đường' : (row.department == 'Cardiology' ? 'Tim mạch' : (row.department == 'Nephrology' ? 'Thận học' : (row.department == 'General' ? 'Tổng quát' : row.department)))}</td>
                                                <td class="text-end">
                                                    <span class="badge queue-load-badge" data-waiting-count="${row.waitingCount}">${row.waitingCount}</span>
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

            <div class="row g-3 mt-2">
                <div class="col-md-4">
                    <div class="card chart-panel h-100">
                        <div class="card-body">
                            <h6 class="card-title">Lưu lượng bệnh nhân theo giờ</h6>
                            <div class="chart-canvas-wrap">
                                <canvas id="todayHourlyFlowChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card chart-panel h-100">
                        <div class="card-body">
                            <h6 class="card-title">Doanh thu theo loại dịch vụ</h6>
                            <div class="chart-canvas-wrap">
                                <canvas id="todayRevenueServiceChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card chart-panel h-100">
                        <div class="card-body">
                            <h6 class="card-title">Tỷ lệ trạng thái ca khám hôm nay</h6>
                            <div class="chart-canvas-wrap">
                                <canvas id="todayStatusPieChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

                </div>
            </div>

        </div>

        <div class="modal fade" id="dashboardQuickModal" tabindex="-1" aria-labelledby="dashboardQuickModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-xl modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="dashboardQuickModalLabel">Xem nhanh dữ liệu</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body" id="dashboardQuickModalBody">
                        <div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>
                    </div>
                    <div class="modal-footer" id="dashboardQuickModalFooter">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="dashboardInvoiceDetailModal" tabindex="-1" aria-labelledby="dashboardInvoiceDetailModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="dashboardInvoiceDetailModalLabel">Chi tiết hóa đơn nhanh</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body" id="dashboardInvoiceDetailModalBody">
                        <div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                        <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin?action=reports">Mở Báo cáo chuyên sâu</a>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="doctorQueueModal" tabindex="-1" aria-labelledby="doctorQueueModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-xl modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="doctorQueueModalLabel">Chi tiết hàng đợi</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="table-responsive">
                            <table class="table table-sm table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>STT</th>
                                        <th>Mã lịch hẹn</th>
                                        <th>Tên bệnh nhân</th>
                                        <th>Khung giờ hẹn</th>
                                        <th>Trạng thái</th>
                                        <th class="text-end">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody id="doctorQueueTableBody">
                                    <tr>
                                        <td colspan="6" class="text-center text-muted py-4">Chọn bác sĩ để xem chi tiết hàng đợi.</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="todayAppointmentsModal" tabindex="-1" aria-labelledby="todayAppointmentsModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-xl modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="todayAppointmentsModalLabel">Danh sách ca khám hôm nay</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="table-responsive">
                            <table class="table table-sm table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>STT</th>
                                        <th>Bệnh nhân</th>
                                        <th>Bác sĩ</th>
                                        <th>Ngày Khám</th>
                                        <th>Giờ hẹn</th>
                                        <th>Trạng thái</th>
                                    </tr>
                                </thead>
                                <tbody id="todayAppointmentsTableBody">
                                    <tr><td colspan="6" class="text-center text-muted py-4">Đang tải dữ liệu...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="todayWaitingModal" tabindex="-1" aria-labelledby="todayWaitingModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-xl modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="todayWaitingModalLabel">Danh sách bệnh nhân đã check-in</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="table-responsive">
                            <table class="table table-sm table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>STT</th>
                                        <th>Bệnh nhân</th>
                                        <th>Chuyên khoa</th>
                                        <th>Giờ hẹn</th>
                                        <th>Trạng thái</th>
                                        <th>Thời gian chờ</th>
                                    </tr>
                                </thead>
                                <tbody id="todayWaitingTableBody">
                                    <tr><td colspan="6" class="text-center text-muted py-4">Đang tải dữ liệu...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="bedAvailabilityModal" tabindex="-1" aria-labelledby="bedAvailabilityModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header">
                        <h5 class="modal-title" id="bedAvailabilityModalLabel">Danh sách ca trực hôm nay của Bác sĩ</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Mã ca</th>
                                        <th>Bác sĩ trực</th>
                                        <th>Chuyên khoa</th>
                                        <th>Khung giờ</th>
                                        <th class="text-end">Đã đặt / tối đa</th>
                                        <th>Trạng thái ca</th>
                                    </tr>
                                </thead>
                                <tbody id="bedAvailabilityTableBody">
                                    <c:choose>
                                        <c:when test="${empty todayShiftsList}">
                                            <tr>
                                                <td colspan="6" class="text-center text-muted py-4">Không có ca trực hôm nay.</td>
                                            </tr>
                                        </c:when>
                                        <c:otherwise>
                                            <c:forEach var="shift" items="${todayShiftsList}">
                                                <tr>
                                                    <td>${shift.scheduleId}</td>
                                                    <td>${shift.fullName}</td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${shift.department eq 'Endocrinology'}">Nội tiết - Tiểu đường</c:when>
                                                            <c:when test="${shift.department eq 'Cardiology'}">Tim mạch</c:when>
                                                            <c:when test="${shift.department eq 'Nephrology'}">Thận học</c:when>
                                                            <c:when test="${shift.department eq 'General'}">Tổng quát</c:when>
                                                            <c:otherwise>${shift.department}</c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>${shift.timeSlot}</td>
                                                    <td class="text-end">
                                                        <c:set var="currentLoad" value="${empty shift.currentLoad ? 0 : shift.currentLoad}" />
                                                        <c:set var="activeLoad" value="${empty shift.activeCount ? 0 : shift.activeCount}" />
                                                        <c:set var="maxPatients" value="${empty shift.maxPatients ? 0 : shift.maxPatients}" />
                                                        <c:set var="onlineQuota" value="${empty shift.onlineQuota ? (maxPatients > 1 ? maxPatients - 1 : maxPatients) : shift.onlineQuota}" />
                                                        <c:set var="onlineBookedCount" value="${empty shift.onlineBookedCount ? 0 : shift.onlineBookedCount}" />
                                                        <c:set var="reservedSlots" value="${empty shift.reservedSlots ? (maxPatients - onlineQuota) : shift.reservedSlots}" />
                                                        <c:choose>
                                                            <c:when test="${maxPatients le 0}">
                                                                <span class="badge bg-secondary">${currentLoad} / ${maxPatients}</span>
                                                            </c:when>
                                                            <c:when test="${currentLoad * 100 ge maxPatients * 100}">
                                                                <span class="badge bg-danger">${currentLoad} / ${maxPatients}</span>
                                                            </c:when>
                                                            <c:when test="${currentLoad * 100 ge maxPatients * 80}">
                                                                <span class="badge bg-warning text-dark">${currentLoad} / ${maxPatients}</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge bg-success">${currentLoad} / ${maxPatients}</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                        <small class="d-block text-muted mt-1">Đã check-in/đang khám: ${activeLoad}</small>
                                                        <small class="d-block text-muted">Online: ${onlineBookedCount}/${onlineQuota} - Dự phòng: ${reservedSlots} slot</small>
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${shift.status eq 'available' or shift.status eq 'Available'}">
                                                                <span class="badge bg-success">Khả dụng</span>
                                                            </c:when>
                                                            <c:when test="${shift.status eq 'Full'}">
                                                                <span class="badge bg-danger">Đã đầy</span>
                                                            </c:when>
                                                            <c:when test="${shift.status eq 'Cancelled'}">
                                                                <span class="badge bg-dark">Đã hủy</span>
                                                            </c:when>
                                                            <c:when test="${shift.status eq 'Expired'}">
                                                                <span class="badge bg-secondary">Đã qua</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge bg-secondary">${shift.status}</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                        </c:otherwise>
                                    </c:choose>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
        <script>
    window.AdminConfig = window.AdminConfig || {};
    window.AdminConfig.contextPath = '${pageContext.request.contextPath}';
    window.AdminConfig.csrfToken = '${sessionScope.csrfToken}';
    window.AdminConfig.adminEndpoint = '${pageContext.request.contextPath}/admin';
    window.AdminConfig.loginUrl = '${pageContext.request.contextPath}/login.jsp';
    window.AdminConfig.todayPatientFlowData = ${empty todayPatientFlowJson ? '[]' : todayPatientFlowJson};
    window.AdminConfig.todayRevenueByServiceData = ${empty todayRevenueByServiceJson ? '[]' : todayRevenueByServiceJson};
    window.AdminConfig.todayStatusDistributionData = ${empty todayStatusDistributionJson ? '[]' : todayStatusDistributionJson};
</script>
<script src="${pageContext.request.contextPath}/assets/js/pages/admin/dashboard.js"></script>

        <%--
        ==================== Servlet + DAO mẫu để cấp dữ liệu động cho Dashboard ====================

// AdminDashboardServlet.java (mẫu)
@WebServlet("/admin")
public class AdminDashboardServlet extends HttpServlet {
    private final DashboardDAO dashboardDAO = new DashboardDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int todayAppointments = dashboardDAO.countTodayAppointments();
        int waitingPatients = dashboardDAO.countWaitingPatientsToday();
        int availableBeds = dashboardDAO.countAvailableBeds();

        request.setAttribute("todayAppointments", todayAppointments);
        request.setAttribute("waitingPatients", waitingPatients);
        request.setAttribute("availableBeds", availableBeds);

        request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
    }
}

// DashboardDAO.java (mẫu JDBC SQL Server)
public class DashboardDAO {
    public int countTodayAppointments() {
        String sql = "SELECT COUNT(*) FROM Appointment WHERE CAST(appointment_date AS date) = CAST(GETDATE() AS date)";
        return queryForCount(sql);
    }

    public int countWaitingPatientsToday() {
        String sql = "SELECT COUNT(*) FROM Appointment WHERE status = 'Waiting' AND CAST(appointment_date AS date) = CAST(GETDATE() AS date)";
        return queryForCount(sql);
    }

    public int countAvailableBeds() {
        String sql = "SELECT COUNT(*) FROM Bed WHERE status = 'Available'";
        return queryForCount(sql);
    }

    private int queryForCount(String sql) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}

// AdminAccountServlet.java JSON mẫu: /AdminAccountServlet?action=getAccounts&status=locked
// AdminAppointmentServlet.java JSON mẫu: /AdminAppointmentServlet?action=getAppointments&status=Completed
==============================================================================================
        --%>
    </body>
</html>





