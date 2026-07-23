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
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <div class="doctor-profile-card">
        <div class="doctor-avatar">
            <c:choose>
                <c:when test="${not empty sessionScope.currentUser.fullName}">
                    <c:out value="${sessionScope.currentUser.fullName.substring(0, 1)}" />
                </c:when>
                <c:otherwise>D</c:otherwise>
            </c:choose>
        </div>
        <div class="doctor-info">
            <div class="doctor-name" title="<c:out value='${sessionScope.currentUser.fullName}' />">
                <c:out value="${sessionScope.currentUser.fullName}" default="Bác sĩ" />
            </div>
            <div class="doctor-role-tag">Bác sĩ</div>
        </div>
        <a href="${pageContext.request.contextPath}/settings" class="doctor-edit-profile-btn" title="Chỉnh sửa hồ sơ">
            <i class="bi bi-pencil-square"></i>
        </a>
    </div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/doctor/dashboard"><i class="bi bi-grid"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/doctor/general-examinations"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/doctor/laboratory-requests"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/doctor/examinations"><i class="bi bi-clipboard2-pulse"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/doctor/completed-records"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/doctor/patients/search"><i class="bi bi-search"></i> Tra cứu</a>
        <a class="active" href="${pageContext.request.contextPath}/doctor/schedule"><i class="bi bi-calendar3"></i> Lịch trực</a>
        <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

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
                    <label class="fw-bold text-uppercase small m-0" style="color: #cbd5e1;" for="yearSelect">Năm</label>
                    <select id="yearSelect" class="form-select form-select-sm doctor-filter" style="width: 90px;" onchange="generateWeekOptions(); renderScheduleGrid();">
                    </select>
                </div>
                <div class="d-flex align-items-center gap-1">
                    <label class="fw-bold text-uppercase small m-0" style="color: #cbd5e1;" for="weekSelect">Tuần</label>
                    <select id="weekSelect" class="form-select form-select-sm doctor-filter" style="width: 250px;" onchange="renderScheduleGrid();">
                    </select>
                </div>
            </div>
        </div>
    </section>

    <!-- Schedule Grid Table -->
    <div class="doctor-card p-0 overflow-hidden">
        <div class="table-responsive">
            <table class="table doctor-table m-0">
                <thead>
                    <tr id="headerRow">
                        <th class="grid-header-cell" style="width: 140px; background-color: #0F172A !important;">Khung giờ</th>
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
    select.innerHTML = "";
    
    for (let y = currentYear - 1; y <= currentYear + 1; y++) {
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
    if (!dbTimeSlot) return null;
    const timeStr = dbTimeSlot.toLowerCase().replace(/\s/g, '');
    const match = timeStr.match(/^(\d{1,2})[\:\s\-\_]/);
    if (match) {
        const startHour = parseInt(match[1]);
        return startHour < 12 ? "7:30 - 12:00" : "13:30 - 16:30";
    }
    return timeStr.includes("12:") || timeStr.includes("13:") || timeStr.includes("14:") || timeStr.includes("15:") || timeStr.includes("16:") || timeStr.includes("17:") || timeStr.includes("18:") ? "13:30 - 16:30" : "7:30 - 12:00";
}

function renderScheduleGrid() {
    const mondayStr = document.getElementById("weekSelect").value;
    if (!mondayStr) return;
    const mondayDate = parseLocalDate(mondayStr);
    const headerRow = document.getElementById("headerRow");
    headerRow.innerHTML = '<th class="grid-header-cell" style="width: 140px; background-color: #0F172A !important;">Khung giờ</th>';
    const weekDates = [];
    const dayNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    for (let i = 0; i < 7; i++) {
        const current = new Date(mondayDate);
        current.setDate(mondayDate.getDate() + i);
        weekDates.push(current);
        headerRow.innerHTML += '<th class="grid-header-cell" style="min-width: 130px;"><div>' + dayNames[i] + '</div><div class="fw-normal text-xs opacity-75 mt-0.5">' + formatDateShort(current) + '</div></th>';
    }
    const weekStart = new Date(mondayDate);
    const weekEnd = new Date(mondayDate);
    weekEnd.setDate(mondayDate.getDate() + 6);
    const weekSchedules = schedules.filter(s => s.workDate >= formatDateLocal(weekStart) && s.workDate <= formatDateLocal(weekEnd));
    const timeSlots = ["7:30 - 12:00", "13:30 - 16:30"];
    const tbody = document.getElementById("gridBody");
    tbody.innerHTML = "";
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
                    if (matched.status === "Full" || matched.status === "full") { badgeClass = "bg-danger-subtle text-danger"; statusText = "Đầy lịch"; }
                    else if (matched.status === "Expired" || matched.status === "expired") { badgeClass = "bg-secondary-subtle text-secondary"; statusText = "Đã qua"; }
                    else if (matched.status === "Pending" || matched.status === "pending") { badgeClass = "bg-warning-subtle text-warning"; statusText = "Chờ duyệt"; }
                    else if (matched.status === "Cancelled" || matched.status === "cancelled") { badgeClass = "bg-danger-subtle text-danger"; statusText = "Đã hủy"; }
                    cellHtml += '<div class="schedule-cell-card p-2 text-start w-100 shadow-xs">' +
                        '<div class="fw-bold mb-0.5" style="font-size: 0.82rem; color: #2AB5A3;">' + (matched.roomName || 'Phòng khám') + '</div>' +
                        '<div class="small mb-1" style="font-size: 0.7rem; color: #94a3b8;"><span class="fw-semibold me-1" style="color: #ffffff;"><i class="bi bi-clock me-0.5" style="color: #2AB5A3;"></i>' + matched.timeSlot + '</span><span>(' + (matched.roomId || '-') + ')</span></div>' +
                        '<div class="d-flex align-items-center justify-content-between pt-1 border-top" style="border-top-style: dashed !important; border-top-color: rgba(255,255,255,0.1) !important;"><span class="badge ' + badgeClass + ' text-xs py-0.5 px-1">' + statusText + '</span><span class="fw-semibold text-xs" style="color: #94a3b8;"><i class="bi bi-people me-1"></i>' + matched.bookedPatients + '/' + matched.maxPatients + '</span></div></div>';
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
    
    const startDateInput = document.getElementById("startDateInput");
    const endDateInput = document.getElementById("endDateInput");
    if (startDateInput && endDateInput) {
        const todayStr = new Date().toISOString().split('T')[0];
        startDateInput.min = todayStr;
        endDateInput.min = todayStr;
        
        startDateInput.addEventListener("change", () => {
            endDateInput.min = startDateInput.value;
            if (endDateInput.value && endDateInput.value < startDateInput.value) {
                endDateInput.value = startDateInput.value;
            }
        });
    }

    const form = document.querySelector("#proposeScheduleModal form");
    if (form) {
        form.addEventListener("submit", function(e) {
            const checked = form.querySelectorAll('input[name="timeSlots"]:checked');
            if (checked.length === 0) {
                alert("Vui lòng chọn ít nhất một ca trực.");
                e.preventDefault();
                return false;
            }
            const startVal = startDateInput.value;
            const endVal = endDateInput.value;
            if (startVal && endVal && endVal < startVal) {
                alert("Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu.");
                e.preventDefault();
                return false;
            }
        });
    }
});
</script>



<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
