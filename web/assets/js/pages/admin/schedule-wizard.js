/**
 * =========================================================================
 * MODULE: LẬP LỊCH THÔNG MINH BÁC SĨ (AI SCHEDULING WIZARD & WEEKLY CALENDAR)
 * =========================================================================
 * File này quản lý biểu mẫu Wizard 3 bước lập lịch thông minh bằng AI, 
 * hiển thị Preview các ca trực đề xuất và xem lịch trực tuần (Weekly Calendar).
 */

// ==========================================
// 1. GLOBAL VARIABLES FOR WIZARD
// ==========================================
let proposedSchedules = [];
let availableDoctors = [];

// ==========================================
// 2. SHIFT TEMPLATE & CAPACITY CALCULATION HELPERS
// ==========================================

function normalizeSearchText(value) {
    return (value || '')
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'd')
        .replace(/[^a-z0-9]+/g, ' ')
        .trim();
}

const specialtyKeywords = {
    'Nội tiết - Tiểu đường': ['noi tiet', 'endo'],
    'Endocrinology': ['noi tiet', 'endo'],
    'Tim mạch': ['tim mach', 'cardio'],
    'Cardiology': ['tim mach', 'cardio'],
    'Thận học': ['than hoc', 'nephro'],
    'Nephrology': ['than hoc', 'nephro'],
    'Tổng quát': ['tong quat', 'general'],
    'General': ['tong quat', 'general']
};

function getActiveRoomsForSpecialty(specialty) {
    if (!window.activeRoomsList || !Array.isArray(window.activeRoomsList) || window.activeRoomsList.length === 0) {
        return [{ roomId: 'R102', roomName: 'Phòng Khám Tổng Quát 1', department: 'Tổng quát', status: 'active' }];
    }
    // Lọc lấy các phòng khám tổng quát dành cho Bác sĩ (Không lấy Quầy lễ tân R101 & Phòng xét nghiệm R104/R105)
    const doctorRooms = window.activeRoomsList.filter(room => {
        const id = (room.roomId || '').toLowerCase().trim();
        const name = normalizeSearchText(room.roomName || '');
        const status = (room.status || '').toLowerCase().trim();
        const isActive = status === 'active' || status === '';
        const isLab = name.includes('xet nghiem') || name.includes('lab') || name.includes('xn') || id === 'r104' || id === 'r105';
        const isReception = name.includes('quay') || name.includes('reception') || id === 'r101';
        return isActive && !isLab && !isReception;
    });

    if (doctorRooms.length === 0) {
        return [{ roomId: 'R102', roomName: 'Phòng Khám Tổng Quát 1', department: 'Tổng quát', status: 'active' }];
    }

    const keywords = specialtyKeywords[specialty] || [];
    const matchedBySpecialty = doctorRooms.filter(room => {
        const name = normalizeSearchText(room.roomName || '');
        const dept = normalizeSearchText(room.department || '');
        return keywords.some(kw => name.includes(kw) || dept.includes(kw));
    });

    return matchedBySpecialty.length > 0 ? matchedBySpecialty : doctorRooms;
}

/**
 * Đếm số lượng ca trực trong tệp cấu hình thô mẫu ca trực
 * @returns {number} Số ca trực
 */
function countShiftTemplateLines() {
    const textarea = document.querySelector('textarea[name="shiftTemplates"]');
    return textarea ? textarea.value.split(/\r?\n/).filter(line => line.trim().includes('|')).length : 0;
}

function getDoctorActiveRooms() {
    if (!window.activeRoomsList || !Array.isArray(window.activeRoomsList) || window.activeRoomsList.length === 0) {
        return [
            { roomId: 'R102', roomName: 'Phòng Khám Tổng Quát 1', department: 'Tổng quát', status: 'active' },
            { roomId: 'R103', roomName: 'Phòng KhámTổng Quát 2', department: 'Tổng quát', status: 'active' }
        ];
    }
    const doctorRooms = window.activeRoomsList.filter(room => {
        const id = (room.roomId || '').toLowerCase().trim();
        const name = normalizeSearchText(room.roomName || '');
        const status = (room.status || '').toLowerCase().trim();
        const isActive = status === 'active' || status === '';
        const isLab = name.includes('xet nghiem') || name.includes('lab') || name.includes('xn') || id === 'r104' || id === 'r105';
        const isReception = name.includes('quay') || name.includes('reception') || id === 'r101';
        return isActive && !isLab && !isReception;
    });

    return doctorRooms.length > 0 ? doctorRooms : [
        { roomId: 'R102', roomName: 'Phòng Khám Tổng Quát 1', department: 'Tổng quát', status: 'active' },
        { roomId: 'R103', roomName: 'Phòng KhámTổng Quát 2', department: 'Tổng quát', status: 'active' }
    ];
}

/**
 * Xây dựng danh sách ca trực dựa vào các ca hành chính và đối tượng được chọn
 * @returns {Array<string>} Mảng ca trực dạng "timeSlot|department"
 */
function buildCustomShiftTemplate() {
    const staffType = document.getElementById('aiStaffType') ? document.getElementById('aiStaffType').value : 'Doctor';
    const checkedShifts = Array.from(document.querySelectorAll('input[name="aiSelectedShifts"]:checked')).map(cb => cb.value);

    if (checkedShifts.length === 0) {
        return [];
    }

    const slots = [];
    if (staffType === 'Doctor') {
        const checkedDepts = Array.from(document.querySelectorAll('.ai-dept-cb:checked')).map(cb => cb.value);
        if (checkedDepts.length === 0) return [];

        const staffPerRoom = getDoctorsPerShift();
        const doctorRooms = getDoctorActiveRooms();
        const totalSlotsPerShift = doctorRooms.length * staffPerRoom;

        checkedShifts.forEach(shift => {
            for (let i = 0; i < totalSlotsPerShift; i++) {
                const dept = checkedDepts[i % checkedDepts.length];
                slots.push(shift + '|' + dept);
            }
        });
    } else if (staffType === 'Receptionist') {
        checkedShifts.forEach(shift => {
            slots.push(shift + '|Tiếp nhận');
        });
    } else if (staffType === 'doctor_lab') {
        checkedShifts.forEach(shift => {
            slots.push(shift + '|');
        });
    }

    return slots;
}

/**
 * Cập nhật hiển thị bản xem trước của khuôn mẫu ca trực trong Hidden input
 */
function updateTemplatePreview() {
    const hiddenTemplates = document.getElementById('aiShiftTemplates');
    if (hiddenTemplates) {
        const slots = buildCustomShiftTemplate();
        // Định dạng gửi lên: mỗi dòng là một ca "timeslot|department|\n"
        const templateLines = slots.map(s => s + '||').join('\n');
        hiddenTemplates.value = templateLines;
    }
    updateAiMaxSchedules();
}

/**
 * Lấy danh sách các thứ được tick chọn trong tuần (1 = Thứ 2, 7 = Chủ nhật)
 * @returns {Array<number>}
 */
function getSelectedWeekdays() {
    return Array.from(document.querySelectorAll('input[name="selectedWeekdays"]:checked'))
        .map(input => Number(input.value));
}

/**
 * Đếm số ngày thực tế được áp dụng lịch trực trong khoảng ngày bắt đầu/kết thúc
 * @param {string} startValue 
 * @param {string} endValue 
 * @returns {number} Số ngày thỏa mãn các thứ được chọn
 */
function countSelectedTargetDates(startValue, endValue) {
    if (!startValue || !endValue) {
        return 0;
    }
    const selected = new Set(getSelectedWeekdays());
    const cursor = new Date(startValue + 'T00:00:00');
    const end = new Date(endValue + 'T00:00:00');
    let count = 0;
    while (cursor <= end) {
        const jsDay = cursor.getDay();
        const isoDay = jsDay === 0 ? 7 : jsDay;
        if (selected.has(isoDay)) {
            count++;
        }
        cursor.setDate(cursor.getDate() + 1);
    }
    return count;
}

/**
 * Lấy số lượng nhân viên phân bổ trực cho mỗi ca/phòng từ ô chọn
 * @returns {number}
 */
function getDoctorsPerShift() {
    const input = document.getElementById('aiDoctorsPerShift');
    const value = input ? Number(input.value) : 1;
    return Number.isFinite(value) && value > 0 ? value : 1;
}

/**
 * Tính toán và cập nhật tóm tắt tổng số ca trực dự kiến sẽ tạo
 */
function updateAiMaxSchedules() {
    const startDate = document.getElementById('aiStartDate');
    const endDate = document.getElementById('aiEndDate');
    const maxSchedules = document.getElementById('aiMaxSchedules');
    const summary = document.getElementById('aiScheduleSummary');
    const staffType = document.getElementById('aiStaffType') ? document.getElementById('aiStaffType').value : 'Doctor';

    if (!startDate || !endDate || !maxSchedules || !startDate.value || !endDate.value) {
        if (summary) {
            summary.innerHTML = '<span class="text-muted">Vui lòng chọn khoảng ngày để xem tóm tắt...</span>';
        }
        return;
    }
    const days = countSelectedTargetDates(startDate.value, endDate.value);
    const checkedShifts = Array.from(document.querySelectorAll('input[name="aiSelectedShifts"]:checked')).map(cb => cb.value);
    const actualShiftsPerDay = checkedShifts.length;
    const staffPerShift = getDoctorsPerShift();

    let total = 0;
    let desc = '';

    if (staffType === 'Doctor') {
        const checkedDepts = Array.from(document.querySelectorAll('.ai-dept-cb:checked')).map(cb => cb.value);
        const doctorRooms = getDoctorActiveRooms();
        const roomsCount = doctorRooms.length;
        const totalDoctorsPerShift = roomsCount * staffPerShift;

        let specialtyDetailHtml = `<ul class="ps-3 mb-0 text-muted" style="font-size:0.78rem; list-style-type:circle;">
            <li>Tổng phòng khám tổng quát đang hoạt động: <strong>${roomsCount} phòng</strong></li>
            <li>Sức chứa phân bổ: <strong>${totalDoctorsPerShift} bác sĩ/ca</strong> (${roomsCount} phòng x ${staffPerShift} bác sĩ/phòng)</li>
        </ul>`;

        total = days * actualShiftsPerDay * totalDoctorsPerShift;
        desc = `(${days} ngày x ${actualShiftsPerDay} ca trực/ngày x ${totalDoctorsPerShift} bác sĩ/ca)<br>${specialtyDetailHtml}`;
    } else if (staffType === 'Receptionist') {
        total = days * actualShiftsPerDay * staffPerShift;
        desc = `(${days} ngày x ${actualShiftsPerDay} ca trực/ngày x ${staffPerShift} lễ tân/ca)`;
    } else if (staffType === 'doctor_lab') {
        const checkedRooms = Array.from(document.querySelectorAll('.lab-room-cb:checked')).length;
        const roomsCount = checkedRooms > 0 ? checkedRooms : 1;
        const totalStaffPerShift = roomsCount * staffPerShift;
        total = days * actualShiftsPerDay * totalStaffPerShift;
        desc = `(${days} ngày x ${actualShiftsPerDay} ca trực/ngày x ${totalStaffPerShift} bác sĩ xét nghiệm/ca - ${roomsCount} phòng lab)`;
    }

    maxSchedules.value = total;
    if (summary) {
        summary.innerHTML = `Tổng số ca trực dự kiến: <strong class="text-purple" style="font-size:0.95rem;">${total} ca trực</strong> <span class="text-muted d-block mt-1">${desc}</span>`;
    }
}

/**
 * Cấu hình động giao diện Universal Modal theo vai trò được chọn
 */
function initUniversalModal(staffType) {
    const title = document.getElementById('aiModalTitle');
    const subtitle = document.getElementById('aiModalSubtitle');
    const staffTypeInput = document.getElementById('aiStaffType');
    const actionInput = document.getElementById('aiAction');
    const staffPerShiftLabel = document.getElementById('aiStaffPerShiftLabel');
    const doctorsPerShiftSelect = document.getElementById('aiDoctorsPerShift');

    const deptSection = document.getElementById('aiDeptSelectionSection');
    const labRoomSection = document.getElementById('aiLabRoomSelectionSection');
    const conflictSection = document.getElementById('aiConflictHandlingSection');
    const proposalContainer = document.getElementById('aiProposalTableContainer');
    const submitBtn = document.getElementById('aiScheduleSubmitBtn');
    const runBtn = document.getElementById('aiRunModelBtn');

    if (proposalContainer) proposalContainer.classList.add('d-none');
    if (submitBtn) submitBtn.style.display = 'none';
    if (runBtn) {
        runBtn.style.display = 'inline-block';
        runBtn.disabled = false;
    }

    if (staffTypeInput) staffTypeInput.value = staffType;

    const startDate = document.getElementById('aiStartDate');
    const endDate = document.getElementById('aiEndDate');
    const todayStr = new Date().toISOString().slice(0, 10);
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);
    const nextWeekStr = nextWeek.toISOString().slice(0, 10);

    if (startDate && !startDate.value) startDate.value = todayStr;
    if (endDate && !endDate.value) endDate.value = nextWeekStr;

    if (doctorsPerShiftSelect) {
        doctorsPerShiftSelect.innerHTML = '';
        if (staffType === 'Doctor') {
            doctorsPerShiftSelect.innerHTML =
                '<option value="1" selected>1 bác sĩ/phòng</option>' +
                '<option value="2">2 bác sĩ/phòng</option>' +
                '<option value="3">3 bác sĩ/phòng</option>';
        } else if (staffType === 'Receptionist') {
            doctorsPerShiftSelect.innerHTML =
                '<option value="1" selected>1 lễ tân/ca</option>' +
                '<option value="2">2 lễ tân/ca</option>' +
                '<option value="3">3 lễ tân/ca</option>';
        } else if (staffType === 'doctor_lab') {
            doctorsPerShiftSelect.innerHTML =
                '<option value="1">1 KTV/ca</option>' +
                '<option value="2" selected>2 KTV/ca</option>' +
                '<option value="3">3 KTV/ca</option>';
        }
    }

    if (conflictSection) conflictSection.classList.remove('d-none');

    if (staffType === 'Doctor') {
        if (title) title.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles me-2 text-purple"></i>Lập lịch bác sĩ thông minh';
        if (subtitle) subtitle.textContent = 'Tối ưu hóa nguồn lực và tự động phân bổ ca trực bằng AI Gemini.';
        if (actionInput) actionInput.value = 'aiCreateSchedules';
        if (staffPerShiftLabel) staffPerShiftLabel.textContent = 'Số bác sĩ trực mỗi PHÒNG';

        if (deptSection) deptSection.classList.remove('d-none');
        if (labRoomSection) labRoomSection.classList.add('d-none');

        if (runBtn) {
            runBtn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles me-1"></i>Lập lịch thông minh';
            runBtn.className = 'btn btn-purple text-white bg-purple border-purple';
        }
    } else if (staffType === 'Receptionist') {
        if (title) title.innerHTML = '<i class="bi bi-person-badge me-2 text-success"></i>Lập lịch lễ tân thông minh';
        if (subtitle) subtitle.textContent = 'Tự động tạo lịch trực lễ tân hành chính cố định.';
        if (actionInput) actionInput.value = 'ai-staff-schedule';
        if (staffPerShiftLabel) staffPerShiftLabel.textContent = 'Số lễ tân mỗi ca';

        if (deptSection) deptSection.classList.add('d-none');
        if (labRoomSection) labRoomSection.classList.add('d-none');

        if (runBtn) {
            runBtn.innerHTML = '<i class="bi bi-check-circle me-1"></i>Xác nhận lập lịch';
            runBtn.className = 'btn btn-success text-white';
        }
    } else if (staffType === 'doctor_lab') {
        if (title) title.innerHTML = '<i class="bi bi-clipboard2-pulse me-2 text-info"></i>Lập lịch xét nghiệm thông minh';
        if (subtitle) subtitle.textContent = 'Tự động tạo lịch trực kỹ thuật viên phòng xét nghiệm hành chính.';
        if (actionInput) actionInput.value = 'ai-staff-schedule';
        if (staffPerShiftLabel) staffPerShiftLabel.textContent = 'Số kỹ thuật viên mỗi ca';

        if (deptSection) deptSection.classList.add('d-none');
        if (labRoomSection) labRoomSection.classList.remove('d-none');

        if (runBtn) {
            runBtn.innerHTML = '<i class="bi bi-check-circle me-1"></i>Xác nhận lập lịch';
            runBtn.className = 'btn btn-success text-white';
        }
    }

    const alertBox = document.getElementById('aiScheduleAlert');
    if (alertBox) alertBox.style.display = 'none';

    const startEl = document.getElementById('aiStartDate');
    if (startEl) {
        startEl.dispatchEvent(new Event('change'));
    }
}

// ==========================================
// 3. WIZARD INTERFACES & UI PROGRESS STEPS
// ==========================================

function setAiScheduleBusy(isBusy) {
    const toolbarButton = document.getElementById('aiScheduleGeminiBtn');
    const submitButton = document.getElementById('aiScheduleSubmitBtn');
    const loadingBox = document.getElementById('aiScheduleLoading');
    const detail = document.getElementById('aiScheduleLoadingDetail');
    if (toolbarButton) {
        toolbarButton.disabled = isBusy;
    }
    if (submitButton) {
        submitButton.disabled = isBusy;
        submitButton.innerHTML = isBusy
            ? '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Đang lưu lịch trực...'
            : '<i class="fa-solid fa-cloud-arrow-up me-2"></i>Xác nhận lưu lịch trực';
    }
    if (loadingBox) {
        loadingBox.classList.toggle('d-none', !isBusy);
        loadingBox.classList.toggle('d-flex', isBusy);
    }
    if (detail) {
        detail.textContent = isBusy ? 'Đang ghi lịch trực thật vào hệ thống...' : '';
    }
}

function showAiScheduleMessage(message, isSuccess) {
    const alertBox = document.getElementById('aiScheduleAlert');
    if (!alertBox) return;
    alertBox.style.display = 'block';
    alertBox.className = 'alert border-0 fw-semibold ' + (isSuccess ? 'alert-success' : 'alert-danger');
    alertBox.innerHTML = '<i class="fa-solid ' + (isSuccess ? 'fa-circle-check' : 'fa-triangle-exclamation') + ' me-2"></i>' + escapeHtmlForSchedule(message);
}

function appendCreatedSchedules(schedules) {
    const tbody = document.getElementById('scheduleTableBody');
    if (!tbody || !Array.isArray(schedules) || schedules.length === 0) return;
    const emptyRow = tbody.querySelector('td[colspan="10"]');
    if (emptyRow) emptyRow.closest('tr').remove();
    tbody.insertAdjacentHTML('afterbegin', schedules.map(buildScheduleRow).join(''));
}

function buildScheduleRow(schedule) {
    const maxPatients = Number(schedule.maxPatients || 20);
    const activeAppointments = Number(schedule.activeAppointments || 0);
    const bookedAppointments = Number(schedule.bookedAppointments || schedule.bookedCount || activeAppointments || 0);
    const loadPct = maxPatients > 0 ? Math.round((bookedAppointments * 100) / maxPatients) : 0;
    const onlineQuota = schedule.onlineQuota !== undefined && schedule.onlineQuota !== null
        ? Number(schedule.onlineQuota)
        : calculateDefaultOnlineQuota(maxPatients);
    const onlineBookedCount = Number(schedule.onlineBookedCount || 0);
    const reservedSlots = schedule.reservedSlots !== undefined && schedule.reservedSlots !== null
        ? Number(schedule.reservedSlots)
        : Math.max(0, maxPatients - onlineQuota);

    const departmentMap = {
        Endocrinology: 'Nội tiết - Tiểu đường',
        Cardiology: 'Tim mạch',
        Nephrology: 'Thận học',
        General: 'Tổng quát'
    };
    const department = departmentMap[schedule.department] || (schedule.department || 'Chưa xác định');

    const isGemini = schedule.source === 'Gemini AI';
    const sourceLabel = isGemini ? 'Gemini AI tạo lịch' : 'Cân bằng tải dự phòng';
    const sourceIcon = isGemini ? 'fa-brain' : 'fa-scale-balanced';

    const status = schedule.effectiveStatus || schedule.status || 'Available';

    let statusBadge = '<span class="badge text-bg-success"><i class="bi bi-check-circle"></i> Khả dụng</span>';

    if (status === 'Expired') {
        statusBadge = '<span class="badge text-bg-secondary"><i class="bi bi-clock"></i> Đã qua</span>';
    } else if (status === 'Cancelled') {
        statusBadge = '<span class="badge text-bg-dark"><i class="bi bi-x-circle"></i> Đã hủy</span>';
    } else if (status === 'Full') {
        statusBadge = '<span class="badge text-bg-danger"><i class="bi bi-exclamation-circle"></i> Đã đầy</span>';
    }
    const scheduleId = escapeHtmlForSchedule(schedule.scheduleId || '');
    let actionColumn = '';
    if (scheduleId) {
        let additionalActions = '';
        if (status !== 'Expired' && status !== 'Cancelled') {
            additionalActions = '<li><button type="button" class="dropdown-item" onclick="openEditScheduleModal(\'' + scheduleId + '\')"><i class="bi bi-pencil-square me-2"></i>Chỉnh sửa</button></li>'
                + '<li><button type="button" class="dropdown-item" onclick="openTransferModalFromRow(this)"><i class="bi bi-arrow-left-right me-2"></i>Chuyển ca</button></li>'
                + '<li><form method="post" onsubmit="return confirm(\'Bạn có chắc muốn hủy lịch trực này?\');">'
                + '<input type="hidden" name="action" value="cancelSchedule">'
                + '<input type="hidden" name="scheduleId" value="' + scheduleId + '">'
                + '<button type="submit" class="dropdown-item text-danger"><i class="bi bi-trash me-2"></i>Hủy lịch</button>'
                + '</form></li>';
        }
        actionColumn = '<div class="dropdown table-actions">'
            + '<button type="button" class="btn btn-sm btn-outline-secondary rounded-circle" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Thao tác lịch trực">'
            + '<i class="bi bi-three-dots-vertical"></i>'
            + '</button>'
            + '<ul class="dropdown-menu dropdown-menu-end">'
            + '<li><button type="button" class="dropdown-item schedule-detail-action" data-schedule-id="' + scheduleId + '"><i class="bi bi-eye me-2"></i>Xem chi tiết</button></li>'
            + additionalActions
            + '</ul>'
            + '</div>';
    } else {
        actionColumn = '<span class="badge ai-schedule-badge" title="'
            + escapeHtmlForSchedule(schedule.reason || '')
            + '"><i class="fa-solid fa-database me-1"></i>Đã lưu DB</span>';
    }

    return '<tr class="ai-generated-row" data-schedule-id="' + (schedule.scheduleId || '') + '" data-doctor-name="' + escapeHtmlForSchedule(schedule.doctorName)
        + '" data-department="' + escapeHtmlForSchedule(schedule.department || '')
        + '" data-load-pct="' + loadPct + '" data-active-appointments="' + activeAppointments + '" data-booked-appointments="' + bookedAppointments
        + '" data-online-booked-count="' + onlineBookedCount + '" data-max-patients="' + maxPatients
        + '" data-online-quota="' + onlineQuota + '" data-reserved-slots="' + reservedSlots + '">'

        + '<td><span class="fw-semibold">' + escapeHtmlForSchedule(schedule.doctorName)
        + '</span><div class="small text-purple"><i class="fa-solid ' + sourceIcon + ' me-1"></i>'
        + sourceLabel + '</div></td>'

        + '<td>' + escapeHtmlForSchedule(department) + '</td>'

        + '<td>' + escapeHtmlForSchedule(formatVietnameseDate(schedule.workDate)) + '</td>'

        + '<td>' + escapeHtmlForSchedule(schedule.timeSlot) + '</td>'

        + '<td><span class="badge bg-light text-dark border"><i class="fa-solid fa-hospital-user me-1 text-primary"></i>'
        + escapeHtmlForSchedule(schedule.room || schedule.roomName || schedule.roomId || 'Chưa xếp') + '</span></td>'

        + '<td><div style="background-color: #f0f8f4; padding: 6px 10px; border-radius: 4px; font-weight: 500; text-align: center;">'
        + bookedAppointments + ' / ' + maxPatients + '</div>'
        + '<small class="text-muted d-block text-center mt-1">Đã check-in/đang khám: ' + activeAppointments + '</small>'
        + '<small class="text-muted d-block text-center">Dự phòng: ' + reservedSlots + ' slot</small></td>'

        + '<td class="text-center">'
        + '<div class="fw-semibold">' + onlineBookedCount + ' / ' + onlineQuota + '</div>'
        + '<small class="text-muted d-block">Slot online</small>'
        + getOnlineQuotaBadge(onlineBookedCount, onlineQuota)
        + '</td>'

        + '<td class="schedule-load-cell">'
        + '<div class="schedule-load-wrap" title="' + (loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Bình thường')) + '">'
        + '<div class="progress schedule-load-progress">'
        + '<div class="progress-bar ' + (loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')) + '" role="progressbar" style="width: ' + (loadPct > 100 ? 100 : loadPct) + '%;" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' + loadPct + '"></div>'
        + '</div>'
        + '<span class="badge schedule-load-percent ' + (loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')) + '">' + loadPct + '%</span>'
        + '<small class="text-muted schedule-load-state">' + (loadPct >= 100 ? 'Quá tải' : (loadPct >= 80 ? 'Cận đầy' : 'Bình thường')) + '</small>'
        + '</div>'
        + '</td>'

        + '<td>' + statusBadge + '</td>'

        + '<td>' + actionColumn + '</td>'

        + '</tr>';
}

document.addEventListener('DOMContentLoaded', function () {
    const startDate = document.getElementById('aiStartDate');
    const endDate = document.getElementById('aiEndDate');
    const form = document.getElementById('aiScheduleForm');
    const maxPatientsInput = document.getElementById('aiMaxPatients');
    const submitBtn = document.getElementById('aiScheduleSubmitBtn');

    function updateWeekdayStates() {
        if (!startDate || !endDate || !startDate.value || !endDate.value) return;
        const start = new Date(startDate.value + 'T00:00:00');
        const end = new Date(endDate.value + 'T00:00:00');
        const activeDays = new Set();
        const cursor = new Date(start);
        while (cursor <= end) {
            const jsDay = cursor.getDay();
            const isoDay = jsDay === 0 ? 7 : jsDay;
            activeDays.add(isoDay);
            cursor.setDate(cursor.getDate() + 1);
        }
        document.querySelectorAll('input[name="selectedWeekdays"]').forEach(cb => {
            const val = Number(cb.value);
            const container = cb.closest('.form-check') || cb.parentElement;
            if (activeDays.has(val)) {
                cb.disabled = false;
                if (container) container.classList.remove('opacity-50');
            } else {
                cb.disabled = true;
                cb.checked = false;
                if (container) container.classList.add('opacity-50');
            }
        });
        updateAiMaxSchedules();
    }

    [startDate, endDate].forEach(input => {
        if (input) input.addEventListener('change', updateWeekdayStates);
    });

    document.querySelectorAll('.ai-dept-cb, .doctor-ai-shift-cb, input[name="selectedWeekdays"], .lab-room-cb').forEach(cb => {
        cb.addEventListener('change', updateTemplatePreview);
    });

    const doctorsPerShiftSelect = document.getElementById('aiDoctorsPerShift');
    if (doctorsPerShiftSelect) {
        doctorsPerShiftSelect.addEventListener('change', updateTemplatePreview);
    }

    const aiModalEl = document.getElementById('aiScheduleModal');
    if (aiModalEl) {
        aiModalEl.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            const staffType = button ? (button.getAttribute('data-staff-type') || 'Doctor') : 'Doctor';
            initUniversalModal(staffType);
        });
    }

    const runModelBtn = document.getElementById('aiRunModelBtn');
    if (runModelBtn) {
        runModelBtn.addEventListener('click', async function () {
            if (!startDate.value || !endDate.value) {
                showAiScheduleMessage('Vui lòng chọn khoảng ngày trực.', false);
                return;
            }
            if (startDate.value > endDate.value) {
                showAiScheduleMessage('Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.', false);
                return;
            }

            const staffType = document.getElementById('aiStaffType') ? document.getElementById('aiStaffType').value : 'Doctor';

            if (staffType === 'Doctor') {
                const depts = Array.from(document.querySelectorAll('.ai-dept-cb:checked')).map(cb => cb.value);
                if (depts.length === 0) {
                    showAiScheduleMessage('Vui lòng chọn ít nhất một chuyên khoa áp dụng.', false);
                    return;
                }
            } else if (staffType === 'doctor_lab') {
                const rooms = Array.from(document.querySelectorAll('.lab-room-cb:checked')).map(cb => cb.value);
                if (rooms.length === 0) {
                    showAiScheduleMessage('Vui lòng chọn ít nhất một phòng xét nghiệm áp dụng.', false);
                    return;
                }
            }

            const shifts = Array.from(document.querySelectorAll('input[name="aiSelectedShifts"]:checked')).map(cb => cb.value);
            if (shifts.length === 0) {
                showAiScheduleMessage('Vui lòng chọn ít nhất một khung ca trực áp dụng.', false);
                return;
            }

            if (getSelectedWeekdays().length === 0) {
                showAiScheduleMessage('Vui lòng chọn ít nhất một ngày áp dụng trong tuần.', false);
                return;
            }

            if (staffType === 'Doctor') {
                await generateProposal();
            } else {
                await submitStaffAiSchedule();
            }
        });
    }

    async function generateProposal() {
        const loader = document.getElementById('aiProposalLoading');
        const container = document.getElementById('aiProposalTableContainer');

        if (loader) {
            loader.classList.remove('d-none');
            const loadingTitle = document.getElementById('aiLoadingTitle');
            if (loadingTitle) loadingTitle.textContent = 'Đang gửi yêu cầu phân bổ bằng AI Gemini...';
        }
        if (container) container.classList.add('d-none');
        if (submitBtn) submitBtn.style.display = 'none';

        updateTemplatePreview();

        const doctorsPerShiftHidden = document.getElementById('aiDoctorsPerShiftHidden');
        if (doctorsPerShiftHidden) {
            doctorsPerShiftHidden.value = "1";
        }

        const formData = new FormData(form);
        const params = new URLSearchParams();
        params.set('action', 'aiCreateSchedules');
        params.set('preview', 'true');
        formData.forEach((value, key) => params.append(key, value));

        try {
            const response = await fetch(adminScheduleEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json'
                },
                body: params.toString()
            });
            if (!response.ok) throw new Error('HTTP ' + response.status);
            const data = await response.json();
            if (!data.success) throw new Error(data.message || 'Lỗi không xác định.');

            proposedSchedules = data.items || [];
            availableDoctors = data.doctors || [];

            renderProposalTable();

            if (loader) loader.classList.add('d-none');
            if (container) container.classList.remove('d-none');
            if (submitBtn) submitBtn.style.display = 'inline-block';
            if (runModelBtn) runModelBtn.style.display = 'none';

            const modalBody = document.querySelector('#aiScheduleModal .modal-body');
            if (modalBody) {
                setTimeout(() => {
                    modalBody.scrollTo({
                        top: modalBody.scrollHeight,
                        behavior: 'smooth'
                    });
                }, 200);
            }
        } catch (err) {
            showAiScheduleMessage('Không thể tạo đề xuất AI: ' + err.message, false);
            if (loader) loader.classList.add('d-none');
        }
    }

    async function submitStaffAiSchedule() {
        const loader = document.getElementById('aiProposalLoading');
        const alertBox = document.getElementById('aiScheduleAlert');

        if (loader) {
            loader.classList.remove('d-none');
            const loadingTitle = document.getElementById('aiLoadingTitle');
            if (loadingTitle) loadingTitle.textContent = 'Đang tự động xử lý và lưu ca trực...';
        }
        if (runModelBtn) runModelBtn.disabled = true;
        if (alertBox) alertBox.style.display = 'none';

        updateTemplatePreview();

        const staffType = document.getElementById('aiStaffType').value;
        const doctorsPerShiftSelect = document.getElementById('aiDoctorsPerShift');
        const doctorsPerShiftHidden = document.getElementById('aiDoctorsPerShiftHidden');
        if (doctorsPerShiftHidden && doctorsPerShiftSelect) {
            doctorsPerShiftHidden.value = doctorsPerShiftSelect.value;
        }
        const deptHiddenInput = document.getElementById('aiDeptHiddenInput');
        if (deptHiddenInput) {
            deptHiddenInput.value = (staffType === 'Receptionist') ? 'Tiếp nhận' : 'Xét nghiệm';
        }

        const formData = new FormData(form);
        const params = new URLSearchParams();

        params.set('action', 'ai-staff-schedule');
        formData.forEach((value, key) => {
            if (key === 'roomIds') {
                params.append('roomIds', value);
            } else if (key !== 'action') {
                params.set(key, value);
            }
        });

        try {
            const response = await fetch(adminScheduleEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json'
                },
                body: params.toString()
            });

            let data = {};
            const text = await response.text();
            try {
                data = JSON.parse(text);
            } catch (e) {
                if (response.redirected || response.ok) {
                    data = { success: true, message: 'Lập lịch thông minh thành công!' };
                } else {
                    throw new Error('Không thể phân tích phản hồi từ máy chủ.');
                }
            }

            if (!data.success) throw new Error(data.message || 'Lỗi lưu lịch trực.');

            showAiScheduleMessage('Lập lịch thông minh thành công! Trang web sẽ tải lại...', true);
            setTimeout(() => {
                window.location.reload();
            }, 1200);

        } catch (err) {
            showAiScheduleMessage('Lỗi lập lịch: ' + err.message, false);
            if (loader) loader.classList.add('d-none');
            if (runModelBtn) runModelBtn.disabled = false;
        }
    }

    function renderProposalTable() {
        const tbody = document.getElementById('aiProposalTableBody');
        if (!tbody) return;
        tbody.innerHTML = '';

        if (proposedSchedules.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted py-3">Không có ca trực nào được đề xuất.</td></tr>';
            return;
        }

        proposedSchedules.forEach((item, index) => {
            const row = document.createElement('tr');
            const specialty = item.department || '';
            const displayDept = departmentMapping[specialty] || specialty;
            const doctorsInSpecialty = availableDoctors.filter(doc => {
                const docDept = String(doc.department || '').toLowerCase().trim();
                const searchDept = displayDept.toLowerCase().trim();
                return docDept.includes(searchDept) || searchDept.includes(docDept);
            });

            const doctorOptionsList = doctorsInSpecialty.length > 0 ? doctorsInSpecialty : availableDoctors;
            let selectHtml = '<select class="form-select form-select-sm proposed-doctor-select" style="min-width: 150px; font-size: 0.8rem; padding: 0.25rem 0.5rem;" data-index="' + index + '">';
            doctorOptionsList.forEach(doc => {
                const selected = Number(doc.doctorId) === Number(item.doctorId) ? 'selected' : '';
                selectHtml += '<option value="' + doc.doctorId + '" ' + selected + '>' + escapeHtmlForSchedule(doc.doctorName || doc.fullName || '-') + '</option>';
            });
            selectHtml += '</select>';

            row.innerHTML = '<td><strong>' + escapeHtmlForSchedule(formatVietnameseDate(item.workDate)) + '</strong></td>'
                + '<td><span class="badge bg-purple-subtle text-purple border border-purple-subtle" style="background:#f3e8ff; color:#6b21a8; font-size: 0.78rem; font-weight:600; padding:0.25rem 0.45rem;">' + escapeHtmlForSchedule(item.timeSlot) + '</span></td>'
                + '<td><span class="fw-semibold text-dark" style="font-size:0.82rem;">' + escapeHtmlForSchedule(displayDept) + '</span></td>'
                + '<td>' + selectHtml + '</td>'
                + '<td><small class="text-muted" style="line-height:1.25; display:block; font-size:0.75rem;">' + escapeHtmlForSchedule(item.reason || '-') + '</small></td>';

            tbody.appendChild(row);
        });

        const summary = document.getElementById('aiScheduleSummary');
        if (summary) {
            summary.textContent = 'Hệ thống đã đề xuất ' + proposedSchedules.length + ' ca trực bác sĩ khám. Bạn có thể chọn bác sĩ trực khác từ danh sách thả xuống.';
        }
    }

    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();

            const staffType = document.getElementById('aiStaffType') ? document.getElementById('aiStaffType').value : 'Doctor';
            if (staffType !== 'Doctor' || proposedSchedules.length === 0) return;

            const selects = document.querySelectorAll('.proposed-doctor-select');
            const params = new URLSearchParams();
            params.set('action', 'aiSaveProposedSchedules');
            params.set('csrfToken', document.querySelector('input[name="csrfToken"]').value);

            const conflictOption = document.querySelector('input[name="conflictHandling"]:checked');
            if (conflictOption) {
                params.set('conflictHandling', conflictOption.value);
            }

            selects.forEach(select => {
                const index = parseInt(select.getAttribute('data-index'));
                const item = proposedSchedules[index];
                const selectedDoctorId = select.value;

                params.append('doctorId', selectedDoctorId);
                params.append('workDate', item.workDate);
                params.append('timeSlot', item.timeSlot);
                params.append('maxPatients', maxPatientsInput.value);
            });

            setAiScheduleBusy(true);
            try {
                const response = await fetch(adminScheduleEndpoint, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                        'Accept': 'application/json'
                    },
                    body: params.toString()
                });
                if (!response.ok) throw new Error('HTTP ' + response.status);
                const data = await response.json();
                showAiScheduleMessage(data.message || 'Đã lưu lịch trực.', data.success);
                if (data.success) {
                    window.setTimeout(() => {
                        const modalEl = document.getElementById('aiScheduleModal');
                        const instance = bootstrap.Modal.getInstance(modalEl);
                        if (instance) instance.hide();
                        window.location.reload();
                    }, 1200);
                }
            } catch (err) {
                showAiScheduleMessage('Không thể lưu lịch trực đề xuất: ' + err.message, false);
            } finally {
                setAiScheduleBusy(false);
            }
        });
    }

    initUniversalModal('Doctor');
    updateTemplatePreview();

    // ==========================================
    // 4. BỘ ĐIỀU HƯỚNG LỊCH TRỰC TUẦN (WEEKLY CALENDAR)
    // ==========================================

    function getMondayOfDate(d) {
        if (!d) return new Date();
        if (typeof d === 'string') {
            const parts = d.split('-');
            if (parts.length === 3) {
                const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
                const day = date.getDay();
                const diff = date.getDate() - day + (day === 0 ? -6 : 1);
                date.setDate(diff);
                return date;
            }
        }
        const date = new Date(d);
        const day = date.getDay();
        const diff = date.getDate() - day + (day === 0 ? -6 : 1);
        return new Date(date.setDate(diff));
    }

    function formatDateIso(d) {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    function formatDateDisplay(d) {
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${day}/${month}`;
    }

    const weekPicker = document.getElementById('calendarWeekPicker');
    const unifiedWeekPickerEl = document.getElementById('unifiedWeekPicker') || document.getElementById('calendarWeekPicker');
    if (unifiedWeekPickerEl) {
        const todayStr = formatDateIso(new Date());
        if (!unifiedWeekPickerEl.value) {
            unifiedWeekPickerEl.value = todayStr;
        }

        const bindClick = (id, fn) => {
            const el = document.getElementById(id);
            if (el) el.addEventListener('click', fn);
        };

        bindClick('unifiedTodayBtn', () => {
            unifiedWeekPickerEl.value = formatDateIso(new Date());
            loadWeeklyCalendar();
        });
        bindClick('calTodayBtn', () => {
            unifiedWeekPickerEl.value = formatDateIso(new Date());
            loadWeeklyCalendar();
        });

        bindClick('unifiedPrevWeekBtn', () => {
            const cur = new Date(unifiedWeekPickerEl.value || new Date());
            cur.setDate(cur.getDate() - 7);
            unifiedWeekPickerEl.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });
        bindClick('calPrevWeekBtn', () => {
            const cur = new Date(unifiedWeekPickerEl.value || new Date());
            cur.setDate(cur.getDate() - 7);
            unifiedWeekPickerEl.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });

        bindClick('unifiedNextWeekBtn', () => {
            const cur = new Date(unifiedWeekPickerEl.value || new Date());
            cur.setDate(cur.getDate() + 7);
            unifiedWeekPickerEl.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });
        bindClick('calNextWeekBtn', () => {
            const cur = new Date(unifiedWeekPickerEl.value || new Date());
            cur.setDate(cur.getDate() + 7);
            unifiedWeekPickerEl.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });

        unifiedWeekPickerEl.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('unifiedRoleFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('unifiedRoomFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calendarRoleFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calendarRoomFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calFilterSubmitBtn')?.addEventListener('click', loadWeeklyCalendar);

        document.getElementById('viewModeCalendarBtn')?.addEventListener('click', () => {
            setTimeout(loadWeeklyCalendar, 50);
        });

        if (!document.getElementById('weeklyCalendarPane')?.hasAttribute('hidden')) {
            loadWeeklyCalendar();
        }
    }

    // Tải dữ liệu lịch tuần qua AJAX
    async function loadWeeklyCalendar() {
        window.loadWeeklyCalendar = loadWeeklyCalendar;
        const picker = document.getElementById('unifiedWeekPicker') || document.getElementById('calendarWeekPicker');
        if (!picker) return;

        if (!picker.value) {
            picker.value = new Date().toISOString().slice(0, 10);
        }

        const baseDate = new Date(picker.value);
        const monday = getMondayOfDate(baseDate);

        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        const datesMap = {};

        days.forEach((dayKey, idx) => {
            const dateObj = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + idx);
            const isoStr = formatDateIso(dateObj);
            datesMap[dayKey] = isoStr;

            const el = document.getElementById(`date-head-${dayKey}`);
            if (el) el.textContent = formatDateDisplay(dateObj);
        });

        days.forEach(dayKey => {
            ['0800', '1300'].forEach(timeKey => {
                const cell = document.getElementById(`cell-${dayKey}-${timeKey}`);
                if (cell) cell.innerHTML = '';
            });
        });

        const roleFilterEl = document.getElementById('unifiedRoleFilter') || document.getElementById('calendarRoleFilter');
        const roomFilterEl = document.getElementById('unifiedRoomFilter') || document.getElementById('calendarRoomFilter');

        const role = roleFilterEl ? roleFilterEl.value : 'all';
        const room = roomFilterEl ? roomFilterEl.value : 'all';

        try {
            const url = `${adminContextPath}/admin?action=getCalendarSchedule&weekDate=${encodeURIComponent(picker.value)}&role=${encodeURIComponent(role)}&room=${encodeURIComponent(room)}`;
            const resp = await fetch(url, { headers: { 'Accept': 'application/json' } });
            if (!resp.ok) throw new Error('HTTP ' + resp.status);
            const data = await resp.json();
            currentWeeklySchedules = Array.isArray(data) ? data : [];
            renderWeeklyCalendarCards(currentWeeklySchedules, datesMap, role);
        } catch (err) {
            console.error('Failed to load weekly calendar', err);
        }
    }

    // Vẽ các thẻ trực Bác sĩ/Lễ tân lên lưới lịch trực tuần
    function renderWeeklyCalendarCards(schedules, datesMap, activeRole) {
        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        const daysMapByDate = {};
        Object.keys(datesMap).forEach(key => {
            daysMapByDate[datesMap[key]] = key;
        });

        let hasConflict = false;

        // Lọc client-side theo role nếu được chọn
        if (activeRole && activeRole !== 'all') {
            const targetRoleLower = activeRole.toLowerCase();
            schedules = schedules.filter(shift => {
                const r = (shift.role || '').toLowerCase();
                if (targetRoleLower === 'doctor') return r.includes('doctor') || r.includes('bác sĩ khám');
                if (targetRoleLower === 'receptionist' || targetRoleLower === 'reception') return r.includes('reception') || r.includes('lễ tân');
                if (targetRoleLower === 'doctor_lab' || targetRoleLower === 'lab') return r.includes('lab') || r.includes('xét nghiệm');
                return r === targetRoleLower;
            });
        }

        // Nhóm các ca trực theo ô (Cell)
        const shiftsByCell = {};
        schedules.forEach(shift => {
            const dayKey = daysMapByDate[shift.date];
            if (!dayKey) return;
            const isMorning = (shift.start === '08:00' || (shift.timeSlot && shift.timeSlot.toLowerCase().includes('morning')));
            const timeKey = isMorning ? '0800' : '1300';
            const cellId = `cell-${dayKey}-${timeKey}`;
            if (!shiftsByCell[cellId]) {
                shiftsByCell[cellId] = [];
            }
            shiftsByCell[cellId].push(shift);
            if (shift.conflict) hasConflict = true;
        });

        // Clear tất cả các ô cell trước khi render
        days.forEach(dayKey => {
            ['0800', '1300'].forEach(timeKey => {
                const cell = document.getElementById(`cell-${dayKey}-${timeKey}`);
                if (cell) cell.innerHTML = '';
            });
        });

        // Render từng ô cell với giới hạn tối đa 2 thẻ
        Object.keys(shiftsByCell).forEach(cellId => {
            const cell = document.getElementById(cellId);
            if (!cell) return;
            const listInCell = shiftsByCell[cellId];
            const maxVisible = 2;
            const visibleShifts = listInCell.slice(0, maxVisible);
            const extraCount = listInCell.length - maxVisible;

            visibleShifts.forEach(shift => {
                const card = document.createElement('div');
                card.className = `shift-card role-${shift.role || 'Doctor'} ${shift.conflict ? 'is-conflict' : ''} ${shift.isPreview ? 'is-preview' : ''}`;

                const conflictBadge = shift.conflict ? '<span class="badge bg-danger-subtle text-danger border border-danger-subtle ms-1" style="font-size:0.65rem;" title="' + escapeHtml(shift.conflictMessage || 'Trùng lịch') + '">⚠ Trùng</span>' : '';
                const previewBadge = shift.isPreview ? '<span class="badge bg-purple-subtle text-purple ms-1" style="font-size:0.65rem;">AI gợi ý</span>' : '';

                card.innerHTML = `
                    <div class="fw-bold d-flex justify-content-between align-items-center mb-1">
                        <span class="text-truncate">${escapeHtml(shift.staff)}</span>
                        ${conflictBadge} ${previewBadge}
                    </div>
                    <div class="text-secondary small mb-1" style="font-size: 0.72rem;">
                        <i class="bi bi-person-badge me-1"></i>${escapeHtml(shift.role)}
                    </div>
                    <div class="text-dark small fw-semibold text-truncate" style="font-size: 0.72rem;">
                        <i class="bi bi-geo-alt me-1 text-danger"></i>${escapeHtml(shift.room || 'Chưa xếp')}
                    </div>
                `;

                card.addEventListener('click', () => openShiftDetailModal(shift));
                cell.appendChild(card);
            });

            if (extraCount > 0) {
                const moreBtn = document.createElement('div');
                moreBtn.className = 'btn-more-shifts mt-1 text-center py-1 bg-purple-subtle text-purple fw-bold rounded border border-purple-subtle cursor-pointer';
                moreBtn.style.fontSize = '0.72rem';
                moreBtn.style.cursor = 'pointer';
                moreBtn.innerHTML = `<i class="fa-solid fa-layer-group me-1"></i>+${extraCount} nhân sự khác`;
                moreBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    openCellMoreSchedulesModal(cellId, listInCell);
                });
                cell.appendChild(moreBtn);
            }
        });

        const alertEl = document.getElementById('calendarConflictAlert');
        if (alertEl) {
            if (hasConflict) {
                alertEl.classList.remove('d-none');
                alertEl.classList.add('d-flex');
            } else {
                alertEl.classList.add('d-none');
                alertEl.classList.remove('d-flex');
            }
        }
    }

    // Mở modal xem thông tin ca trực chi tiết trên Calendar tuần
    function openShiftDetailModal(shift) {
        const staffEl = document.getElementById('shiftDetailStaff');
        const roleEl = document.getElementById('shiftDetailRole');
        const roomEl = document.getElementById('shiftDetailRoom');
        const dateEl = document.getElementById('shiftDetailDate');
        const timeEl = document.getElementById('shiftDetailTime');
        const statusEl = document.getElementById('shiftDetailStatus');
        const editBtn = document.getElementById('shiftDetailEditBtn');

        if (staffEl) staffEl.textContent = shift.staff || '-';
        if (roleEl) roleEl.textContent = shift.role || '-';
        if (roomEl) roomEl.textContent = shift.room || 'Chưa xếp';
        if (dateEl) dateEl.textContent = shift.date || '-';
        
        const timeText = (shift.start && shift.end) 
            ? `${shift.start} - ${shift.end}` 
            : (shift.timeSlot || 'Ca trực');
        if (timeEl) timeEl.textContent = timeText;
        if (statusEl) statusEl.textContent = shift.status || 'Đã xếp lịch';

        if (editBtn) {
            const schId = shift.scheduleId || shift.id || '';
            if (schId) {
                editBtn.setAttribute('data-schedule-id', schId);
                editBtn.style.display = 'inline-block';
            } else {
                editBtn.removeAttribute('data-schedule-id');
                editBtn.style.display = 'none';
            }
        }

        const alertEl = document.getElementById('shiftDetailConflictAlert');
        const textEl = document.getElementById('shiftDetailConflictText');
        if (alertEl && textEl) {
            if (shift.conflict) {
                alertEl.classList.remove('d-none');
                textEl.textContent = shift.conflictMessage || 'Phát hiện ca làm việc trùng nhân sự hoặc trùng phòng!';
            } else {
                alertEl.classList.add('d-none');
            }
        }

        const modalEl = document.getElementById('shiftDetailModal');
        if (modalEl) {
            const modal = new bootstrap.Modal(modalEl);
            modal.show();
        }
    }

    window.openShiftDetailModal = openShiftDetailModal;

    // Mở Modal xem danh sách đầy đủ ca trực trong 1 ô ngày/ca
    function openCellMoreSchedulesModal(cellId, listInCell) {
        const modalEl = document.getElementById('cellMoreSchedulesModal');
        const container = document.getElementById('cellMoreSchedulesList');
        if (!modalEl || !container) return;

        let html = '';
        listInCell.forEach((shift, index) => {
            const conflictBadge = shift.conflict ? '<span class="badge bg-danger-subtle text-danger border border-danger-subtle ms-2">⚠ Trùng lịch</span>' : '';
            html += `<div class="p-3 mb-2 rounded border ${shift.conflict ? 'border-danger bg-danger-subtle' : 'bg-light'} d-flex justify-content-between align-items-center">
                <div>
                    <div class="fw-bold text-dark"><i class="fa-solid fa-user-doctor me-2 text-primary"></i>${escapeHtml(shift.staff)} ${conflictBadge}</div>
                    <div class="small text-secondary mt-1"><i class="fa-solid fa-hospital-user me-1 text-danger"></i>${escapeHtml(shift.room || 'Chưa xếp')} | Khung giờ: ${escapeHtml(shift.timeSlot || shift.start)}</div>
                </div>
                <button type="button" class="btn btn-sm btn-outline-primary fw-bold px-3" onclick="openShiftDetailModalFromMore('${index}')">Chi tiết</button>
            </div>`;
        });
        container.innerHTML = html;

        // Lưu tạm danh sách hiện tại để gọi detail
        window.currentCellMoreList = listInCell;

        const modal = new bootstrap.Modal(modalEl);
        modal.show();
    }

    window.openShiftDetailModalFromMore = function (index) {
        if (window.currentCellMoreList && window.currentCellMoreList[index]) {
            openShiftDetailModal(window.currentCellMoreList[index]);
        }
    };

    // Mở Modal Tháo gỡ xung đột ca trực 1-Click
    window.openResolveConflictModal = function () {
        const modalEl = document.getElementById('resolveConflictModal');
        const container = document.getElementById('resolveConflictList');
        if (!modalEl || !container) return;

        const conflictShifts = currentWeeklySchedules.filter(s => s.conflict);
        if (conflictShifts.length === 0) {
            container.innerHTML = '<div class="alert alert-success mb-0 text-center fw-bold"><i class="fa-solid fa-circle-check me-2"></i>Không có xung đột nào cần tháo gỡ! Lịch làm việc tuần này hoàn toàn hợp lệ.</div>';
        } else {
            let html = '';
            conflictShifts.forEach(shift => {
                html += `<div class="p-3 rounded border border-danger-subtle bg-danger-subtle d-flex justify-content-between align-items-center flex-wrap gap-2 mb-2">
                    <div>
                        <div class="fw-bold text-danger mb-1"><i class="fa-solid fa-circle-exclamation me-1"></i>${escapeHtml(shift.staff)} (${escapeHtml(shift.role)})</div>
                        <div class="small text-dark mb-1"><i class="fa-solid fa-hospital-user me-1"></i>Phòng: ${escapeHtml(shift.room || 'Chưa xếp')} | Ngày: ${escapeHtml(shift.date)} (${escapeHtml(shift.timeSlot || shift.start)})</div>
                        <div class="small text-danger fw-semibold"><i class="fa-solid fa-info-circle me-1"></i>Lý do: ${escapeHtml(shift.conflictMessage || 'Trùng phòng hoặc trùng bác sĩ')}</div>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="button" class="btn btn-sm btn-outline-danger fw-bold" onclick="resolveSingleConflict('${shift.id}', '${shift.staffType}', 'delete')"><i class="fa-solid fa-trash-can me-1"></i>Hủy ca</button>
                        <button type="button" class="btn btn-sm btn-primary fw-bold" onclick="resolveSingleConflict('${shift.id}', '${shift.staffType}', 'reassign')"><i class="fa-solid fa-shuffle me-1"></i>Đổi phòng trống</button>
                    </div>
                </div>`;
            });
            container.innerHTML = html;
        }

        const modal = new bootstrap.Modal(modalEl);
        modal.show();
    };

    window.resolveSingleConflict = async function (id, staffType, actionType) {
        try {
            const formData = new URLSearchParams();
            formData.append('action', 'resolveScheduleConflict');
            formData.append('id', id);
            formData.append('staffType', staffType);
            formData.append('type', actionType);

            const resp = await fetch(`${adminContextPath}/admin`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'Accept': 'application/json' },
                body: formData.toString()
            });
            const data = await resp.json();
            if (data.success) {
                loadWeeklyCalendar();
                const modalEl = document.getElementById('resolveConflictModal');
                if (modalEl) {
                    const modal = bootstrap.Modal.getInstance(modalEl);
                    if (modal) modal.hide();
                }
            } else {
                alert(data.message || 'Không thể xử lý xung đột');
            }
        } catch (e) {
            console.error('Failed to resolve single conflict', e);
        }
    };

    const autoResolveBtn = document.getElementById('autoResolveAllConflictsBtn');
    if (autoResolveBtn) {
        autoResolveBtn.addEventListener('click', async () => {
            try {
                const formData = new URLSearchParams();
                formData.append('action', 'autoResolveAllConflicts');

                const resp = await fetch(`${adminContextPath}/admin`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'Accept': 'application/json' },
                    body: formData.toString()
                });
                const data = await resp.json();
                if (data.success) {
                    loadWeeklyCalendar();
                    const modalEl = document.getElementById('resolveConflictModal');
                    if (modalEl) {
                        const modal = bootstrap.Modal.getInstance(modalEl);
                        if (modal) modal.hide();
                    }
                } else {
                    alert(data.message || 'Không thể tự động sửa ca trùng');
                }
            } catch (e) {
                console.error('Failed to auto resolve conflicts', e);
            }
        });
    }

    // Gán sự kiện cho picker tuần và bộ lọc role/room
    const unifiedWeekPicker = document.getElementById('unifiedWeekPicker') || document.getElementById('calendarWeekPicker');
    if (unifiedWeekPicker) {
        unifiedWeekPicker.addEventListener('change', loadWeeklyCalendar);
        if (!unifiedWeekPicker.value) {
            unifiedWeekPicker.value = new Date().toISOString().slice(0, 10);
        }
    }

    const unifiedRoleFilter = document.getElementById('unifiedRoleFilter') || document.getElementById('calendarRoleFilter');
    if (unifiedRoleFilter) {
        unifiedRoleFilter.addEventListener('change', loadWeeklyCalendar);
    }

    const unifiedRoomFilter = document.getElementById('unifiedRoomFilter') || document.getElementById('calendarRoomFilter');
    if (unifiedRoomFilter) {
        unifiedRoomFilter.addEventListener('change', loadWeeklyCalendar);
    }

    // Tự động nạp Weekly Calendar ban đầu
    loadWeeklyCalendar();
});
