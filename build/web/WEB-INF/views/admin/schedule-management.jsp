<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:setLocale value="vi_VN" />

<c:set var="currentAction" value="schedule" />

<%--
    Trang Quản lý lịch trực bác sĩ:
    - Lọc, xem tải ca trực theo bác sĩ/khoa/ngày
    - Tạo ca thủ công và hủy ca
    - Tích hợp modal AI lập lịch (Gemini + fallback)
--%>

<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Quản lý Lịch trực Bác sĩ - S-COMS</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
        <link href="${pageContext.request.contextPath}/assets/css/pages/admin/admin-ui.css" rel="stylesheet">
        <style>
            .schedule-load-cell {
                min-width: 220px;
            }

            .schedule-load-wrap {
                display: grid;
                grid-template-columns: minmax(84px, 1fr) 56px 80px;
                align-items: center;
                column-gap: 0.5rem;
            }

            .schedule-load-progress {
                height: 10px;
                margin: 0;
            }

            .schedule-load-percent {
                min-width: 56px;
                text-align: center;
                font-weight: 600;
            }

            .schedule-table > :not(caption) > * > * {
                padding: 0.68rem 0.55rem;
            }

            .schedule-table thead th {
                white-space: normal;
                line-height: 1.2;
                font-size: 0.78rem;
            }

            .schedule-table td {
                font-size: 0.95rem;
            }


            .text-purple {
                color: #6f42c1 !important;
            }

            .bg-purple-subtle {
                background: linear-gradient(135deg, rgba(111, 66, 193, 0.12), rgba(139, 92, 246, 0.18)) !important;
            }

            .ai-schedule-toolbar-btn {
                border: 1px solid rgba(111, 66, 193, 0.24);
                box-shadow: 0 8px 18px rgba(111, 66, 193, 0.10);
                transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
            }

            .ai-schedule-toolbar-btn:hover,
            .ai-schedule-toolbar-btn:focus {
                color: #5b2fb0 !important;
                border-color: rgba(111, 66, 193, 0.42);
                transform: translateY(-1px);
                box-shadow: 0 12px 24px rgba(111, 66, 193, 0.16);
            }

            .ai-schedule-toolbar-btn:disabled {
                opacity: 0.78;
                transform: none;
                box-shadow: none;
            }

            .ai-schedule-loading {
                border: 1px solid rgba(111, 66, 193, 0.18);
                background: linear-gradient(135deg, rgba(111, 66, 193, 0.10), rgba(13, 202, 240, 0.10));
                color: #4b327f;
                border-radius: 16px;
                animation: ai-schedule-glow 1.25s ease-in-out infinite alternate;
            }

            @keyframes ai-schedule-glow {
                from {
                    box-shadow: 0 0 0 rgba(111, 66, 193, 0);
                }
                to {
                    box-shadow: 0 12px 28px rgba(111, 66, 193, 0.14);
                }
            }

            .ai-generated-row {
                background: linear-gradient(90deg, rgba(111, 66, 193, 0.08), rgba(13, 202, 240, 0.05));
                animation: ai-row-arrive 0.42s ease-out;
            }

            @keyframes ai-row-arrive {
                from {
                    opacity: 0;
                    transform: translateY(-8px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .ai-schedule-badge {
                background: rgba(111, 66, 193, 0.12);
                color: #5b2fb0;
                border: 1px solid rgba(111, 66, 193, 0.22);
            }
            .schedule-load-state {
                min-width: 80px;
                line-height: 1;
                margin: 0;
                text-align: left;
                white-space: normal;
            }

            .ai-step-banner,
            .ai-task-summary {
                border: 1px solid rgba(111, 66, 193, 0.16);
                background: #f8f7fc;
                border-radius: 14px;
            }

            .ai-section-number {
                display: inline-flex;
                width: 28px;
                height: 28px;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
                background: #6f42c1;
                color: #fff;
                font-size: 0.8rem;
                margin-right: 0.55rem;
            }

            .weekday-options {
                display: grid;
                grid-template-columns: repeat(7, minmax(50px, 1fr));
                gap: 0.3rem;
            }

            #aiScheduleModal .modal-dialog {
                max-width: 580px;
            }

            #aiScheduleModal .modal-header,
            #aiScheduleModal .modal-body,
            #aiScheduleModal .modal-footer {
                padding: 0.7rem 0.85rem;
            }

            #aiScheduleModal .modal-header h5 {
                margin-bottom: 0.2rem !important;
            }

            #aiScheduleModal .modal-header .small {
                font-size: 0.75rem;
            }

            #aiScheduleModal .modal-title {
                font-size: 1.15rem;
                font-weight: 600;
            }

            #aiScheduleModal .form-label {
                margin-bottom: 0.25rem;
                font-size: 0.9rem;
            }

            #aiScheduleModal .ai-section-number {
                width: 24px;
                height: 24px;
                font-size: 0.72rem;
                margin-right: 0.45rem;
            }

            #aiScheduleModal .weekday-option label {
                padding: 0.5rem 0.4rem;
                border-radius: 9px;
            }

            #aiScheduleModal .row {
                --bs-gutter-x: 0.75rem;
                --bs-gutter-y: 0.5rem;
                margin-right: calc(var(--bs-gutter-x) * -0.5) !important;
                margin-left: calc(var(--bs-gutter-x) * -0.5) !important;
            }

            #aiScheduleModal .col-md-4,
            #aiScheduleModal .col-md-6,
            #aiScheduleModal .col-12 {
                margin-bottom: 0.45rem;
            }

            #aiScheduleModal .form-control,
            #aiScheduleModal .form-select,
            #aiScheduleModal .input-group {
                font-size: 0.9rem;
                padding: 0.35rem 0.55rem;
            }

            #aiScheduleModal .template-preview {
                max-height: 100px;
                font-size: 0.85rem;
            }

            #aiScheduleModal .ai-step-banner,
            #aiScheduleModal .ai-task-summary {
                border-radius: 12px;
                padding: 0.5rem 0.7rem !important;
                margin-bottom: 0.3rem !important;
                font-size: 0.85rem;
            }

            #aiScheduleModal .ai-task-summary .fw-bold {
                font-size: 0.85rem;
                margin-bottom: 0.15rem !important;
            }

            #aiScheduleModal .ai-task-summary div:last-child {
                font-size: 0.8rem;
            }

            #aiScheduleModal .btn {
                padding: 0.35rem 0.75rem;
                font-size: 0.9rem;
            }

            .cursor-pointer {
                cursor: pointer;
                user-select: none;
            }

            #aiDepartmentList .badge {
                cursor: pointer;
                transition: opacity 0.2s;
                font-size: 0.8rem;
                padding: 0.3rem 0.5rem;
            }

            #aiDepartmentList .badge:hover {
                opacity: 0.8;
            }

            #aiScheduleModal .input-group-sm > .btn {
                padding: 0.25rem 0.55rem;
                font-size: 0.85rem;
            }

            .weekday-option {
                position: relative;
            }

            .weekday-option input {
                position: absolute;
                opacity: 0;
                pointer-events: none;
            }

            .weekday-option label {
                display: block;
                padding: 0.4rem 0.3rem;
                border: 1px solid #dee2e6;
                border-radius: 8px;
                background: #fff;
                text-align: center;
                cursor: pointer;
                transition: 0.18s ease;
                font-size: 0.8rem;
                white-space: nowrap;
            }

            .weekday-option input:checked + label {
                border-color: #6f42c1;
                background: rgba(111, 66, 193, 0.10);
                color: #5b2fb0;
                font-weight: 700;
            }

            .template-preview {
                max-height: 172px;
                resize: none;
                background: #fbfbfd;
            }

            @media (max-width: 767.98px) {
                .weekday-options {
                    grid-template-columns: repeat(4, 1fr);
                }

                #aiScheduleModal .modal-dialog {
                    max-width: calc(100% - 1rem);
                    margin: 0.5rem auto;
                }

                #aiScheduleModal .modal-title {
                    font-size: 1.1rem;
                }

                #aiScheduleModal .modal-body {
                    padding: 0.8rem;
                }
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
                    <div class="admin-page-header d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h3 class="mb-1">Quản lý Lịch trực Bác sĩ</h3>
                        </div>
                        <div class="d-flex gap-2">
                            <button type="button" id="aiScheduleGeminiBtn" class="btn bg-purple-subtle text-purple fw-bold ai-schedule-toolbar-btn" data-bs-toggle="modal" data-bs-target="#aiScheduleModal">
                                <i class="fa-solid fa-brain me-2"></i>AI Lập Lịch (Gemini)
                            </button>
                            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createScheduleModal">Tạo lịch trực mới</button>
                        </div>
                    </div>

                    <!-- Modal chuyển giao ca trực (AJAX) -->
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
                                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
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
                <span class="fw-semibold">Gemini AI đang phân tích dữ liệu hiệu suất và tự động phân bổ ca trực...</span><span id="aiScheduleLoadingDetail" class="small text-muted ms-2"></span>
            </div>

            <div class="card mb-3">
                <div class="card-body">
                    <form method="get" action="${pageContext.request.contextPath}/admin" class="row g-3 align-items-end">
                        <input type="hidden" name="action" value="schedule">
                        <div class="col-md-3">
                            <label class="form-label">Chuyên khoa</label>
                            <select class="form-select" name="department">
                                <option value="">Tất cả chuyên khoa</option>
                                <c:forEach var="dep" items="${departments}">
                                    <option value="${dep}" ${selectedDepartment == dep ? 'selected' : ''}>
                                        <c:choose>
                                            <c:when test="${dep == 'Endocrinology'}">Nội tiết - Tiểu đường</c:when>
                                            <c:when test="${dep == 'Cardiology'}">Tim mạch</c:when>
                                            <c:when test="${dep == 'Nephrology'}">Thận học</c:when>
                                            <c:when test="${dep == 'General'}">Tổng quát</c:when>
                                            <c:otherwise>${dep}</c:otherwise>
                                        </c:choose>
                                    </option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Tìm theo tên Bác sĩ</label>
                            <input type="text" class="form-control" name="doctorName" placeholder="Nhập tên bác sĩ" value="${doctorNameFilter}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Ngày trực</label>
                            <input type="date" class="form-control" name="workDate" value="${selectedWorkDate}">
                        </div>
                        <div class="col-md-2 d-flex gap-2">
                            <button type="submit" class="btn btn-primary w-100">Lọc</button>
                            <a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/admin?action=schedule">Reset</a>
                        </div>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header fw-semibold">Danh sách lịch trực</div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0 schedule-table">
                        <thead class="table-light">
                            <tr>
                                <th>Tên bác sĩ</th>
                                <th>Chuyên khoa</th>
                                <th>Ngày trực</th>
                                <th>Khung giờ</th>
                                <th>Tải hiện tại (Đã đặt / Tối đa)</th>
                                <th>Quota online</th>
                                <th>Mức tải</th>
                                <th>Trạng thái slot</th>
                                <th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody id="scheduleTableBody">
                            <c:if test="${empty schedules}">
                                <tr>
                                    <td colspan="9" class="text-center text-muted py-4">
                                        <i class="bi bi-inbox"></i> Không có ca trực nào. Hãy tạo lịch trực mới hoặc thay đổi bộ lọc.
                                    </td>
                                </tr>
                            </c:if>
                            <c:forEach var="s" items="${schedules}">
                                <c:set var="bookedAppointments" value="${empty s.bookedAppointments ? 0 : s.bookedAppointments}" />
                                <c:set var="activeAppointments" value="${empty s.activeAppointments ? 0 : s.activeAppointments}" />
                                <c:set var="onlineQuota" value="${empty s.onlineQuota ? 0 : s.onlineQuota}" />
                                <c:set var="onlineBookedCount" value="${empty s.onlineBookedCount ? 0 : s.onlineBookedCount}" />
                                <c:set var="reservedSlots" value="${empty s.reservedSlots ? (s.maxPatients - onlineQuota) : s.reservedSlots}" />
                                <c:set var="loadPct" value="${s.maxPatients > 0 ? (bookedAppointments * 100.0 / s.maxPatients) : 0}" />
                                <tr data-schedule-id="${s.scheduleId}" data-doctor-name="${s.doctorName}" data-department="${s.department}" data-load-pct="${loadPct}" data-active-appointments="${activeAppointments}" data-booked-appointments="${bookedAppointments}" data-online-booked-count="${onlineBookedCount}" data-max-patients="${s.maxPatients}" data-online-quota="${onlineQuota}" data-reserved-slots="${reservedSlots}">
                                    <td>${s.doctorName}</td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.department == 'Endocrinology'}">Nội tiết - Tiểu đường</c:when>
                                            <c:when test="${s.department == 'Cardiology'}">Tim mạch</c:when>
                                            <c:when test="${s.department == 'Nephrology'}">Thận học</c:when>
                                            <c:when test="${s.department == 'General'}">Tổng quát</c:when>
                                            <c:otherwise>${s.department}</c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td><fmt:formatDate value="${s.workDate}" pattern="dd/MM/yyyy" /></td>
                                    <td>${s.timeSlot}</td>
                                    <td>
                                        <div style="background-color: #f0f8f4; padding: 6px 10px; border-radius: 4px; font-weight: 500; text-align: center;">${bookedAppointments} / ${s.maxPatients}</div>
                                        <small class="text-muted d-block text-center mt-1">Đã check-in/đang khám: ${activeAppointments}</small>
                                        <small class="text-muted d-block text-center">Dự phòng: ${reservedSlots} slot</small>
                                    </td>
                                    <td class="text-center">
                                        <div class="fw-semibold">${onlineBookedCount} / ${onlineQuota}</div>
                                        <small class="text-muted d-block">Slot online</small>
                                        <c:choose>
                                            <c:when test="${onlineBookedCount gt onlineQuota}">
                                                <span class="badge text-bg-danger mt-1">Vượt quota online</span>
                                            </c:when>
                                            <c:when test="${onlineBookedCount ge onlineQuota and onlineQuota ge 0}">
                                                <span class="badge text-bg-warning mt-1">Hết slot online</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge text-bg-success mt-1">Còn slot online</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="schedule-load-cell">
                                        <div class="schedule-load-wrap" title="${loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Bình thường')}">
                                            <div class="progress schedule-load-progress">
                                                <div class="progress-bar ${loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')}"
                                                     role="progressbar"
                                                     style="width: ${loadPct > 100 ? 100 : loadPct}%;"
                                                     aria-valuemin="0" aria-valuemax="100" aria-valuenow="${loadPct}"></div>
                                            </div>
                                            <span class="badge schedule-load-percent ${loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')}">
                                                <fmt:formatNumber value="${loadPct}" maxFractionDigits="0"/>%
                                            </span>
                                            <small class="text-muted schedule-load-state">${loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Bình thường')}</small>
                                        </div>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.effectiveStatus == 'Expired'}">
                                                <span class="badge text-bg-secondary">
                                                    <i class="bi bi-clock"></i> Đã qua
                                                </span>
                                            </c:when>

                                            <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                <span class="badge text-bg-dark">
                                                    <i class="bi bi-x-circle"></i> Đã hủy
                                                </span>
                                            </c:when>

                                            <c:when test="${s.effectiveStatus == 'Full'}">
                                                <span class="badge text-bg-danger">
                                                    <i class="bi bi-exclamation-circle"></i> Đã đầy
                                                </span>
                                            </c:when>

                                            <c:when test="${s.effectiveStatus == 'Available'}">
                                                <span class="badge text-bg-success">
                                                    <i class="bi bi-check-circle"></i> Khả dụng
                                                </span>
                                            </c:when>

                                            <c:otherwise>
                                                <span class="badge text-bg-secondary">
                                                    ${s.effectiveStatus}
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${s.effectiveStatus == 'Expired'}">
                                                <button type="button" class="btn btn-sm btn-outline-secondary" disabled>
                                                    <i class="bi bi-clock"></i> Đã qua
                                                </button>
                                            </c:when>

                                            <c:when test="${s.effectiveStatus == 'Cancelled'}">
                                                <button type="button" class="btn btn-sm btn-outline-dark" disabled>
                                                    <i class="bi bi-x-circle"></i> Đã hủy
                                                </button>
                                            </c:when>

                                            <c:otherwise>
                                                <button type="button" class="btn btn-sm btn-outline-primary me-2" style="border-color:#0d6efd;color:#0d6efd;"
                                                        onclick="openEditScheduleModal('${s.scheduleId}'); return false;">
                                                    <i class="bi bi-pencil-square"></i> Chỉnh sửa
                                                </button>
                                                <form method="post" action="${pageContext.request.contextPath}/admin" class="d-inline"
                                                      onsubmit="return confirm('Bạn chắc chắn muốn hủy ca trực này?');">
                                                    <input type="hidden" name="action" value="cancelSchedule">
                                                    <input type="hidden" name="scheduleId" value="${s.scheduleId}">
                                                    <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger">
                                                        <i class="bi bi-trash"></i> Hủy lịch
                                                    </button>
                                                </form>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>

            <c:if test="${not empty selectedSchedule}">
                <div class="card mt-4 border-primary-subtle">
                    <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
                        <span>Chuyển giao ca trực</span>
                        <a class="btn btn-sm btn-outline-secondary" href="${pageContext.request.contextPath}/admin?action=schedule">Đóng</a>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <div class="small text-muted mb-1">Ca đang chọn</div>
                            <div class="fw-semibold">
                                ${selectedSchedule.doctorName} -
                                <c:choose>
                                    <c:when test="${selectedSchedule.department == 'Endocrinology'}">Nội tiết - Tiểu đường</c:when>
                                    <c:when test="${selectedSchedule.department == 'Cardiology'}">Tim mạch</c:when>
                                    <c:when test="${selectedSchedule.department == 'Nephrology'}">Thận học</c:when>
                                    <c:when test="${selectedSchedule.department == 'General'}">Tổng quát</c:when>
                                    <c:otherwise>${selectedSchedule.department}</c:otherwise>
                                </c:choose>
                                - <fmt:formatDate value="${selectedSchedule.workDate}" pattern="dd/MM/yyyy" />
                                - ${selectedSchedule.timeSlot}
                            </div>
                        </div>
                        <form method="post" action="${pageContext.request.contextPath}/admin" class="row g-3">
                            <input type="hidden" name="action" value="transferSchedule">
                            <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                            <input type="hidden" name="scheduleId" value="${selectedSchedule.scheduleId}">
                            <div class="col-md-8">
                                <label class="form-label">Chọn bác sĩ nhận ca</label>
                                <select class="form-select" name="targetDoctorId" required>
                                    <option value="">-- Chọn bác sĩ thay thế --</option>
                                    <c:forEach var="d" items="${transferCandidates}">
                                        <option value="${d.doctorId}">${d.fullName} - ${d.department}</option>
                                    </c:forEach>
                                </select>
                                <small class="text-muted">Hệ thống sẽ kiểm tra trùng ca và chỉ cho phép chuyển sang bác sĩ còn khả dụng.</small>
                            </div>
                            <div class="col-md-4 d-flex align-items-end">
                                <button type="submit" class="btn btn-primary w-100">Xác nhận chuyển giao</button>
                            </div>
                        </form>
                    </div>
                </div>
            </c:if>
            </div>
        </div>

        <div class="modal fade" id="createScheduleModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <form method="post" action="${pageContext.request.contextPath}/admin">
                        <input type="hidden" name="action" value="createSchedule">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        <div class="modal-header">
                            <h5 class="modal-title">Tạo lịch trực mới</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <div class="mb-3">
                                <label class="form-label">Bác sĩ</label>
                                <select class="form-select" name="doctorId" required>
                                    <c:forEach var="d" items="${doctors}">
                                        <option value="${d.doctorId}">${d.fullName}</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Ngày trực</label>
                                <input type="date" class="form-control" name="workDate" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Khung giờ</label>
                                <input class="form-control" name="timeSlot" placeholder="07:00-09:00" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Số bệnh nhân tối đa</label>
                                <input type="number" class="form-control" name="maxPatients" min="1" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Slot online</label>
                                <input type="number" class="form-control" name="onlineQuota" min="0" placeholder="Tự động nếu bỏ trống">
                                <div class="form-text">Nếu để trống, hệ thống sẽ tự dùng cấu hình an toàn mặc định.</div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                            <button type="submit" class="btn btn-primary">Lưu lịch trực</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>


        <div class="modal fade" id="aiScheduleModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content border-0 shadow-lg">
                    <form id="aiScheduleForm">
                        <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                        <div class="modal-header bg-purple-subtle">
                            <div>
                                <h5 class="modal-title text-purple fw-bold mb-1"><i class="fa-solid fa-wand-magic-sparkles me-2"></i>AI LẬP LỊCH THÔNG MINH S-COMS</h5>
                                <div class="small text-secondary">Nhân bản khung lịch rỗng và để Gemini điền bác sĩ phù hợp.</div>
                            </div>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <div id="aiScheduleModalAlert" class="ai-step-banner p-3 mb-4 text-purple fw-semibold">
                                <i class="fa-solid fa-circle-info me-2"></i>
                                Bước 1: Nhân bản khung lịch rỗng
                                <i class="fa-solid fa-arrow-right mx-2"></i>
                                Bước 2: Gemini tự động điền bác sĩ
                            </div>
                            <div class="row g-3">
                                <div class="col-12">
                                    <label class="form-label fw-bold">
                                        <span class="ai-section-number">1</span>THIẾT KẾ KHUNG CA TRỰC
                                    </label>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Giờ bắt đầu</label>
                                    <input type="time" class="form-control" id="aiStartTime" value="07:00" required>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Giờ kết thúc</label>
                                    <input type="time" class="form-control" id="aiEndTime" value="19:00" required>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Giãn cách (phút)</label>
                                    <select class="form-select" id="aiSlotDuration" required>
                                        <option value="30">30 phút</option>
                                        <option value="60" selected>60 phút (1 tiếng)</option>
                                        <option value="90">90 phút</option>
                                        <option value="120">120 phút (2 tiếng)</option>
                                        <option value="180">180 phút (3 tiếng)</option>
                                    </select>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-semibold">Phân bổ chuyên khoa cho từng ca <small class="text-muted">(nhập lặp lại để chuyên khoa khác nhau)</small></label>
                                    <div class="input-group input-group-sm mb-2">
                                        <input type="text" class="form-control" id="aiDepartmentInput" placeholder="Nội tiết - Tiểu đường, Tim mạch, Thận học, Tổng quát, ...">
                                        <button class="btn btn-outline-secondary" type="button" id="aiAddDepartmentBtn">Thêm</button>
                                    </div>
                                    <div class="d-flex flex-wrap gap-2" id="aiDepartmentList">
                                        <span class="badge bg-info text-dark cursor-pointer" data-dept="Nội tiết - Tiểu đường">Nội tiết - Tiểu đường ✕</span>
                                        <span class="badge bg-info text-dark cursor-pointer" data-dept="Tim mạch">Tim mạch ✕</span>
                                        <span class="badge bg-info text-dark cursor-pointer" data-dept="Thận học">Thận học ✕</span>
                                        <span class="badge bg-info text-dark cursor-pointer" data-dept="Tổng quát">Tổng quát ✕</span>
                                    </div>
                                </div>

                                <div class="col-12">
                                    <label class="form-label fw-bold">
                                        <span class="ai-section-number">2</span>CHỌN CÁC NGÀY ÁP DỤNG KHUNG NÀY TRONG TUẦN
                                    </label>
                                    <div class="weekday-options">
                                        <div class="weekday-option"><input type="checkbox" id="weekday1" name="selectedWeekdays" value="1" checked><label for="weekday1">Thứ 2</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday2" name="selectedWeekdays" value="2" checked><label for="weekday2">Thứ 3</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday3" name="selectedWeekdays" value="3" checked><label for="weekday3">Thứ 4</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday4" name="selectedWeekdays" value="4" checked><label for="weekday4">Thứ 5</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday5" name="selectedWeekdays" value="5" checked><label for="weekday5">Thứ 6</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday6" name="selectedWeekdays" value="6"><label for="weekday6">Thứ 7</label></div>
                                        <div class="weekday-option"><input type="checkbox" id="weekday7" name="selectedWeekdays" value="7"><label for="weekday7">Chủ Nhật</label></div>
                                    </div>
                                </div>

                                <div class="col-12">
                                    <label class="form-label fw-bold">
                                        <span class="ai-section-number">3</span>THÔNG TIN PHẠM VI LỊCH TRỰC
                                    </label>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Từ ngày</label>
                                    <input type="date" class="form-control" name="startDate" id="aiStartDate" required>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Đến ngày</label>
                                    <input type="date" class="form-control" name="endDate" id="aiEndDate" required>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Số bệnh nhân tối đa/ca</label>
                                    <input type="number" class="form-control" name="maxPatients" min="1" max="100" value="20" required>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Số bác sĩ trực mỗi ca</label>
                                    <select class="form-select" name="doctorsPerShift" id="aiDoctorsPerShift" required>
                                        <option value="1" selected>1 bác sĩ/ca</option>
                                        <option value="2">2 bác sĩ/ca</option>
                                        <option value="3">3 bác sĩ/ca</option>
                                    </select>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Tổng số slot bác sĩ phải tạo</label>
                                    <input type="number" class="form-control" name="maxSchedules" id="aiMaxSchedules" value="12" readonly>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-semibold">Xem trước khung mẫu ca trực</label>
                                    <textarea class="form-control font-monospace template-preview" name="shiftTemplates" rows="8" required readonly></textarea>
                                </div>
                                <input type="hidden" name="startTime" value="07:00">
                                <input type="hidden" name="endTime" value="19:00">
                                <input type="hidden" name="slotMinutes" value="60">
                                <input type="hidden" name="department" value="">
                                <div class="col-12">
                                    <div class="ai-task-summary p-3">
                                        <div class="fw-bold text-purple mb-1"><i class="fa-solid fa-chart-column me-2"></i>TỔNG QUAN TÁC VỤ</div>
                                        <div id="aiScheduleSummary">Hệ thống sẽ tạo lịch rỗng trước, sau đó Gemini điền bác sĩ đúng chuyên khoa.</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy bỏ</button>
                            <button type="submit" id="aiScheduleSubmitBtn" class="btn bg-purple-subtle text-purple fw-bold ai-schedule-toolbar-btn">
                                <i class="fa-solid fa-rocket me-2"></i>Tiến hành phân bổ bằng AI
                            </button>
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
<script src="${pageContext.request.contextPath}/assets/js/pages/admin/schedule-management.js"></script>
        
        

        <!-- Modal xem danh sách bệnh nhân của ca trực -->
        <div class="modal fade" id="scheduleAppointmentsModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Danh sách bệnh nhân - Ca trực <span id="appointmentsModalTitle"></span></h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Thời gian</th>
                                        <th>Tên bệnh nhân</th>
                                        <th>Nguồn đặt</th>
                                        <th>Trạng thái khám</th>
                                    </tr>
                                </thead>
                                <tbody id="appointmentsTableBody">
                                    <tr>
                                        <td colspan="4" class="text-center text-muted py-3">
                                            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                                            Đang tải...
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        
</body>
