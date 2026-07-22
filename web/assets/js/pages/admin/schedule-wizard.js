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
let currentStep = 1;

// ==========================================
// 2. SHIFT TEMPLATE & CAPACITY CALCULATION HELPERS
// ==========================================

/**
 * Đếm số lượng ca trực trong tệp cấu hình thô mẫu ca trực
 * @returns {number} Số ca trực
 */
function countShiftTemplateLines() {
    const textarea = document.querySelector('textarea[name="shiftTemplates"]');
    return textarea ? textarea.value.split(/\r?\n/).filter(line => line.trim().includes('|')).length : 0;
}

/**
 * Xây dựng danh sách ca trực dựa vào giờ bắt đầu, kết thúc, và chuyên khoa đã chọn
 * @returns {Array<string>} Mảng ca trực dạng "timeSlot|department"
 */
function buildCustomShiftTemplate() {
    const startTimeInput = document.getElementById('aiStartTime');
    const endTimeInput = document.getElementById('aiEndTime');
    const slotDurationInput = document.getElementById('aiSlotDuration');
    const deptList = document.getElementById('aiDepartmentList');

    if (!startTimeInput || !endTimeInput || !slotDurationInput || !deptList) {
        return [];
    }

    const startTime = startTimeInput.value;
    const endTime = endTimeInput.value;
    const slotMinutes = parseInt(slotDurationInput.value);

    if (!startTime || !endTime || isNaN(slotMinutes)) {
        return [];
    }

    const departments = Array.from(deptList.querySelectorAll('.badge'))
        .map(badge => badge.getAttribute('data-dept'))
        .filter(dept => dept);

    if (departments.length === 0) {
        return [];
    }

    const slots = [];
    try {
        const [startHour, startMin] = startTime.split(':').map(Number);
        const [endHour, endMin] = endTime.split(':').map(Number);

        let currentMinutes = startHour * 60 + startMin;
        const endMinutes = endHour * 60 + endMin;
        let deptIndex = 0;

        while (currentMinutes + slotMinutes <= endMinutes) {
            const slotStart = Math.floor(currentMinutes / 60);
            const slotStartMin = currentMinutes % 60;
            const slotEnd = Math.floor((currentMinutes + slotMinutes) / 60);
            const slotEndMin = (currentMinutes + slotMinutes) % 60;

            const timeSlot = String(slotStart).padStart(2, '0') + ':' + String(slotStartMin).padStart(2, '0')
                + '-' + String(slotEnd).padStart(2, '0') + ':' + String(slotEndMin).padStart(2, '0');

            const dept = departments[deptIndex % departments.length];
            slots.push(timeSlot + '|' + dept);

            currentMinutes += slotMinutes;
            deptIndex++;
        }
    } catch (e) {
        console.error('Error building custom shift template:', e);
    }

    return slots;
}

/**
 * Cập nhật hiển thị bản xem trước của khuôn mẫu ca trực trong Textarea cấu hình thô
 */
function updateTemplatePreview() {
    const textarea = document.querySelector('textarea[name="shiftTemplates"]');
    if (textarea) {
        const slots = buildCustomShiftTemplate();
        textarea.value = slots.join('\n');
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
 * Lấy số lượng bác sĩ phân bổ trực cho mỗi ca từ ô nhập liệu
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
    if (!startDate || !endDate || !maxSchedules || !startDate.value || !endDate.value) {
        return;
    }
    const days = countSelectedTargetDates(startDate.value, endDate.value);
    const shifts = countShiftTemplateLines();
    const doctorsPerShift = getDoctorsPerShift();
    const total = days * shifts * doctorsPerShift;
    maxSchedules.value = total;
    if (summary) {
        summary.textContent = 'Hệ thống sẽ tạo ra: ' + days + ' ngày x ' + shifts
            + ' ca x ' + doctorsPerShift + ' bác sĩ/ca = ' + total
            + ' slot lịch trực, sau đó Gemini điền bác sĩ.';
    }
}


// ==========================================
// 3. WIZARD INTERFACES & UI PROGRESS STEPS
// ==========================================

/**
 * Chuyển giao diện nút bấm và trạng thái khi đang lưu lịch trực AI
 * @param {boolean} isBusy 
 */
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
            ? '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Gemini đang phân bổ...'
            : '<i class="fa-solid fa-rocket me-2"></i>Tiến hành phân bổ bằng AI';
    }
    if (loadingBox) {
        loadingBox.classList.toggle('d-none', !isBusy);
        loadingBox.classList.toggle('d-flex', isBusy);
    }
    if (detail) {
        detail.textContent = isBusy ? 'Đang ghi lịch trực thật vào hệ thống...' : '';
    }
}

/**
 * Hiển thị thông báo trên Modal lập lịch thông minh
 * @param {string} message 
 * @param {boolean} isSuccess 
 */
function showAiScheduleMessage(message, isSuccess) {
    const alertBox = document.getElementById('aiScheduleModalAlert');
    if (!alertBox) {
        return;
    }
    alertBox.className = 'alert border-0 fw-semibold ' + (isSuccess ? 'alert-success' : 'alert-danger');
    alertBox.innerHTML = '<i class="fa-solid ' + (isSuccess ? 'fa-circle-check' : 'fa-triangle-exclamation') + ' me-2"></i>' + escapeHtmlForSchedule(message);
}

/**
 * Trích xuất danh sách ca trực được tạo ra bởi AI và đẩy lên hàng đầu của bảng ca trực bác sĩ khám
 * @param {Array<Object>} schedules 
 */
function appendCreatedSchedules(schedules) {
    const tbody = document.getElementById('scheduleTableBody');
    if (!tbody || !Array.isArray(schedules) || schedules.length === 0) {
        return;
    }
    const emptyRow = tbody.querySelector('td[colspan="10"]');
    if (emptyRow) {
        emptyRow.closest('tr').remove();
    }
    tbody.insertAdjacentHTML('afterbegin', schedules.map(buildScheduleRow).join(''));
}

/**
 * Dựng chuỗi HTML cho một hàng của lịch trực
 * @param {Object} schedule 
 * @returns {string} HTML string
 */
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
    const startTimeInput = document.getElementById('aiStartTime');
    const endTimeInput = document.getElementById('aiEndTime');
    const slotDurationInput = document.getElementById('aiSlotDuration');
    const visitDurationInput = document.getElementById('aiVisitDuration');
    const maxPatientsInput = document.getElementById('aiMaxPatients');
    const departmentSelect = document.getElementById('aiDepartmentSelect');
    const addDepartmentBtn = document.getElementById('aiAddDepartmentBtn');
    const departmentList = document.getElementById('aiDepartmentList');

    const prevBtn = document.getElementById('aiWizardPrevBtn');
    const nextBtn = document.getElementById('aiWizardNextBtn');
    const submitBtn = document.getElementById('aiScheduleSubmitBtn');

    // Cập nhật trạng thái tick chọn ngày trong tuần tương ứng với phạm vi ngày
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
            const container = cb.closest('.form-check');
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
        if (input) {
            input.addEventListener('change', updateWeekdayStates);
        }
    });
    updateWeekdayStates();

    // Cập nhật nhãn thông tin tải lượng khám tối đa dựa trên thời gian
    function updateWorkloadInfo() {
        if (!slotDurationInput || !visitDurationInput || !maxPatientsInput) return;
        const slotMin = parseInt(slotDurationInput.value) || 60;
        const visitMin = parseInt(visitDurationInput.value) || 15;
        const maxPatients = Math.floor(slotMin / visitMin);
        maxPatientsInput.value = maxPatients;
        const workloadInfo = document.getElementById('aiWorkloadCalcInfo');
        if (workloadInfo) {
            workloadInfo.innerHTML = '<i class="bi bi-calculator me-1"></i>Số bệnh nhân tối đa mỗi ca: ' + maxPatients + ' lượt khám (' + slotMin + ' phút / ' + visitMin + ' phút).';
        }
        updateAiMaxSchedules();
    }

    [slotDurationInput, visitDurationInput].forEach(input => {
        if (input) {
            input.addEventListener('change', updateWorkloadInfo);
        }
    });
    updateWorkloadInfo();

    // Thêm chuyên khoa áp dụng ca trực
    if (addDepartmentBtn && departmentSelect && departmentList) {
        addDepartmentBtn.addEventListener('click', function () {
            const dept = departmentSelect.value;
            if (!dept) return;
            const exists = Array.from(departmentList.querySelectorAll('.badge'))
                .some(badge => badge.getAttribute('data-dept') === dept);
            if (!exists) {
                const badge = document.createElement('span');
                badge.className = 'badge bg-purple-subtle text-purple border border-purple-subtle cursor-pointer';
                badge.style = 'background:#f3e8ff; color:#6b21a8; border-color:#e9d5ff;';
                badge.setAttribute('data-dept', dept);
                badge.textContent = dept + ' ✕';
                departmentList.appendChild(badge);
                updateTemplatePreview();
            }
        });
    }

    // Xóa chuyên khoa khi bấm dấu X
    if (departmentList) {
        departmentList.addEventListener('click', function (e) {
            if (e.target.classList.contains('badge')) {
                e.target.remove();
                updateTemplatePreview();
            }
        });
    }

    [startTimeInput, endTimeInput, slotDurationInput].forEach(element => {
        if (element) {
            element.addEventListener('change', updateTemplatePreview);
            element.addEventListener('input', updateTemplatePreview);
        }
    });
    document.querySelectorAll('input[name="selectedWeekdays"]').forEach(cb => {
        cb.addEventListener('change', updateAiMaxSchedules);
    });

    // Quản lý hiển thị của stepper panel
    function showStep(step) {
        currentStep = step;

        for (let i = 1; i <= 3; i++) {
            const indicator = document.getElementById('indicator' + i);
            if (indicator) {
                const stepNum = indicator.querySelector('.step-num');
                if (i < step) {
                    indicator.className = 'wizard-step-indicator completed';
                    if (stepNum) {
                        stepNum.style.background = '#10b981';
                        stepNum.style.borderColor = '#10b981';
                        stepNum.style.color = '#fff';
                        stepNum.innerHTML = '<i class="bi bi-check-lg"></i>';
                    }
                } else if (i === step) {
                    indicator.className = 'wizard-step-indicator active';
                    if (stepNum) {
                        stepNum.style.background = '#7c3aed';
                        stepNum.style.borderColor = '#7c3aed';
                        stepNum.style.color = '#fff';
                        stepNum.innerHTML = i;
                    }
                } else {
                    indicator.className = 'wizard-step-indicator';
                    if (stepNum) {
                        stepNum.style.background = '#fff';
                        stepNum.style.borderColor = '#cbd5e1';
                        stepNum.style.color = '#cbd5e1';
                        stepNum.innerHTML = i;
                    }
                }
            }
        }

        const s1 = document.getElementById('aiWizardStep1');
        const s2 = document.getElementById('aiWizardStep2');
        const s3 = document.getElementById('aiWizardStep3');
        if (s1) s1.classList.toggle('d-none', step !== 1);
        if (s2) s2.classList.toggle('d-none', step !== 2);
        if (s3) s3.classList.toggle('d-none', step !== 3);

        if (step === 1) {
            if (prevBtn) prevBtn.style.display = 'none';
            if (nextBtn) {
                nextBtn.style.display = 'inline-block';
                nextBtn.innerHTML = 'Tiếp tục <i class="bi bi-arrow-right ms-1"></i>';
            }
            if (submitBtn) submitBtn.style.display = 'none';
        } else if (step === 2) {
            if (prevBtn) prevBtn.style.display = 'inline-block';
            if (nextBtn) {
                nextBtn.style.display = 'inline-block';
                nextBtn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles me-1"></i> Tạo đề xuất AI';
            }
            if (submitBtn) submitBtn.style.display = 'none';
        } else if (step === 3) {
            if (prevBtn) prevBtn.style.display = 'inline-block';
            if (nextBtn) nextBtn.style.display = 'none';
            if (submitBtn) submitBtn.style.display = 'inline-block';
        }
    }

    if (prevBtn) {
        prevBtn.addEventListener('click', function () {
            if (currentStep > 1) {
                showStep(currentStep - 1);
            }
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener('click', async function () {
            if (currentStep === 1) {
                if (!startDate.value || !endDate.value) {
                    showAiScheduleMessage('Vui lòng chọn khoảng ngày.', false);
                    return;
                }
                if (getSelectedWeekdays().length === 0) {
                    showAiScheduleMessage('Vui lòng chọn ít nhất một ngày áp dụng trong tuần.', false);
                    return;
                }
                showStep(2);
            } else if (currentStep === 2) {
                const depts = Array.from(departmentList.querySelectorAll('.badge'))
                    .map(badge => badge.getAttribute('data-dept'));
                if (depts.length === 0) {
                    showAiScheduleMessage('Vui lòng chọn ít nhất một chuyên khoa.', false);
                    return;
                }
                showStep(3);
                await generateProposal();
            }
        });
    }

    // Gọi AJAX lấy dữ liệu đề xuất từ thuật toán AI
    async function generateProposal() {
        const loader = document.getElementById('aiProposalLoading');
        const container = document.getElementById('aiProposalTableContainer');

        if (loader) loader.classList.remove('d-none');
        if (container) container.classList.add('d-none');

        if (startTimeInput && endTimeInput && slotDurationInput) {
            document.querySelector('input[name="startTime"]').value = startTimeInput.value || '07:00';
            document.querySelector('input[name="endTime"]').value = endTimeInput.value || '17:00';
            document.querySelector('input[name="slotMinutes"]').value = slotDurationInput.value || '60';
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
            if (!response.ok) {
                throw new Error('HTTP ' + response.status);
            }
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.message || 'Lỗi không xác định.');
            }

            proposedSchedules = data.items || [];
            availableDoctors = data.doctors || [];

            renderProposalTable();

            if (loader) loader.classList.add('d-none');
            if (container) container.classList.remove('d-none');
        } catch (err) {
            showAiScheduleMessage('Không thể tạo đề xuất AI: ' + err.message, false);
            showStep(2);
        }
    }

    // Kết xuất bảng xem trước đề xuất phân ca của AI
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

    // Submit xác nhận và lưu danh sách lịch trực AI đề xuất
    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();

            if (currentStep !== 3 || proposedSchedules.length === 0) {
                return;
            }

            const selects = document.querySelectorAll('.proposed-doctor-select');
            const params = new URLSearchParams();
            params.set('action', 'aiSaveProposedSchedules');
            params.set('csrfToken', document.querySelector('input[name="csrfToken"]').value);

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
                if (!response.ok) {
                    throw new Error('HTTP ' + response.status);
                }
                const data = await response.json();
                showAiScheduleMessage(data.message || 'Đã lưu lịch trực.', data.success);
                if (data.success) {
                    window.setTimeout(() => {
                        const modalEl = document.getElementById('aiScheduleModal');
                        const instance = bootstrap.Modal.getInstance(modalEl);
                        if (instance) {
                            instance.hide();
                        }
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

    updateTemplatePreview();

    // ==========================================
    // 4. BỘ ĐIỀU HƯỚNG LỊCH TRỰC TUẦN (WEEKLY CALENDAR)
    // ==========================================
    let currentWeeklySchedules = [];

    function getMondayOfDate(d) {
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
    if (weekPicker) {
        const todayStr = formatDateIso(new Date());
        weekPicker.value = todayStr;

        document.getElementById('calTodayBtn')?.addEventListener('click', () => {
            weekPicker.value = formatDateIso(new Date());
            loadWeeklyCalendar();
        });

        document.getElementById('calPrevWeekBtn')?.addEventListener('click', () => {
            const cur = new Date(weekPicker.value || new Date());
            cur.setDate(cur.getDate() - 7);
            weekPicker.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });

        document.getElementById('calNextWeekBtn')?.addEventListener('click', () => {
            const cur = new Date(weekPicker.value || new Date());
            cur.setDate(cur.getDate() + 7);
            weekPicker.value = formatDateIso(cur);
            loadWeeklyCalendar();
        });

        weekPicker.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calendarRoleFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calendarRoomFilter')?.addEventListener('change', loadWeeklyCalendar);
        document.getElementById('calFilterSubmitBtn')?.addEventListener('click', loadWeeklyCalendar);

        document.getElementById('weekly-calendar-tab')?.addEventListener('click', () => {
            setTimeout(loadWeeklyCalendar, 50);
        });

        if (!document.getElementById('weeklyCalendarPane')?.hasAttribute('hidden')) {
            loadWeeklyCalendar();
        }
    }

    // Tải dữ liệu lịch tuần qua AJAX
    async function loadWeeklyCalendar() {
        const picker = document.getElementById('calendarWeekPicker');
        if (!picker) return;

        const baseDate = new Date(picker.value || new Date());
        const monday = getMondayOfDate(baseDate);

        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        const datesMap = {};

        days.forEach((dayKey, idx) => {
            const dateObj = new Date(monday);
            dateObj.setDate(monday.getDate() + idx);
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

        const role = document.getElementById('calendarRoleFilter')?.value || 'all';
        const room = document.getElementById('calendarRoomFilter')?.value || 'all';

        try {
            const url = `${adminContextPath}/admin?action=getCalendarSchedule&weekDate=${encodeURIComponent(picker.value)}&role=${encodeURIComponent(role)}&room=${encodeURIComponent(room)}`;
            const resp = await fetch(url, { headers: { 'Accept': 'application/json' } });
            if (!resp.ok) throw new Error('HTTP ' + resp.status);
            const data = await resp.json();
            currentWeeklySchedules = Array.isArray(data) ? data : [];
            renderWeeklyCalendarCards(currentWeeklySchedules, datesMap);
        } catch (err) {
            console.error('Failed to load weekly calendar', err);
        }
    }

    // Vẽ các thẻ trực Bác sĩ/Lễ tân lên lưới lịch trực tuần
    function renderWeeklyCalendarCards(schedules, datesMap) {
        const daysMapByDate = {};
        Object.keys(datesMap).forEach(key => {
            daysMapByDate[datesMap[key]] = key;
        });

        let hasConflict = false;

        schedules.forEach(shift => {
            const dayKey = daysMapByDate[shift.date];
            if (!dayKey) return;

            const isMorning = (shift.start === '08:00' || (shift.timeSlot && shift.timeSlot.toLowerCase().includes('morning')));
            const timeKey = isMorning ? '0800' : '1300';
            const cell = document.getElementById(`cell-${dayKey}-${timeKey}`);
            if (!cell) return;

            if (shift.conflict) hasConflict = true;

            const card = document.createElement('div');
            card.className = `shift-card role-${shift.role || 'Doctor'} ${shift.conflict ? 'is-conflict' : ''} ${shift.isPreview ? 'is-preview' : ''}`;

            const conflictBadge = shift.conflict ? '<span class="badge bg-danger ms-1" style="font-size:0.65rem;">⚠ Trùng</span>' : '';
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
        document.getElementById('shiftDetailStaff').textContent = shift.staff || '-';
        document.getElementById('shiftDetailRole').textContent = shift.role || '-';
        document.getElementById('shiftDetailRoom').textContent = shift.room || 'Chưa xếp';
        document.getElementById('shiftDetailDate').textContent = shift.date || '-';
        document.getElementById('shiftDetailTime').textContent = `${shift.start || '08:00'} - ${shift.end || '12:00'} (${shift.timeSlot || ''})`;
        document.getElementById('shiftDetailStatus').textContent = shift.status || 'Confirmed';

        const alertEl = document.getElementById('shiftDetailConflictAlert');
        const textEl = document.getElementById('shiftDetailConflictText');
        if (shift.conflict) {
            alertEl.classList.remove('d-none');
            textEl.textContent = shift.conflictMessage || 'Phát hiện ca làm việc trùng nhân sự hoặc trùng phòng!';
        } else {
            alertEl.classList.add('d-none');
        }

        const modalEl = document.getElementById('shiftDetailModal');
        const modal = new bootstrap.Modal(modalEl);
        modal.show();
    }
});
