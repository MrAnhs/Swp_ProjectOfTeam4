<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lịch trực bác sĩ - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css?v=20260721-ui2" rel="stylesheet">
    <style>
        .doctor-table thead th.grid-header-cell {
            background: #E8F7F4 !important;
            border: 1px solid #D0EFE8 !important;
            border-bottom: 3px solid #00C8A5 !important;
            color: #005C47 !important;
            text-align: center;
            padding: 14px 8px !important;
        }
        .schedule-cell-card {
            border-left: 4px solid #00C8A5 !important;
            border-top: 1px solid #e2e8f0 !important;
            border-right: 1px solid #e2e8f0 !important;
            border-bottom: 1px solid #e2e8f0 !important;
            border-radius: 12px;
            background-color: #ffffff !important;
            color: #1a202c !important;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.05);
            transition: all 0.2s ease;
        }
        .schedule-cell-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(0, 200, 165, 0.2);
            border-top-color: #00C8A5 !important;
            border-right-color: #00C8A5 !important;
            border-bottom-color: #00C8A5 !important;
        }
        .slot-badge {
            font-size: 0.8rem;
            font-weight: 700;
            background-color: #ffffff !important;
            color: #007f61 !important;
            border: 1px solid #00C8A5 !important;
            border-radius: 20px !important;
            padding: 4px 10px !important;
            box-shadow: 0 2px 6px rgba(0, 200, 165, 0.15);
        }
        .text-xs {
            font-size: 0.73rem;
        }
    </style>
</head>
<body class="doctor-app">
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

    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small">LỊCH LÀM VIỆC LÂM SÀNG</div>
                <h1 class="doctor-title h3 mb-1">Lịch trực của tôi</h1>
                <p class="doctor-muted mb-0">Xem danh sách phân công lịch trực theo từng tuần.</p>
            </div>
            
            <!-- Filter Dropdowns -->
            <div class="d-flex align-items-center gap-2">
                <div class="d-flex align-items-center gap-1">
                    <label class="fw-bold text-uppercase small m-0 text-secondary" for="yearSelect">Năm</label>
                    <select id="yearSelect" class="form-select form-select-sm doctor-filter" style="width: 95px;" onchange="generateWeekOptions(); renderScheduleGrid();">
                    </select>
                </div>
                <div class="d-flex align-items-center gap-1">
                    <label class="fw-bold text-uppercase small m-0 text-secondary" for="weekSelect">Tuần</label>
                    <select id="weekSelect" class="form-select form-select-sm doctor-filter" style="width: 260px;" onchange="renderScheduleGrid();">
                    </select>
                </div>
            </div>
        </div>
    </section>

    <!-- Schedule Grid Table -->
    <div class="doctor-card p-0 overflow-hidden shadow-sm" style="border-radius: 18px;">
        <div class="table-responsive">
            <table class="table doctor-table m-0">
                <thead>
                    <tr id="headerRow">
                        <th class="grid-header-cell" style="width: 140px;">Khung giờ</th>
                    </tr>
                </thead>
                <tbody id="gridBody">
                </tbody>
            </table>
        </div>
    </div>
</main>

<script>
const schedules = [
    <c:forEach var="s" items="${schedules}" varStatus="loop">
        {
            workDate: '${s.workDate != null ? s.workDate : ""}',
            timeSlot: '${s.timeSlot != null ? s.timeSlot : ""}',
            roomName: '${s.roomName != null ? s.roomName : ""}',
            roomId: '${s.roomId != null ? s.roomId : ""}',
            maxPatients: ${not empty s.maxPatients ? s.maxPatients : 0},
            bookedPatients: ${not empty s.bookedPatients ? s.bookedPatients : 0},
            status: '${s.status != null ? s.status : ""}'
        }${!loop.last ? ',' : ''}
    </c:forEach>
];

function parseLocalDate(dateStr) {
    if (!dateStr) return new Date();
    const parts = dateStr.split('-');
    return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
}

function formatDateLocal(dateObj) {
    const y = dateObj.getFullYear();
    const m = String(dateObj.getMonth() + 1).padStart(2, '0');
    const d = String(dateObj.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + d;
}

function formatDateShort(dateObj) {
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
    const select = document.getElementById("yearSelect");
    if (!select) return;
    
    const currentYear = new Date().getFullYear();
    let minYear = currentYear - 1;
    let maxYear = currentYear + 1;
    
    if (typeof schedules !== 'undefined' && Array.isArray(schedules)) {
        schedules.forEach(s => {
            if (s.workDate) {
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
        option.textContent = y;
        if (y === currentYear) {
            option.selected = true;
        }
        select.appendChild(option);
    }
}

function generateWeekOptions() {
    const select = document.getElementById("weekSelect");
    if (!select) return;
    select.innerHTML = "";
    const yearSelect = document.getElementById("yearSelect");
    const selectedYear = yearSelect ? parseInt(yearSelect.value) : new Date().getFullYear();
    const today = new Date();
    let tempDate = new Date(selectedYear, 0, 1);
    let firstMonday = getMonday(tempDate);
    let current = new Date(firstMonday);
    let weekIndex = 1;
    while (current.getFullYear() <= selectedYear) {
        const monday = new Date(current);
        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);
        const option = document.createElement("option");
        option.value = formatDateLocal(monday);
        option.textContent = "Tuần " + String(weekIndex).padStart(2, '0') + " (" + formatDateShort(monday) + " - " + formatDateShort(sunday) + ")";
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
    const mondayStr = document.getElementById("weekSelect").value;
    if (!mondayStr) return;
    const mondayDate = parseLocalDate(mondayStr);
    const headerRow = document.getElementById("headerRow");
    headerRow.innerHTML = '<th class="grid-header-cell" style="width: 140px; color: #005C47 !important; font-weight: 800; font-size: 0.88rem;">KHUNG GIỜ</th>';
    const weekDates = [];
    const dayNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    for (let i = 0; i < 7; i++) {
        const current = new Date(mondayDate);
        current.setDate(mondayDate.getDate() + i);
        weekDates.push(current);
        headerRow.innerHTML += '<th class="grid-header-cell" style="min-width: 130px;"><div style="color: #005C47 !important; font-weight: 800; font-size: 0.88rem; letter-spacing: 0.05em;">' + dayNames[i] + '</div><div style="color: #007F61 !important; font-weight: 700; font-size: 0.78rem; margin-top: 2px;">' + formatDateShort(current) + '</div></th>';
    }
    const weekStart = new Date(mondayDate);
    const weekEnd = new Date(mondayDate);
    weekEnd.setDate(mondayDate.getDate() + 6);
    const weekSchedules = schedules.filter(s => s.workDate >= formatDateLocal(weekStart) && s.workDate <= formatDateLocal(weekEnd));
    const timeSlots = ["7:30 - 12:00", "13:30 - 16:30"];
    const tbody = document.getElementById("gridBody");
    tbody.innerHTML = "";
    const todayStr = formatDateLocal(new Date());
    timeSlots.forEach((slot, index) => {
        let rowHtml = '<tr>' +
            '<td class="fw-bold text-nowrap text-center py-4" style="width: 140px; background: #f1f8f6; border-right: 2px solid #00C8A5; border-bottom: 1px solid #e2e8f0;">' +
                '<div class="fw-extrabold mb-1.5" style="color: #007f61; font-size: 0.9rem;">Ca ' + (index + 1) + '</div>' +
                '<span class="badge slot-badge">' + slot + '</span>' +
            '</td>';
        for (let i = 0; i < 7; i++) {
            const dateStr = formatDateLocal(weekDates[i]);
            const matchedSchedules = weekSchedules.filter(s => s.workDate === dateStr && getStandardShift(s.timeSlot) === slot);
            if (matchedSchedules.length > 0) {
                let cellHtml = '<td class="p-2 align-top" style="background-color: #fafbfc; border-bottom: 1px solid #e2e8f0;"><div class="d-flex flex-column gap-2">';
                matchedSchedules.forEach(matched => {
                    let badgeClass = "bg-success text-white";
                    let statusText = "Sẵn sàng";
                    const isPast = matched.workDate < todayStr;
                    const st = (matched.status || '').toLowerCase().trim();
                    if (st === "full") { badgeClass = "bg-danger text-white"; statusText = "Đầy lịch"; }
                    else if (st === "expired" || st === "completed" || isPast) { badgeClass = "bg-secondary text-white"; statusText = "Hoàn thành"; }
                    else if (st === "pending") { badgeClass = "bg-warning text-dark"; statusText = "Chờ duyệt"; }
                    else if (st === "cancelled") { badgeClass = "bg-danger text-white"; statusText = "Đã hủy"; }
                    const roomDisplayName = matched.roomName ? matched.roomName : (matched.roomId ? ('Phòng ' + matched.roomId) : 'Phòng khám');
                    cellHtml += '<div class="schedule-cell-card p-2 text-start w-100">' +
                        '<div class="d-flex align-items-center justify-content-between mb-1" style="font-size: 0.8rem;"><span class="fw-bold text-dark"><i class="bi bi-clock-fill me-1" style="color: #00C8A5;"></i>' + matched.timeSlot + '</span></div>' +
                        '<div class="mb-2" style="font-size: 0.73rem;"><span style="background: rgba(2, 132, 199, 0.12); color: #0284c7; padding: 2px 7px; border-radius: 6px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;"><i class="bi bi-door-open-fill"></i>' + roomDisplayName + '</span></div>' +
                        '<div class="d-flex align-items-center justify-content-between pt-1.5 border-top" style="border-top-style: dashed !important; border-top-color: #e2e8f0 !important;"><span class="badge ' + badgeClass + ' text-xs py-1 px-2 fw-bold" style="border-radius: 6px;">' + statusText + '</span><span class="fw-bold text-xs" style="color: #475569;"><i class="bi bi-people-fill me-1" style="color: #00C8A5;"></i>' + matched.bookedPatients + '/' + matched.maxPatients + '</span></div></div>';
                });
                cellHtml += '</div></td>';
                rowHtml += cellHtml;
            } else {
                rowHtml += '<td class="text-center py-4" style="color: #cbd5e1; border-bottom: 1px solid #e2e8f0; font-weight: 600;">-</td>';
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
});
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
