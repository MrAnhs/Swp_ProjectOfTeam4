<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Lịch trực Bác sĩ - DiabetesCare</title>
    <%@ include file="/WEB-INF/views/components/shared/master-head.jspf" %>
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
    <style>
        .grid-header-cell {
            background-color: #0F172A !important;
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            color: #2AB5A3 !important;
            text-align: center;
            font-weight: 700;
        }
        .schedule-cell-card {
            border: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-radius: 12px;
            background-color: rgba(30, 41, 59, 0.45) !important;
            color: #ffffff !important;
            backdrop-filter: blur(12px) !important;
            transition: all 0.2s ease;
        }
        .schedule-cell-card:hover {
            transform: translateY(-2px);
            border-color: rgba(42, 181, 163, 0.4) !important;
            box-shadow: 0 6px 16px rgba(42, 181, 163, 0.15);
        }
        .slot-badge {
            font-size: 0.8rem;
            font-weight: 600;
            background-color: rgba(42, 181, 163, 0.15) !important;
            color: #2AB5A3 !important;
            border: 1px solid rgba(42, 181, 163, 0.3) !important;
        }
        .text-xs {
            font-size: 0.72rem;
        }
    </style>
</head>
<body class="doctor-app master-ui-body master-ui-dark">
<c:set var="activeDoctorPage" value="schedule" />
<%@ include file="/WEB-INF/views/components/doctor/sidebar.jspf" %>

<main class="doctor-main">
    <!-- Alert Messages -->
    <c:if test="${not empty sessionScope.successMsg}">
        <div class="alert alert-success alert-dismissible fade show mx-4 mt-3" role="alert" style="background-color: rgba(42, 181, 163, 0.15); border-color: rgba(42, 181, 163, 0.3); color: #2AB5A3;">
            <i class="bi bi-check-circle-fill me-2"></i> ${sessionScope.successMsg}
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
        <c:remove var="successMsg" scope="session" />
    </c:if>
    <c:if test="${not empty sessionScope.errorMsg}">
        <div class="alert alert-danger alert-dismissible fade show mx-4 mt-3" role="alert" style="background-color: rgba(239, 68, 68, 0.15); border-color: rgba(239, 68, 68, 0.3); color: #f87171;">
            <i class="bi bi-exclamation-triangle-fill me-2"></i> ${sessionScope.errorMsg}
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
        <c:remove var="errorMsg" scope="session" />
    </c:if>

    <!-- Doctor Action Bar -->
    <div class="d-flex justify-content-between align-items-center mb-4 px-2">
        <div>
            <h1 class="h3 text-white fw-bold mb-1">Lịch trực bác sĩ</h1>
            <p class="text-white-50 small mb-0">Quản lý ca trực lâm sàng và gửi yêu cầu đăng ký lịch trực mới với Admin.</p>
        </div>
        <button type="button" class="master-btn-primary" data-bs-toggle="modal" data-bs-target="#proposeScheduleModal">
            <i class="bi bi-plus-lg me-1"></i> Đăng ký ca trực mới
        </button>
    </div>

    <!-- Shared Master Duty Schedule Grid Component -->
    <%@ include file="/WEB-INF/views/components/shared/duty-schedule-grid.jspf" %>
</main>

<!-- Modal Đăng Ký Ca Trực Bác Sĩ -->
<div class="modal fade" id="proposeScheduleModal" tabindex="-1" aria-labelledby="proposeScheduleModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content master-panel-card p-2" style="background: #0F172A; border: 1px solid rgba(255, 255, 255, 0.12);">
            <div class="modal-header border-bottom border-secondary border-opacity-10 pb-3">
                <h5 class="modal-title text-white fw-bold" id="proposeScheduleModalLabel">
                    <i class="bi bi-calendar-plus text-teal me-2" style="color: #2AB5A3;"></i>Đăng Ký Ca Trực Mới
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form action="${pageContext.request.contextPath}/doctor/schedule" method="POST">
                <div class="modal-body py-4">
                    <!-- Ngày trực -->
                    <div class="mb-3">
                        <label class="master-form-label" for="workDate">NGÀY LÀM VIỆC</label>
                        <div class="master-input-group">
                            <span class="input-group-text"><i class="bi bi-calendar-event"></i></span>
                            <input type="date" class="form-control" id="workDate" name="workDate" required />
                        </div>
                    </div>

                    <!-- Ca trực -->
                    <div class="mb-3">
                        <label class="master-form-label" for="timeSlot">CA TRỰC / KHUNG GIỜ</label>
                        <div class="master-input-group">
                            <span class="input-group-text"><i class="bi bi-clock"></i></span>
                            <select class="form-select" id="timeSlot" name="timeSlot" required>
                                <option value="Ca 1">Ca 1 (Sáng: 07:30 - 12:00)</option>
                                <option value="Ca 2">Ca 2 (Chiều: 13:30 - 16:30)</option>
                            </select>
                        </div>
                    </div>

                    <!-- Số bệnh nhân tối đa -->
                    <div class="mb-3">
                        <label class="master-form-label" for="maxPatients">SỐ BỆNH NHÂN TỐI ĐA</label>
                        <div class="master-input-group">
                            <span class="input-group-text"><i class="bi bi-person-bounding-box"></i></span>
                            <input type="number" class="form-control" id="maxPatients" name="maxPatients" value="15" min="1" max="50" required />
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top border-secondary border-opacity-10 pt-3">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4" data-bs-dismiss="modal">Hủy</button>
                    <button type="submit" class="master-btn-primary px-4">Gửi Yêu Cầu</button>
                </div>
            </form>
        </div>
    </div>
</div>
<script src="${pageContext.request.contextPath}/assets/js/core/duty-schedule-shared.js"></script>

<script>
const schedules = [
    <c:forEach var="s" items="${schedules}" varStatus="loop">
        {
            workDate: "${s.workDate}",
            timeSlot: "${s.timeSlot}",
            roomName: "${s.roomName}",
            roomId: "${s.roomId}",
            maxPatients: ${empty s.maxPatients ? 0 : s.maxPatients},
            bookedPatients: ${empty s.bookedPatients ? 0 : s.bookedPatients},
            status: "${s.status}"
        }${!loop.last ? ',' : ''}
    </c:forEach>
];

function parseLocalDate(dateStr) {
    if (!dateStr || typeof dateStr !== 'string' || !dateStr.includes('-')) return new Date();
    const parts = dateStr.trim().split('-');
    const y = parseInt(parts[0], 10);
    const m = parseInt(parts[1], 10) - 1;
    const d = parseInt(parts[2], 10);
    if (isNaN(y) || isNaN(m) || isNaN(d)) return new Date();
    return new Date(y, m, d);
}

function formatDateLocal(dateObj) {
    if (!(dateObj instanceof Date) || isNaN(dateObj.getTime())) return '';
    const y = dateObj.getFullYear();
    const m = String(dateObj.getMonth() + 1).padStart(2, '0');
    const d = String(dateObj.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + d;
}

function formatDateShort(dateObj) {
    if (!(dateObj instanceof Date) || isNaN(dateObj.getTime())) return '';
    const d = String(dateObj.getDate()).padStart(2, '0');
    const m = String(dateObj.getMonth() + 1).padStart(2, '0');
    return d + '/' + m;
}

function getMonday(d) {
    const date = new Date(d);
    const day = date.getDay();
    const diff = date.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(date.setDate(diff));
}

function populateYearSelect() {
    const select = document.getElementById("dutyYearSelect") || document.getElementById("yearSelect");
    if (!select) return;
    
    const currentYear = new Date().getFullYear();
    let minYear = currentYear - 1;
    let maxYear = currentYear + 1;
    
    if (typeof schedules !== 'undefined' && Array.isArray(schedules)) {
        schedules.forEach(s => {
            if (s && s.workDate) {
                const y = parseInt(String(s.workDate).split('-')[0], 10);
                if (!isNaN(y)) {
                    if (y < minYear) minYear = y;
                    if (y > maxYear) maxYear = y;
                }
            }
        });
    }
    
    select.innerHTML = "";
    for (let y = minYear; y <= maxYear; y++) {
        const option = document.createElement("option");
        option.value = y;
        option.textContent = "Năm " + y;
        if (y === currentYear) {
            option.selected = true;
        }
        select.appendChild(option);
    }
}

function generateWeekOptions() {
    const select = document.getElementById("dutyWeekSelect") || document.getElementById("weekSelect");
    if (!select) return;
    select.innerHTML = "";
    const yearSelect = document.getElementById("dutyYearSelect") || document.getElementById("yearSelect");
    const selectedYear = yearSelect && yearSelect.value ? parseInt(yearSelect.value, 10) : new Date().getFullYear();
    const today = new Date();
    let tempDate = new Date(selectedYear, 0, 1);
    let firstMonday = getMonday(tempDate);
    let current = new Date(firstMonday);
    let weekIndex = 1;
    while (current.getFullYear() <= selectedYear || weekIndex <= 52) {
        if (current.getFullYear() > selectedYear + 1) break;
        const monday = new Date(current);
        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);
        const option = document.createElement("option");
        option.value = formatDateLocal(monday);
        option.textContent = "Tuần " + String(weekIndex).padStart(2, '0') + " [" + formatDateShort(monday) + " - " + formatDateShort(sunday) + "]";
        if (selectedYear === today.getFullYear()) {
            const todayStr = formatDateLocal(today);
            if (todayStr >= formatDateLocal(monday) && todayStr <= formatDateLocal(sunday)) {
                option.selected = true;
            }
        } else if (weekIndex === 1) {
            option.selected = true;
        }
        select.appendChild(option);
        current.setDate(current.getDate() + 7);
        weekIndex++;
        if (weekIndex > 53) break;
    }
}

function getStandardShift(dbTimeSlot) {
    if (!dbTimeSlot) return "7:30 - 12:00";
    const timeStr = dbTimeSlot.toLowerCase().trim();
    if (timeStr.includes("ca 2") || timeStr.includes("chiều") || timeStr.includes("chieu") || timeStr.includes("afternoon")) {
        return "13:30 - 16:30";
    }
    if (timeStr.includes("ca 1") || timeStr.includes("sáng") || timeStr.includes("sang") || timeStr.includes("morning")) {
        return "7:30 - 12:00";
    }
    const match = timeStr.replace(/\s/g, '').match(/^(\d{1,2})[\:\s\-\_]/);
    if (match) {
        const startHour = parseInt(match[1], 10);
        return startHour >= 12 ? "13:30 - 16:30" : "7:30 - 12:00";
    }
    return "7:30 - 12:00";
}

function renderScheduleGrid() {
    const weekSelect = document.getElementById("dutyWeekSelect") || document.getElementById("weekSelect");
    const mondayStr = weekSelect ? weekSelect.value : '';
    if (!mondayStr) return;
    const mondayDate = parseLocalDate(mondayStr);
    const headerRow = document.getElementById("dutyGridHeaderRow") || document.getElementById("headerRow");
    if (headerRow) {
        headerRow.innerHTML = '<th style="width: 140px; color: #2AB5A3; background-color: rgba(30, 41, 59, 0.8) !important;" class="text-start ps-3">Khung Giờ</th>';
        const dayNames = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"];
        for (let i = 0; i < 7; i++) {
            const current = new Date(mondayDate);
            current.setDate(mondayDate.getDate() + i);
            headerRow.innerHTML += '<th style="min-width: 130px; background-color: rgba(30, 41, 59, 0.8) !important;"><div>' + dayNames[i] + '</div><div class="fw-normal text-white-50 small mt-0.5">' + formatDateShort(current) + '</div></th>';
        }
    }
    
    const weekDates = [];
    for (let i = 0; i < 7; i++) {
        const current = new Date(mondayDate);
        current.setDate(mondayDate.getDate() + i);
        weekDates.push(current);
    }
    
    const weekStart = new Date(mondayDate);
    const weekEnd = new Date(mondayDate);
    weekEnd.setDate(mondayDate.getDate() + 6);
    const weekSchedules = (typeof schedules !== 'undefined' && Array.isArray(schedules)) 
        ? schedules.filter(s => s && s.workDate >= formatDateLocal(weekStart) && s.workDate <= formatDateLocal(weekEnd))
        : [];
        
    const timeSlots = ["7:30 - 12:00", "13:30 - 16:30"];
    const tbody = document.getElementById("dutyGridBody") || document.getElementById("gridBody");
    if (!tbody) return;
    tbody.innerHTML = "";
    const todayStr = formatDateLocal(new Date());
    
    timeSlots.forEach((slot, index) => {
        let rowHtml = '<tr>' +
            '<td class="fw-semibold text-nowrap text-center py-4" style="width: 140px; background: rgba(15, 23, 42, 0.6); color: #cbd5e1; border-color: rgba(255,255,255,0.06);">' +
                '<div class="small text-secondary mb-1" style="color: #94a3b8 !important;">Ca ' + (index + 1) + '</div>' +
                '<span class="badge slot-badge">' + slot + '</span>' +
            '</td>';
        for (let i = 0; i < 7; i++) {
            const dateStr = formatDateLocal(weekDates[i]);
            const matchedSchedules = weekSchedules.filter(s => s.workDate === dateStr && getStandardShift(s.timeSlot) === slot);
            if (matchedSchedules.length > 0) {
                let cellHtml = '<td class="p-2 align-top" style="background-color: transparent; border-color: rgba(255,255,255,0.06);"><div class="d-flex flex-column gap-2">';
                matchedSchedules.forEach(matched => {
                    let badgeClass = "bg-success-subtle text-success";
                    let statusText = "Sẵn sàng";
                    const isPast = matched.workDate < todayStr;
                    const st = (matched.status || '').toLowerCase().trim();
                    if (st === "full") { badgeClass = "bg-danger-subtle text-danger"; statusText = "Đầy lịch"; }
                    else if (st === "expired" || st === "completed" || isPast) { badgeClass = "bg-secondary-subtle text-secondary"; statusText = "Hoàn thành"; }
                    else if (st === "pending") { badgeClass = "bg-warning-subtle text-warning"; statusText = "Chờ duyệt"; }
                    else if (st === "cancelled") { badgeClass = "bg-danger-subtle text-danger"; statusText = "Đã hủy"; }
                    const roomDisplayName = matched.roomName ? matched.roomName : (matched.roomId ? ('Phòng ' + matched.roomId) : 'Phòng khám');
                    cellHtml += '<div class="schedule-cell-card p-2 text-start w-100 shadow-xs">' +
                        '<div class="small mb-1" style="font-size: 0.78rem; color: #94a3b8;"><span class="fw-semibold" style="color: #ffffff;"><i class="bi bi-clock me-1" style="color: #2AB5A3;"></i>' + matched.timeSlot + '</span></div>' +
                        '<div class="small text-secondary mb-1" style="font-size: 0.72rem; color: #38bdf8 !important;"><i class="bi bi-door-open me-1"></i>' + roomDisplayName + '</div>' +
                        '<div class="d-flex align-items-center justify-content-between pt-1 border-top" style="border-top-style: dashed !important; border-top-color: rgba(255,255,255,0.1) !important;"><span class="badge ' + badgeClass + ' text-xs py-0.5 px-1">' + statusText + '</span><span class="fw-semibold text-xs" style="color: #94a3b8;"><i class="bi bi-people me-1"></i>' + (matched.bookedPatients || 0) + '/' + (matched.maxPatients || 0) + '</span></div></div>';
                });
                cellHtml += '</div></td>';
                rowHtml += cellHtml;
            } else {
                rowHtml += '<td class="text-center opacity-25 py-4" style="color: #94a3b8; border-color: rgba(255,255,255,0.06);">-</td>';
            }
        }
        rowHtml += '</tr>';
        tbody.innerHTML += rowHtml;
    });
}

document.addEventListener("DOMContentLoaded", () => {
    populateYearSelect();
    generateWeekOptions();
    renderScheduleGrid();

    const workDateInput = document.getElementById("workDate");
    if (workDateInput) {
        const todayStr = new Date().toISOString().split('T')[0];
        workDateInput.min = todayStr;
        workDateInput.addEventListener("change", () => {
            if (workDateInput.value && workDateInput.value < todayStr) {
                alert("Ngày làm việc không được chọn ngày đã qua!");
                workDateInput.value = todayStr;
            }
        });
    }
});
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
