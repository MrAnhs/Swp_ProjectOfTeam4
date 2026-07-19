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
    <link href="${pageContext.request.contextPath}/assets/css/pages/doctor/doctor.css" rel="stylesheet">
    <style>
        .grid-header-cell {
            background-color: #007f61 !important;
            color: #ffffff !important;
            text-align: center;
            font-weight: 600;
        }
        .schedule-cell-card {
            border: 1px solid rgba(0, 127, 97, 0.12);
            border-radius: 8px;
            background-color: #ffffff;
            transition: all 0.2s ease;
        }
        .schedule-cell-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0, 127, 97, 0.08);
        }
        .slot-badge {
            font-size: 0.8rem;
            font-weight: 500;
        }
        .text-xs {
            font-size: 0.72rem;
        }
    </style>
</head>
<body class="doctor-app">
<aside class="doctor-sidebar">
    <div class="doctor-brand"><span class="doctor-brand-icon"><i class="bi bi-heart-pulse"></i></span> Cổng bác sĩ</div>
    <nav class="doctor-nav">
        <a href="${pageContext.request.contextPath}/doctor/dashboard"><i class="bi bi-grid"></i> Tiếp nhận hồ sơ</a>
        <a href="${pageContext.request.contextPath}/doctor/general-examinations"><i class="bi bi-person-vcard"></i> Khám tổng quát</a>
        <a href="${pageContext.request.contextPath}/doctor/laboratory-requests"><i class="bi bi-eyedropper"></i> Xét nghiệm</a>
        <a href="${pageContext.request.contextPath}/doctor/examinations"><i class="bi bi-clipboard2-pulse"></i> Khám chi tiết</a>
        <a href="${pageContext.request.contextPath}/doctor/completed-records"><i class="bi bi-archive"></i> Đã hoàn thành</a>
        <a href="${pageContext.request.contextPath}/doctor/patients/search"><i class="bi bi-search"></i> Tra cứu</a>
        <a class="active" href="${pageContext.request.contextPath}/doctor/schedule"><i class="bi bi-calendar3"></i> Lịch trực</a>
        <a href="${pageContext.request.contextPath}/settings"><i class="bi bi-gear"></i> Cài đặt</a>
        <a class="text-danger mt-lg-4" href="${pageContext.request.contextPath}/logout"><i class="bi bi-box-arrow-right"></i> Đăng xuất</a>
    </nav>
</aside>

<main class="doctor-main">
    <section class="doctor-topbar mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div>
                <div class="doctor-muted small">LỊCH LÀM VIỆC LÂM SÀNG</div>
                <h1 class="doctor-title h3 mb-1">Lịch trực của tôi</h1>
                <p class="doctor-muted mb-0">Xem danh sách phân công lịch trực theo từng tuần giống định dạng FAP.</p>
            </div>
            
            <!-- Filter Dropdowns -->
            <div class="d-flex align-items-center gap-2">
                <div class="d-flex align-items-center gap-1">
                    <label class="fw-bold text-secondary text-uppercase small m-0" for="yearSelect">Năm</label>
                    <select id="yearSelect" class="form-select form-select-sm" style="width: 90px;">
                        <option value="2026" selected>2026</option>
                        <option value="2027">2027</option>
                    </select>
                </div>
                <div class="d-flex align-items-center gap-1">
                    <label class="fw-bold text-secondary text-uppercase small m-0" for="weekSelect">Tuần</label>
                    <select id="weekSelect" class="form-select form-select-sm" style="min-width: 180px;" onchange="renderScheduleGrid()">
                        <!-- Options generated dynamically -->
                    </select>
                </div>
            </div>
        </div>
    </section>

    <section class="doctor-card p-3">
        <div class="table-responsive">
            <table class="table table-bordered align-middle mb-0">
                <thead>
                    <tr id="headerRow">
                        <!-- MON to SUN headers with date values populated dynamically -->
                    </tr>
                </thead>
                <tbody id="gridBody">
                    <!-- Dynamic Grid Rows -->
                </tbody>
            </table>
        </div>
    </section>
</main>

<script>
// Serialize database schedules from controller
const schedules = [
    <c:forEach var="s" items="${schedules}" varStatus="loop">
        {
            workDate: '<fmt:formatDate value="${s.workDate}" pattern="yyyy-MM-dd"/>',
            workDateDisplay: '<fmt:formatDate value="${s.workDate}" pattern="dd/MM/yyyy"/>',
            timeSlot: '${s.timeSlot}',
            roomName: '${s.roomName}',
            roomId: '${s.roomId}',
            maxPatients: ${not empty s.maxPatients ? s.maxPatients : 0},
            bookedPatients: ${not empty s.bookedPatients ? s.bookedPatients : 0},
            status: '${s.status}'
        }${!loop.last ? ',' : ''}
    </c:forEach>
];

function getMonday(d) {
    d = new Date(d);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(d.setDate(diff));
}

function formatDateShort(date) {
    const dd = String(date.getDate()).padStart(2, '0');
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    return dd + "/" + mm;
}

function generateWeekOptions() {
    const select = document.getElementById("weekSelect");
    if (!select) return;
    
    const today = new Date();
    const currentWeekStart = getMonday(today);
    
    // Generate 4 weeks in the past to 4 weeks in the future
    for (let i = -4; i <= 4; i++) {
        const monday = new Date(currentWeekStart);
        monday.setDate(currentWeekStart.getDate() + (i * 7));
        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);
        
        const option = document.createElement("option");
        option.value = monday.toISOString().split('T')[0];
        
        const formatStr = formatDateShort(monday) + " To " + formatDateShort(sunday);
        option.textContent = formatStr;
        
        if (i === 0) {
            option.selected = true;
        }
        select.appendChild(option);
    }
}

function getStandardShift(dbTimeSlot) {
    if (!dbTimeSlot) return null;
    const timeStr = dbTimeSlot.toLowerCase().replace(/\s/g, '');
    
    const match = timeStr.match(/^(\d{1,2})[\:\s\-\_]/);
    if (match) {
        const startHour = parseInt(match[1]);
        if (startHour < 12) {
            return "7:30 - 12:00";
        } else {
            return "13:30 - 16:30";
        }
    }
    
    if (timeStr.includes("12:") || timeStr.includes("13:") || timeStr.includes("14:") || timeStr.includes("15:") || timeStr.includes("16:") || timeStr.includes("17:") || timeStr.includes("18:")) {
        return "13:30 - 16:30";
    }
    return "7:30 - 12:00";
}

function renderScheduleGrid() {
    const mondayStr = document.getElementById("weekSelect").value;
    const mondayDate = new Date(mondayStr);
    
    // Update headers with actual dates
    const headerRow = document.getElementById("headerRow");
    headerRow.innerHTML = `<th class="grid-header-cell" style="width: 140px; background-color: #0d5f49 !important;">Khung giờ</th>`;
    
    const weekDates = [];
    const dayNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    
    for (let i = 0; i < 7; i++) {
        const current = new Date(mondayDate);
        current.setDate(mondayDate.getDate() + i);
        weekDates.push(current);
        
        const dateStr = formatDateShort(current);
        headerRow.innerHTML += `<th class="grid-header-cell" style="min-width: 130px;">
            <div>${dayNames[i]}</div>
            <div class="fw-normal text-xs opacity-75 mt-0.5">${dateStr}</div>
        </th>`;
    }
    
    // Filter schedules for this week
    const weekStart = new Date(mondayDate);
    weekStart.setHours(0,0,0,0);
    const weekEnd = new Date(mondayDate);
    weekEnd.setDate(mondayDate.getDate() + 6);
    weekEnd.setHours(23,59,59,999);
    
    const weekStartStr = weekStart.toISOString().split('T')[0];
    const weekEndStr = weekEnd.toISOString().split('T')[0];
    
    const weekSchedules = schedules.filter(s => {
        return s.workDate >= weekStartStr && s.workDate <= weekEndStr;
    });
    
    // Define exactly 2 shifts
    const timeSlots = ["7:30 - 12:00", "13:30 - 16:30"];
    
    const tbody = document.getElementById("gridBody");
    tbody.innerHTML = "";
    
    timeSlots.forEach((slot, index) => {
        let rowHtml = `<tr>
            <td class="fw-semibold text-nowrap bg-light text-center py-4" style="width: 140px;">
                <div class="small text-secondary mb-1">Ca ${index + 1}</div>
                <span class="badge bg-success bg-opacity-10 text-success slot-badge border border-success border-opacity-10">${slot}</span>
            </td>`;
        
        for (let i = 0; i < 7; i++) {
            const dateObj = weekDates[i];
            const dateStr = dateObj.toISOString().split('T')[0];
            
            // Find all schedules matching dateStr and falling into this slot
            const matchedSchedules = weekSchedules.filter(s => {
                return s.workDate === dateStr && getStandardShift(s.timeSlot) === slot;
            });
            
            if (matchedSchedules.length > 0) {
                let cellHtml = `<td class="p-2 align-top" style="background-color: #fafdfc;">
                    <div class="d-flex flex-column gap-2">`;
                
                matchedSchedules.forEach(matched => {
                    let badgeClass = "bg-success-subtle text-success border border-success-subtle";
                    let statusText = "Sẵn sàng";
                    if (matched.status === "Full" || matched.status === "full") {
                        badgeClass = "bg-danger-subtle text-danger border border-danger-subtle";
                        statusText = "Đầy lịch";
                    } else if (matched.status === "Expired" || matched.status === "expired") {
                        badgeClass = "bg-secondary-subtle text-secondary border border-secondary-subtle";
                        statusText = "Đã qua";
                    }
                    
                    cellHtml += `<div class="schedule-cell-card p-2 text-start w-100 shadow-xs">
                        <div class="fw-bold text-success mb-0.5" style="font-size: 0.82rem;">${matched.roomName || 'Phòng khám'}</div>
                        <div class="text-secondary small mb-1" style="font-size: 0.7rem;">
                            <span class="fw-semibold text-dark me-1"><i class="bi bi-clock me-0.5"></i>${matched.timeSlot}</span>
                            <span>(${matched.roomId || '-'})</span>
                        </div>
                        <div class="d-flex align-items-center justify-content-between pt-1 border-top" style="border-top-style: dashed !important; border-top-color: #eee !important;">
                            <span class="badge ${badgeClass} text-xs py-0.5 px-1">${statusText}</span>
                            <span class="fw-semibold text-secondary text-xs"><i class="bi bi-people me-1"></i>${matched.bookedPatients}/${matched.maxPatients}</span>
                        </div>
                    </div>`;
                });
                
                cellHtml += `</div></td>`;
                rowHtml += cellHtml;
            } else {
                rowHtml += `<td class="text-center text-secondary opacity-25 py-4">-</td>`;
            }
        }
        rowHtml += `</tr>`;
        tbody.innerHTML += rowHtml;
    });
}

document.addEventListener("DOMContentLoaded", () => {
    generateWeekOptions();
    renderScheduleGrid();
});
</script>
</body>
</html>
