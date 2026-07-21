const adminContextPath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
const adminCsrfToken = window.AdminConfig && window.AdminConfig.csrfToken ? window.AdminConfig.csrfToken : '';
const adminLoginUrl = window.AdminConfig && window.AdminConfig.loginUrl ? window.AdminConfig.loginUrl : adminContextPath + '/login.jsp';

// Transfer schedule AJAX support
async function openTransferModal(scheduleId, doctorName, department, workDate, timeSlot) {
    const modalEl = document.getElementById('transferScheduleModal');
    const bsModal = new bootstrap.Modal(modalEl);
    document.getElementById('transferSelectedInfo').textContent = doctorName + ' - ' + department + ' - ' + workDate + ' - ' + timeSlot;
    const select = document.getElementById('transferTargetDoctor');
    select.innerHTML = '<option>\u0110ang t\u1EA3i...</option>';
    try {
        const resp = await fetch(adminContextPath + '/admin?action=getTransferCandidates&scheduleId=' + encodeURIComponent(scheduleId), {
            headers: { 'Accept': 'application/json' }
        });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        const currentId = data.currentDoctorId || null;
        const items = data.items || [];
        let options = '<option value="">-- Ch\u1ECDn b\u00E1c s\u0129 thay th\u1EBF --</option>';
        for (const d of items) {
            if (currentId && String(d.doctorId) === String(currentId)) continue; // skip current doctor
            options += '<option value="' + d.doctorId + '">' + escapeHtml(d.fullName) + ' - ' + escapeHtml(d.department) + '</option>';
        }
        select.innerHTML = options;
    } catch (err) {
        select.innerHTML = '<option value="">Kh\u00F4ng t\u1EA3i \u0111\u01B0\u1EE3c danh s\u00E1ch b\u00E1c s\u0129</option>';
    }
    // attach schedule id to confirm button
    document.getElementById('transferConfirmBtn').setAttribute('data-schedule-id', scheduleId);
    bsModal.show();
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str || '';
    return div.innerHTML;
}

document.getElementById('transferConfirmBtn').addEventListener('click', async function () {
    const scheduleId = this.getAttribute('data-schedule-id');
    const targetDoctorId = document.getElementById('transferTargetDoctor').value;
    const alertBox = document.getElementById('transferAlert');
    alertBox.className = 'alert d-none';
    if (!targetDoctorId) {
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = 'Vui l\u00F2ng ch\u1ECDn b\u00E1c s\u0129 nh\u1EADn ca.';
        return;
    }
    try {
        const params = new URLSearchParams();
        params.set('action', 'transferSchedule');
        params.set('scheduleId', scheduleId);
        params.set('targetDoctorId', targetDoctorId);
        params.set('csrfToken', adminCsrfToken);
        const resp = await fetch(adminContextPath + '/admin', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: params.toString()
        });
        let json = null;
        try { json = await resp.json(); } catch (e) { /* ignore parse error */ }
        if (json && json.success) {
            alertBox.className = 'alert alert-success';
            alertBox.textContent = json.message || '\u0110\u00E3 chuy\u1EC3n giao ca tr\u1EF1c';
            // Update table row in-place if present
            const row = document.querySelector('tr[data-schedule-id="' + scheduleId + '"]');
            if (row) {
                row.setAttribute('data-doctor-name', json.targetDoctorName || '');
                const firstTd = row.querySelector('td');
                if (firstTd) firstTd.textContent = json.targetDoctorName || firstTd.textContent;
            }
            // close modal after short delay
            setTimeout(() => {
                const bsModal = bootstrap.Modal.getInstance(document.getElementById('transferScheduleModal'));
                if (bsModal) bsModal.hide();
            }, 900);
        } else {
            const msg = (json && json.message) ? json.message : ('HTTP ' + resp.status);
            alertBox.className = 'alert alert-danger';
            alertBox.textContent = 'Kh\u00F4ng th\u1EC3 chuy\u1EC3n giao ca: ' + msg;
        }
    } catch (err) {
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = 'L\u1ED7i khi g\u1EEDi y\u00EAu c\u1EA7u: ' + err.message;
    }
});

// Expose helper to global for inline onclick
window.openTransferModal = openTransferModal;

// Helper: find row data and open modal
function openTransferModalFromRow(el) {
    const tr = el.closest('tr');
    if (!tr) return;
    const scheduleId = tr.getAttribute('data-schedule-id');
    const doctorName = tr.getAttribute('data-doctor-name') || tr.querySelector('td')?.textContent || '';
    const department = tr.getAttribute('data-department') || '';
    const workDate = tr.querySelector('td:nth-child(3)')?.textContent.trim() || '';
    const timeSlot = tr.querySelector('td:nth-child(4)')?.textContent.trim() || '';
    openTransferModal(scheduleId, doctorName, department, workDate, timeSlot);
}

// Edit schedule: open modal, populate with schedule data, save via AJAX
async function openEditScheduleModal(scheduleId) {
    const modalHtml = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <form id="editScheduleForm">
                            <div class="modal-header">
                                <h5 class="modal-title">Ch\u1EC9nh s\u1EEDa ca tr\u1EF1c</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <div id="editScheduleAlert" class="alert d-none" role="alert"></div>
                                <input type="hidden" name="scheduleId" id="editScheduleId">
                                <input type="hidden" name="csrfToken" value="${adminCsrfToken}">
                                <div class="mb-3">
                                    <label class="form-label">B\u00E1c s\u0129</label>
                                    <select id="editDoctorId" name="doctorId" class="form-select" required></select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Khung gi\u1EDD</label>
                                    <select id="editTimeSlot" name="timeSlot" class="form-select" required>
                                        <option value="07:00-09:00">07:00-09:00</option>
                                        <option value="09:00-11:00">09:00-11:00</option>
                                        <option value="11:00-13:00">11:00-13:00</option>
                                        <option value="13:00-15:00">13:00-15:00</option>
                                        <option value="15:00-17:00">15:00-17:00</option>
                                        <option value="17:00-19:00">17:00-19:00</option>
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">S\u1ED1 b\u1EC7nh nh\u00E2n t\u1ED1i \u0111a</label>
                                    <input type="number" id="editMaxPatients" name="maxPatients" class="form-control" min="1" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Slot online</label>
                                    <input type="number" id="editOnlineQuota" name="onlineQuota" class="form-control" min="0">
                                    <div class="form-text">N\u1EBFu \u0111\u1EC3 tr\u1ED1ng, h\u1EC7 th\u1ED1ng s\u1EBD t\u1EF1 \u0111\u1EB7t theo c\u1EA5u h\u00ECnh an to\u00E0n m\u1EB7c \u0111\u1ECBnh.</div>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Tr\u1EA1ng th\u00E1i</label>
                                    <select id="editStatus" name="status" class="form-select">
                                        <option value="Available">Kh\u1EA3 d\u1EE5ng</option>
                                        <option value="Full">\u0110\u00E3 \u0111\u1EA7y</option>
                                        <option value="Cancelled">\u0110\u00E3 h\u1EE7y</option>
                                    </select>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button>
                                <button type="submit" class="btn btn-primary">L\u01B0u thay \u0111\u1ED5i</button>
                            </div>
                        </form>
                    </div>
                </div>`;

    // create modal container
    let container = document.getElementById('editScheduleModalContainer');
    if (!container) {
        container = document.createElement('div');
        container.id = 'editScheduleModalContainer';
        container.className = 'modal fade';
        container.tabIndex = -1;
        document.body.appendChild(container);
    }
    container.innerHTML = modalHtml;
    const bsModal = new bootstrap.Modal(container);

    // fetch schedule details
    try {
        const resp = await fetch(adminContextPath + '/admin?action=getSchedule&scheduleId=' + encodeURIComponent(scheduleId), { headers: { 'Accept': 'application/json' } });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        if (!data || !data.schedule) throw new Error('Invalid response');

        // populate form
        document.getElementById('editScheduleId').value = data.schedule.scheduleId;
        document.getElementById('editMaxPatients').value = data.schedule.maxPatients || '';
        document.getElementById('editOnlineQuota').value = data.schedule.onlineQuota !== undefined && data.schedule.onlineQuota !== null ? data.schedule.onlineQuota : '';
        document.getElementById('editTimeSlot').value = data.schedule.timeSlot || '';
        document.getElementById('editStatus').value = data.schedule.status || 'Available';

        // populate doctors list
        const doctorSelect = document.getElementById('editDoctorId');
        doctorSelect.innerHTML = '<option>\u0110ang t\u1EA3i...</option>';
        const doctors = data.doctors || [];
        let opts = '';
        for (const d of doctors) {
            opts += '<option value="' + d.doctorId + '"' + (d.doctorId == data.schedule.doctorId ? ' selected' : '') + '>' + escapeHtml(d.fullName) + ' - ' + escapeHtml(d.department) + '</option>';
        }
        doctorSelect.innerHTML = opts;

    } catch (err) {
        const alert = document.getElementById('editScheduleAlert');
        if (alert) {
            alert.className = 'alert alert-danger';
            alert.textContent = 'Kh\u00F4ng t\u1EA3i \u0111\u01B0\u1EE3c d\u1EEF li\u1EC7u ca tr\u1EF1c.';
        }
    }

    // submit handler
    container.querySelector('#editScheduleForm').addEventListener('submit', async function (e) {
        e.preventDefault();
        const form = e.target;
        const payload = {
            scheduleId: form.scheduleId.value,
            doctorId: form.doctorId.value,
            timeSlot: form.timeSlot.value,
            maxPatients: form.maxPatients.value,
            onlineQuota: form.onlineQuota.value,
            status: form.status.value,
            csrfToken: form.csrfToken ? form.csrfToken.value : ''
        };
        try {
            const params = new URLSearchParams();
            params.set('action', 'updateSchedule');
            Object.keys(payload).forEach(function (key) {
                params.set(key, payload[key] == null ? '' : payload[key]);
            });
            const resp = await fetch(adminContextPath + '/admin?action=updateSchedule', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest', 'X-CSRF-Token': payload.csrfToken },
                body: params.toString()
            });
            if (resp.ok) {
                bsModal.hide();
                // update row in table
                const row = document.querySelector('tr[data-schedule-id="' + payload.scheduleId + '"]');
                if (row) {
                    row.querySelector('td:nth-child(4)').textContent = payload.timeSlot;
                    row.setAttribute('data-max-patients', payload.maxPatients);
                    const resolvedOnlineQuota = payload.onlineQuota
                        ? Number(payload.onlineQuota)
                        : calculateDefaultOnlineQuota(Number(payload.maxPatients || 0));
                    const reservedSlots = Math.max(0, Number(payload.maxPatients || 0) - resolvedOnlineQuota);
                    row.setAttribute('data-online-quota', resolvedOnlineQuota);
                    row.setAttribute('data-reserved-slots', reservedSlots);
                    row.querySelector('td:nth-child(5) div').textContent = (row.dataset.bookedAppointments || 0) + ' / ' + payload.maxPatients;
                    const reserveText = row.querySelector('td:nth-child(5) small:nth-of-type(2)');
                    if (reserveText) reserveText.textContent = 'D\u1EF1 ph\u00F2ng: ' + reservedSlots + ' slot';
                    const onlineQuota = Number(row.dataset.onlineQuota || 0);
                    const onlineBooked = Number(row.dataset.onlineBookedCount || 0);
                    const quotaCell = row.querySelector('td:nth-child(6)');
                    if (quotaCell) {
                        quotaCell.innerHTML = '<div class="fw-semibold">' + onlineBooked + ' / ' + onlineQuota + '</div>'
                            + '<small class="text-muted d-block">Slot online</small>'
                            + getOnlineQuotaBadge(onlineBooked, onlineQuota);
                    }
                    // update status badge
                    const statusCell = row.querySelector('td:nth-child(8)');
                    if (statusCell) statusCell.innerHTML = '<span class="badge text-bg-' + (payload.status === 'Available' ? 'success' : (payload.status === 'Full' ? 'danger' : 'dark')) + '">' + (payload.status === 'Available' ? '<i class="bi bi-check-circle"></i> Kh\u1EA3 d\u1EE5ng' : (payload.status === 'Full' ? '<i class="bi bi-exclamation-circle"></i> \u0110\u00E3 \u0111\u1EA7y' : '<i class="bi bi-x-circle"></i> \u0110\u00E3 h\u1EE7y')) + '</span>';
                }
                showTempAlert('C\u1EADp nh\u1EADt ca tr\u1EF1c th\u00E0nh c\u00F4ng.', 'success');
            } else {
                const alertEl = container.querySelector('#editScheduleAlert');
                if (alertEl) {
                    alertEl.className = 'alert alert-danger';
                    alertEl.textContent = 'Khong the cap nhat ca truc.';
                }
            }
        } catch (err) {
            const alertEl = container.querySelector('#editScheduleAlert');
            if (alertEl) {
                alertEl.className = 'alert alert-danger';
                alertEl.textContent = 'L\u1ED7i khi g\u1EEDi y\u00EAu c\u1EA7u c\u1EADp nh\u1EADt.';
            }
        }
    });

    bsModal.show();
}

function showTempAlert(message, type) {
    const div = document.createElement('div');
    div.className = 'alert alert-' + (type || 'info');
    div.textContent = message;
    document.querySelector('.admin-content-col').insertAdjacentElement('afterbegin', div);
    setTimeout(() => div.remove(), 3000);
}

function escapeHtml(s) {
    if (!s) return '';
    return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": "&#39;" }[c]; });
}

const adminScheduleEndpoint = window.AdminConfig && window.AdminConfig.adminEndpoint ? window.AdminConfig.adminEndpoint : adminContextPath + '/admin';

function escapeHtmlForSchedule(value) {
    const div = document.createElement('div');
    div.textContent = value == null ? '' : String(value);
    return div.innerHTML;
}

function getIsoDateOffset(dayOffset) {
    const date = new Date();
    date.setDate(date.getDate() + dayOffset);
    return date.toISOString().slice(0, 10);
}

function formatVietnameseDate(isoDate) {
    const parts = String(isoDate || '').split('-');
    if (parts.length !== 3) {
        return isoDate || '';
    }
    return parts[2] + '/' + parts[1] + '/' + parts[0];
}


function countShiftTemplateLines() {
    const textarea = document.querySelector('textarea[name="shiftTemplates"]');
    return textarea ? textarea.value.split(/\r?\n/).filter(line => line.trim().includes('|')).length : 0;
}

const departmentMapping = {
    'N\u1ED9i ti\u1EBFt - Ti\u1EC3u \u0111\u01B0\u1EDDng': 'Endocrinology',
    'Endocrinology': 'Endocrinology',
    'Tim m\u1EA1ch': 'Cardiology',
    'Cardiology': 'Cardiology',
    'Th\u1EADn h\u1ECDc': 'Nephrology',
    'Nephrology': 'Nephrology',
    'T\u1ED5ng qu\u00E1t': 'General',
    'General': 'General'
};

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

function updateTemplatePreview() {
    const textarea = document.querySelector('textarea[name="shiftTemplates"]');
    if (textarea) {
        const slots = buildCustomShiftTemplate();
        textarea.value = slots.join('\n');
    }
    updateAiMaxSchedules();
}

function getSelectedWeekdays() {
    return Array.from(document.querySelectorAll('input[name="selectedWeekdays"]:checked'))
        .map(input => Number(input.value));
}

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

function getDoctorsPerShift() {
    const input = document.getElementById('aiDoctorsPerShift');
    const value = input ? Number(input.value) : 1;
    return Number.isFinite(value) && value > 0 ? value : 1;
}

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
        summary.textContent = 'H\u1EC7 th\u1ED1ng s\u1EBD t\u1EA1o ra: ' + days + ' ng\u00E0y x ' + shifts
            + ' ca x ' + doctorsPerShift + ' b\u00E1c s\u0129/ca = ' + total
            + ' slot l\u1ECBch tr\u1EF1c, sau \u0111\u00F3 Gemini \u0111i\u1EC1n b\u00E1c s\u0129.';
    }
}
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
            ? '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Gemini \u0111ang ph\u00E2n b\u1ED5...'
            : '<i class="fa-solid fa-rocket me-2"></i>Ti\u1EBFn h\u00E0nh ph\u00E2n b\u1ED5 b\u1EB1ng AI';
    }
    if (loadingBox) {
        loadingBox.classList.toggle('d-none', !isBusy);
        loadingBox.classList.toggle('d-flex', isBusy);
    }
    if (detail) {
        detail.textContent = isBusy ? '\u0110ang ghi l\u1ECBch tr\u1EF1c th\u1EADt v\u00E0o h\u1EC7 th\u1ED1ng...' : '';
    }
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
        Endocrinology: 'N\u1ED9i ti\u1EBFt - Ti\u1EC3u \u0111\u01B0\u1EDDng',
        Cardiology: 'Tim m\u1EA1ch',
        Nephrology: 'Th\u1EADn h\u1ECDc',
        General: 'T\u1ED5ng qu\u00E1t'
    };
    const department = departmentMap[schedule.department] || (schedule.department || 'Ch\u01B0a x\u00E1c \u0111\u1ECBnh');

    const isGemini = schedule.source === 'Gemini AI';
    const sourceLabel = isGemini ? 'Gemini AI t\u1EA1o l\u1ECBch' : 'C\u00E2n b\u1EB1ng t\u1EA3i d\u1EF1 ph\u00F2ng';
    const sourceIcon = isGemini ? 'fa-brain' : 'fa-scale-balanced';

    const status = schedule.effectiveStatus || schedule.status || 'Available';

    let statusBadge = '<span class="badge text-bg-success"><i class="bi bi-check-circle"></i> Kh\u1EA3 d\u1EE5ng</span>';

    if (status === 'Expired') {
        statusBadge = '<span class="badge text-bg-secondary"><i class="bi bi-clock"></i> \u0110\u00E3 qua</span>';
    } else if (status === 'Cancelled') {
        statusBadge = '<span class="badge text-bg-dark"><i class="bi bi-x-circle"></i> \u0110\u00E3 h\u1EE7y</span>';
    } else if (status === 'Full') {
        statusBadge = '<span class="badge text-bg-danger"><i class="bi bi-exclamation-circle"></i> \u0110\u00E3 \u0111\u1EA7y</span>';
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

        + '<td><div style="background-color: #f0f8f4; padding: 6px 10px; border-radius: 4px; font-weight: 500; text-align: center;">'
        + bookedAppointments + ' / ' + maxPatients + '</div>'
        + '<small class="text-muted d-block text-center mt-1">\u0110\u00E3 check-in/\u0111ang kh\u00E1m: ' + activeAppointments + '</small>'
        + '<small class="text-muted d-block text-center">D\u1EF1 ph\u00F2ng: ' + reservedSlots + ' slot</small></td>'

        + '<td class="text-center">'
        + '<div class="fw-semibold">' + onlineBookedCount + ' / ' + onlineQuota + '</div>'
        + '<small class="text-muted d-block">Slot online</small>'
        + getOnlineQuotaBadge(onlineBookedCount, onlineQuota)
        + '</td>'

        + '<td class="schedule-load-cell">'
        + '<div class="schedule-load-wrap" title="' + (loadPct >= 100 ? 'Qu\u00E1 t\u1EA3i' : (loadPct >= 80 ? 'C\u1EADn \u0111\u1EA7y' : 'B\u00ECnh th\u01B0\u1EDDng')) + '">'
        + '<div class="progress schedule-load-progress">'
        + '<div class="progress-bar ' + (loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')) + '" role="progressbar" style="width: ' + (loadPct > 100 ? 100 : loadPct) + '%;" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' + loadPct + '"></div>'
        + '</div>'
        + '<span class="badge schedule-load-percent ' + (loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')) + '">' + loadPct + '%</span>'
        + '<small class="text-muted schedule-load-state">' + (loadPct >= 100 ? 'Qu\u00E1 t\u1EA3i' : (loadPct >= 80 ? 'C\u1EADn \u0111\u1EA7y' : 'B\u00ECnh th\u01B0\u1EDDng')) + '</small>'
        + '</div>'
        + '</td>'

        + '<td>' + statusBadge + '</td>'

        + '<td>' + actionColumn + '</td>'

        + '</tr>';
}

function appendCreatedSchedules(schedules) {
    const tbody = document.getElementById('scheduleTableBody');
    if (!tbody || !Array.isArray(schedules) || schedules.length === 0) {
        return;
    }
    const emptyRow = tbody.querySelector('td[colspan="9"]');
    if (emptyRow) {
        emptyRow.closest('tr').remove();
    }
    tbody.insertAdjacentHTML('afterbegin', schedules.map(buildScheduleRow).join(''));
}

function showAiScheduleMessage(message, isSuccess) {
    const alertBox = document.getElementById('aiScheduleModalAlert');
    if (!alertBox) {
        return;
    }
    alertBox.className = 'alert border-0 fw-semibold ' + (isSuccess ? 'alert-success' : 'alert-danger');
    alertBox.innerHTML = '<i class="fa-solid ' + (isSuccess ? 'fa-circle-check' : 'fa-triangle-exclamation') + ' me-2"></i>' + escapeHtmlForSchedule(message);
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

    // Wizard navigation buttons
    const prevBtn = document.getElementById('aiWizardPrevBtn');
    const nextBtn = document.getElementById('aiWizardNextBtn');
    const submitBtn = document.getElementById('aiScheduleSubmitBtn');

    let currentStep = 1;
    let proposedSchedules = [];
    let availableDoctors = [];

    if (startDate && !startDate.value) {
        startDate.value = getIsoDateOffset(1);
    }
    if (endDate && !endDate.value) {
        endDate.value = getIsoDateOffset(7);
    }

    // Dynamic weekday disabling based on date range
    function updateWeekdayStates() {
        if (!startDate || !endDate || !startDate.value || !endDate.value) return;
        const start = new Date(startDate.value + 'T00:00:00');
        const end = new Date(endDate.value + 'T00:00:00');
        const diffDays = Math.ceil((end - start) / (1000 * 60 * 60 * 24)) + 1;

        const checkboxes = document.querySelectorAll('input[name="selectedWeekdays"]');
        if (diffDays >= 7) {
            checkboxes.forEach(cb => {
                cb.disabled = false;
                const label = cb.nextElementSibling;
                if (label) {
                    label.style.textDecoration = 'none';
                    label.style.opacity = '1';
                }
            });
        } else {
            const validDays = new Set();
            let cursor = new Date(start);
            while (cursor <= end) {
                let jsDay = cursor.getDay();
                let isoDay = jsDay === 0 ? 7 : jsDay;
                validDays.add(isoDay);
                cursor.setDate(cursor.getDate() + 1);
            }
            checkboxes.forEach(cb => {
                const dayVal = Number(cb.value);
                const label = cb.nextElementSibling;
                if (validDays.has(dayVal)) {
                    cb.disabled = false;
                    if (label) {
                        label.style.textDecoration = 'none';
                        label.style.opacity = '1';
                    }
                } else {
                    cb.disabled = true;
                    cb.checked = false;
                    if (label) {
                        label.style.textDecoration = 'line-through';
                        label.style.opacity = '0.5';
                    }
                }
            });
        }
        updateAiMaxSchedules();
    }

    [startDate, endDate].forEach(input => {
        if (input) {
            input.addEventListener('change', updateWeekdayStates);
        }
    });
    updateWeekdayStates();

    // Workload calculation
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

    // Autocomplete adding from select list
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
                badge.textContent = dept + ' \u2715';
                departmentList.appendChild(badge);
                updateTemplatePreview();
            }
        });
    }

    // Badge removal
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

    // Wizard navigation controls
    function showStep(step) {
        currentStep = step;

        // Progress Stepper Indicators
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

        // Step Panels Visibility
        const s1 = document.getElementById('aiWizardStep1');
        const s2 = document.getElementById('aiWizardStep2');
        const s3 = document.getElementById('aiWizardStep3');
        if (s1) s1.classList.toggle('d-none', step !== 1);
        if (s2) s2.classList.toggle('d-none', step !== 2);
        if (s3) s3.classList.toggle('d-none', step !== 3);

        // Footer Buttons Visibility
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
});

// Event listener bấm vào hàng schedule để xem bệnh nhân
document.addEventListener('click', function (e) {
    const row = e.target.closest('tbody tr');
    if (!row) return;

    // Bỏ qua nếu bấm vào button hoặc form elements
    if (e.target.closest('button') || e.target.closest('form')) return;

    // Lấy schedule ID từ data attribute
    const scheduleId = row.dataset.scheduleId;
    const doctorName = row.dataset.doctorName || 'Không xác định';
    const timeSlot = row.querySelector('td:nth-child(4)')?.textContent || '';
    const workDate = row.querySelector('td:nth-child(3)')?.textContent || '';

    if (!scheduleId) return;

    // Cập nhật tiêu đề modal
    const titleEl = document.getElementById('appointmentsModalTitle');
    if (titleEl) {
        titleEl.textContent = doctorName + ' (' + workDate + ' ' + timeSlot + ')';
    }

    // Mở modal
    const modal = new bootstrap.Modal(document.getElementById('scheduleAppointmentsModal'));
    modal.show();

    // Tải danh sách bệnh nhân
    fetch(adminContextPath + '/admin?action=scheduleAppointments&scheduleId=' + scheduleId)
        .then(async response => {
            const ct = response.headers.get('content-type') || '';
            if (response.status === 401) {
                // Session expired for AJAX request - try to show message then redirect
                if (ct.toLowerCase().indexOf('application/json') !== -1) {
                    const err = await response.json().catch(() => null);
                    const msg = (err && err.message) ? err.message : 'Phiên làm việc đã hết, vui lòng đăng nhập lại.';
                    const tbody = document.getElementById('appointmentsTableBody');
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>' + escapeHtmlForSchedule(msg) + '</td></tr>';
                } else {
                    const tbody = document.getElementById('appointmentsTableBody');
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>Phiên làm việc có thể đã hết. Bạn sẽ được chuyển đến đăng nhập...</td></tr>';
                }
                setTimeout(() => { window.location.href = adminLoginUrl; }, 1200);
                return Promise.reject(new Error('HTTP 401'));
            }
            if (!response.ok) throw new Error('HTTP ' + response.status);
            if (ct.toLowerCase().indexOf('application/json') === -1) {
                // Non-JSON response (likely HTML error or login page)
                const txt = await response.text();
                const snippet = txt.replace(/\s+/g, ' ').substring(0, 400);
                const tbody = document.getElementById('appointmentsTableBody');
                // Detect common signs of login page or server error
                const low = snippet.toLowerCase();
                const looksLikeLogin = low.indexOf('đăng nhập') !== -1 || low.indexOf('login') !== -1 || low.indexOf('j_username') !== -1 || low.indexOf('<form') !== -1;
                if (looksLikeLogin) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>Phiên làm việc có thể đã hết. Bạn sẽ được chuyển đến trang đăng nhập...</td></tr>';
                    // Redirect to login after short delay
                    setTimeout(() => {
                        window.location.href = adminLoginUrl;
                    }, 1200);
                    // Stop further processing
                    return Promise.reject(new Error('Session expired - redirecting to login'));
                }
                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-danger py-3"><i class="bi bi-exclamation-circle me-2"></i>Server trả về nội dung không hợp lệ: ' + escapeHtmlForSchedule(snippet) + '</td></tr>';
                return Promise.reject(new Error('Server returned non-JSON response'));
            }
            return response.json();
        })
        .then(data => {
            const tbody = document.getElementById('appointmentsTableBody');
            if (!data.items || data.items.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3">Chưa có bệnh nhân nào đặt lịch</td></tr>';
                return;
            }

            tbody.innerHTML = data.items.map(item => {
                const statusBadge = getStatusBadge(item.status);
                return '<tr>'
                    + '<td><strong>' + escapeHtmlForSchedule(item.appointmentTime || '') + '</strong></td>'
                    + '<td>' + escapeHtmlForSchedule(item.patientName || '') + '</td>'
                    + '<td>' + getBookingSourceBadge(item.bookingSource) + '</td>'
                    + '<td>' + statusBadge + '</td>'
                    + '</tr>';
            }).join('');
        })
        .catch(error => {
            const tbody = document.getElementById('appointmentsTableBody');
            const msg = error && error.message ? error.message : 'Lỗi khi tải dữ liệu';
            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-danger py-3"><i class="bi bi-exclamation-circle me-2"></i>' + escapeHtmlForSchedule(msg) + '</td></tr>';
        });
}, false);

function getStatusBadge(status) {
    const statusMap = {
        'Waiting': '<span class="badge text-bg-warning"><i class="bi bi-calendar-check me-1"></i>Đã đặt lịch</span>',
        'Checked_In': '<span class="badge text-bg-primary"><i class="bi bi-person-check me-1"></i>Đã check-in</span>',
        'In_Progress': '<span class="badge text-bg-info"><i class="bi bi-play-circle me-1"></i>Đang khám</span>',
        'Completed': '<span class="badge text-bg-success"><i class="bi bi-check-circle me-1"></i>Hoàn tất</span>',
        'Absent': '<span class="badge text-bg-secondary"><i class="bi bi-x-circle me-1"></i>Không có mặt</span>',
        'Cancelled': '<span class="badge text-bg-danger"><i class="bi bi-trash me-1"></i>Đã hủy</span>'
    };
    return statusMap[status] || '<span class="badge text-bg-secondary">' + (status || 'Không xác định') + '</span>';
}

function getOnlineQuotaBadge(onlineBooked, onlineQuota) {
    if (onlineBooked > onlineQuota) {
        return '<span class="badge text-bg-danger mt-1">V\u01B0\u1EE3t quota online</span>';
    }
    if (onlineBooked >= onlineQuota) {
        return '<span class="badge text-bg-warning mt-1">H\u1EBFt slot online</span>';
    }
    return '<span class="badge text-bg-success mt-1">C\u00F2n slot online</span>';
}

function getBookingSourceBadge(source) {
    const normalized = (source || '').toString().trim();
    const sourceMap = {
        'Online': '<span class="badge text-bg-success"><i class="bi bi-globe2 me-1"></i>Online</span>',
        'Receptionist': '<span class="badge text-bg-primary"><i class="bi bi-person-badge me-1"></i>L\u1EC5 t\u00E2n</span>',
        'Admin': '<span class="badge text-bg-dark"><i class="bi bi-shield-lock me-1"></i>Admin</span>',
        'Walk_In': '<span class="badge text-bg-warning text-dark"><i class="bi bi-door-open me-1"></i>Walk-in</span>',
        'Emergency_Routing': '<span class="badge text-bg-danger"><i class="bi bi-lightning-charge me-1"></i>\u0110i\u1EC1u ph\u1ED1i</span>'
    };
    if (!normalized) {
        return '<span class="badge text-bg-secondary">Kh\u00F4ng r\u00F5</span>';
    }
    return sourceMap[normalized] || '<span class="badge text-bg-secondary">' + escapeHtmlForSchedule(normalized) + '</span>';
}

// H\u00E0m escapeHtml \u0111\u1EC3 tr\u00E1nh XSS
function escapeHtmlForSchedule(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function calculateDefaultOnlineQuota(maxPatients) {
    if (maxPatients <= 1) {
        return Math.max(0, maxPatients);
    }
    let quota = Math.ceil(maxPatients * 0.6);
    if (quota >= maxPatients) {
        quota = maxPatients - 1;
    }
    return Math.max(1, quota);
}

// Staff schedule detail/edit actions for Receptionist and Lab Doctor roles.
function getStaffRoleConfig(staffType) {
    const isLab = String(staffType || '').toLowerCase() === 'doctor_lab';
    return {
        isLab: isLab,
        title: isLab ? 'bác sĩ xét nghiệm' : 'lễ tân',
        personLabel: isLab ? 'Bác sĩ xét nghiệm' : 'Lễ tân',
        departmentLabel: isLab ? 'Nhóm xét nghiệm' : 'Quầy trực',
        areaLabel: isLab ? 'Phòng xét nghiệm' : 'Khu vực tiếp nhận',
        workloadLabel: isLab ? 'Số mẫu tối đa/ca' : 'Số lượt tiếp nhận dự kiến/ca'
    };
}

function formatStaffStatus(status) {
    const value = String(status || 'Scheduled');
    if (value === 'Expired') return 'Đã qua';
    if (value === 'Cancelled') return 'Đã hủy';
    if (value === 'Completed') return 'Hoàn tất';
    return 'Đã xếp lịch';
}

function isFinalStaffStatus(status) {
    return ['Expired', 'Cancelled', 'Completed'].includes(String(status || ''));
}

function ensureStaffModalContainer(id) {
    let container = document.getElementById(id);
    if (!container) {
        container = document.createElement('div');
        container.id = id;
        container.className = 'modal fade';
        container.tabIndex = -1;
        document.body.appendChild(container);
    }
    return container;
}

function staffScheduleUrl(staffScheduleId) {
    return adminContextPath + '/admin?action=getStaffSchedule&staffScheduleId=' + encodeURIComponent(staffScheduleId);
}

async function openStaffScheduleDetailModal(staffScheduleId) {
    const container = ensureStaffModalContainer('staffScheduleDetailModalContainer');
    container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body py-5 text-center text-muted">Đang tải dữ liệu...</div></div></div>';
    const bsModal = new bootstrap.Modal(container);
    bsModal.show();
    try {
        const resp = await fetch(staffScheduleUrl(staffScheduleId), { headers: { 'Accept': 'application/json' } });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        if (!data || !data.schedule) throw new Error('Không tìm thấy lịch trực');
        const schedule = data.schedule;
        const cfg = getStaffRoleConfig(schedule.staffType);
        const roomLine = cfg.isLab ? '<div class="col-md-6"><div class="text-muted small">Phòng xét nghiệm</div><div class="fw-semibold">' + escapeHtml(schedule.roomName || '-') + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small">Số phòng</div><div class="fw-semibold">' + escapeHtml(schedule.roomNumber || schedule.roomId || '-') + '</div></div>' : '';
        container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content">'
            + '<div class="modal-header"><h5 class="modal-title">Chi tiết lịch trực ' + cfg.title + '</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>'
            + '<div class="modal-body"><div class="row g-3">'
            + '<div class="col-md-6"><div class="text-muted small">' + cfg.personLabel + '</div><div class="fw-semibold">' + escapeHtml(schedule.staffName || '-') + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small">Trạng thái</div><div class="fw-semibold">' + escapeHtml(formatStaffStatus(schedule.status)) + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small">Ngày trực</div><div class="fw-semibold">' + escapeHtml(formatVietnameseDate(schedule.workDate)) + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small">Khung giờ</div><div class="fw-semibold">' + escapeHtml(schedule.timeSlot || '-') + '</div></div>'
            + roomLine
            + '</div></div><div class="modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button></div>'
            + '</div></div>';

    } catch (err) {
        container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-header"><h5 class="modal-title">Chi tiết lịch trực</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div><div class="modal-body text-danger">Không tải được dữ liệu lịch trực.</div></div></div>';
    }
}

async function openEditStaffScheduleModal(staffScheduleId) {
    const container = ensureStaffModalContainer('editStaffScheduleModalContainer');
    container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body py-5 text-center text-muted">Đang tải dữ liệu...</div></div></div>';
    const bsModal = new bootstrap.Modal(container);
    bsModal.show();
    try {
        const resp = await fetch(staffScheduleUrl(staffScheduleId), { headers: { 'Accept': 'application/json' } });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        if (!data || !data.schedule) throw new Error('Không tìm thấy lịch trực');
        const schedule = data.schedule;
        const cfg = getStaffRoleConfig(schedule.staffType);
        const finalStatus = isFinalStaffStatus(schedule.status);
        const timeParts = String(schedule.timeSlot || '').split('-');
        const startTime = timeParts[0] || '';
        const endTime = timeParts[1] || '';
        const labGroups = ['Huyết học', 'Sinh hóa', 'Miễn dịch', 'Vi sinh', 'Nước tiểu', 'Tổng quát'];
        if (cfg.isLab && schedule.department && !labGroups.includes(schedule.department)) {
            labGroups.push(schedule.department);
        }
        const staffOptions = (data.staff || []).map(function (item) {
            const id = item.accountId || item.id || item.staffId || '';
            const selected = String(id) === String(schedule.accountId) ? ' selected' : '';
            const dept = item.department ? ' - ' + escapeHtml(item.department) : '';
            return '<option value="' + escapeHtml(id) + '"' + selected + '>' + escapeHtml(item.fullName || item.staffName || item.email || id) + dept + '</option>';
        }).join('');
        const groupOptions = labGroups.map(function (group) {
            return '<option value="' + escapeHtml(group) + '"' + (group === schedule.department ? ' selected' : '') + '>' + escapeHtml(group) + '</option>';
        }).join('');
        const roomOptions = (data.rooms || []).map(function (room) {
            const roomId = room.roomId || room.roomNumber || '';
            const selected = String(roomId) === String(schedule.roomId || '') ? ' selected' : '';
            const name = room.roomName ? ' - ' + escapeHtml(room.roomName) : '';
            return '<option value="' + escapeHtml(roomId) + '"' + selected + '>' + escapeHtml(roomId) + name + '</option>';
        }).join('');
        const timeControls = cfg.isLab
            ? '<input type="hidden" name="timeSlot" data-lab-time-slot value="' + escapeHtml(schedule.timeSlot || '') + '">'
            + '<div class="col-md-6"><label class="form-label">Giờ bắt đầu</label><input type="time" class="form-control" name="startTime" value="' + escapeHtml(startTime) + '" required ' + (finalStatus ? 'disabled' : '') + '><div class="invalid-feedback">Vui lòng chọn giờ bắt đầu.</div></div>'
            + '<div class="col-md-6"><label class="form-label">Giờ kết thúc</label><input type="time" class="form-control" name="endTime" value="' + escapeHtml(endTime) + '" required ' + (finalStatus ? 'disabled' : '') + '><div class="invalid-feedback">Giờ kết thúc phải sau giờ bắt đầu.</div></div>'
            : '<div class="col-md-6"><label class="form-label">Khung giờ</label><input type="text" class="form-control" name="timeSlot" value="' + escapeHtml(schedule.timeSlot || '') + '" placeholder="07:00-11:00" pattern="\\d{2}:\\d{2}-\\d{2}:\\d{2}" required ' + (finalStatus ? 'disabled' : '') + '></div>';
        const departmentControl = '<input type="hidden" name="department" value="' + escapeHtml(schedule.department || 'Xét nghiệm') + '">';
        const areaControl = '<input type="hidden" name="workArea" value="' + escapeHtml(schedule.workArea || '') + '">';
        const roomControl = cfg.isLab
            ? '<div class="col-md-6"><label class="form-label">Phòng xét nghiệm</label><select class="form-select" name="roomId" required ' + (finalStatus ? 'disabled' : '') + '><option value="">-- Chọn phòng xét nghiệm --</option>' + roomOptions + '</select><div class="invalid-feedback">Vui lòng chọn phòng xét nghiệm.</div></div>'
            : '';
        container.innerHTML = '<div class="modal-dialog modal-dialog-centered modal-lg"><div class="modal-content">'
            + '<form method="post" action="' + adminContextPath + '/admin" class="lab-schedule-form" novalidate>'
            + '<div class="modal-header"><h5 class="modal-title">Chỉnh sửa lịch trực ' + cfg.title + '</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>'
            + '<div class="modal-body">' + (finalStatus ? '<div class="alert alert-warning">Ca trực này đã ' + escapeHtml(formatStaffStatus(schedule.status).toLowerCase()) + ', hệ thống không cho chỉnh sửa.</div>' : '')
            + '<input type="hidden" name="action" value="update-staff-schedule"><input type="hidden" name="csrfToken" value="' + escapeHtml(adminCsrfToken) + '"><input type="hidden" name="staffScheduleId" value="' + escapeHtml(schedule.staffScheduleId) + '"><input type="hidden" name="staffType" value="' + escapeHtml(schedule.staffType) + '">'
            + '<input type="hidden" name="maxWorkload" value="' + escapeHtml(schedule.maxWorkload == null ? '50' : schedule.maxWorkload) + '">'
            + '<div class="row g-3">'
            + '<div class="col-md-6"><label class="form-label">' + cfg.personLabel + '</label><select class="form-select" name="accountId" required ' + (finalStatus ? 'disabled' : '') + '>' + staffOptions + '</select><div class="invalid-feedback">Vui lòng chọn đúng nhân sự đang hoạt động.</div></div>'
            + '<div class="col-md-6"><label class="form-label">Ngày trực</label><input type="date" class="form-control" name="workDate" value="' + escapeHtml(schedule.workDate || '') + '" required ' + (finalStatus ? 'disabled' : '') + '><div class="invalid-feedback">Ngày trực không được ở quá khứ.</div></div>'
            + timeControls
            + departmentControl
            + roomControl
            + areaControl
            + '<div class="col-md-6"><label class="form-label">Trạng thái</label><select class="form-select" name="status" ' + (finalStatus ? 'disabled' : '') + '><option value="Scheduled"' + (schedule.status === 'Scheduled' ? ' selected' : '') + '>Đã xếp lịch</option><option value="Cancelled"' + (schedule.status === 'Cancelled' ? ' selected' : '') + '>Đã hủy</option></select></div>'
            + '</div></div><div class="modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Hủy</button>' + (finalStatus ? '' : '<button type="submit" class="btn btn-primary">Lưu thay đổi</button>') + '</div>'
            + '</form></div></div>';
        attachLabScheduleValidation(container.querySelector('form'));
    } catch (err) {
        container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-header"><h5 class="modal-title">Chỉnh sửa lịch trực</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div><div class="modal-body text-danger">Không tải được dữ liệu lịch trực.</div></div></div>';
    }
}
window.openEditStaffScheduleModal = openEditStaffScheduleModal;
window.openStaffScheduleDetailModal = openStaffScheduleDetailModal;

async function openDoctorScheduleDetailModal(scheduleId) {
    const container = ensureStaffModalContainer('doctorScheduleDetailModalContainer');
    container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body py-5 text-center text-muted">Đang tải dữ liệu...</div></div></div>';
    const bsModal = new bootstrap.Modal(container);
    bsModal.show();
    try {
        const resp = await fetch(adminContextPath + '/admin?action=getSchedule&scheduleId=' + encodeURIComponent(scheduleId), { headers: { 'Accept': 'application/json' } });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        if (!data || !data.schedule) throw new Error('Không tìm thấy thông tin lịch trực');

        const schedule = data.schedule;
        const statusTranslations = {
            'Available': '<span class="badge bg-success-subtle text-success border border-success-subtle"><i class="bi bi-check-circle me-1"></i>Khả dụng</span>',
            'Full': '<span class="badge bg-danger-subtle text-danger border border-danger-subtle"><i class="bi bi-exclamation-circle me-1"></i>Đã đầy</span>',
            'Cancelled': '<span class="badge bg-dark-subtle text-dark border border-dark-subtle"><i class="bi bi-x-circle me-1"></i>Đã hủy</span>',
            'Expired': '<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle"><i class="bi bi-clock me-1"></i>Đã qua</span>'
        };
        const statusHtml = statusTranslations[schedule.status] || ('<span class="badge bg-primary-subtle text-primary border border-primary-subtle">' + escapeHtml(schedule.status || '-') + '</span>');

        const deptMap = {
            'Endocrinology': 'Nội tiết - Tiểu đường',
            'Cardiology': 'Tim mạch',
            'Nephrology': 'Thận học',
            'General': 'Tổng quát'
        };
        const deptText = deptMap[schedule.department] || (schedule.department || '-');

        container.innerHTML = '<div class="modal-dialog modal-dialog-centered modal-md">'
            + '<div class="modal-content border-0 shadow-lg" style="border-radius:16px;">'
            + '<div class="modal-header border-0 pb-0" style="background:linear-gradient(135deg, #f5f3ff 0%, #ede9fe 100%); border-top-left-radius:16px; border-top-right-radius:16px; padding:1.25rem 1.5rem;">'
            + '<h5 class="modal-title fw-bold text-purple d-flex align-items-center"><i class="bi bi-eye-fill me-2" style="font-size:1.25rem; color:#7c3aed;"></i>Chi tiết ca trực Bác sĩ</h5>'
            + '<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close" style="background-size:0.8rem;"></button>'
            + '</div>'
            + '<div class="modal-body p-4">'
            + '<div class="row g-3">'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Bác sĩ khám</div><div class="fw-bold text-dark mt-1" style="font-size:0.95rem;">' + escapeHtml(schedule.doctorName || '-') + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Trạng thái</div><div class="mt-1">' + statusHtml + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Ngày trực</div><div class="fw-bold text-dark mt-1" style="font-size:0.95rem;">' + escapeHtml(formatVietnameseDate(schedule.workDate)) + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Khung giờ trực</div><div class="fw-bold text-dark mt-1" style="font-size:0.95rem;"><i class="bi bi-clock me-1 text-muted"></i>' + escapeHtml(schedule.timeSlot || '-') + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Chuyên khoa</div><div class="fw-semibold text-secondary mt-1" style="font-size:0.9rem;">' + escapeHtml(deptText) + '</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Phòng khám trực</div><div class="fw-semibold text-secondary mt-1" style="font-size:0.9rem;"><i class="bi bi-geo-alt me-1 text-muted"></i>' + escapeHtml(schedule.roomName ? (schedule.roomId + ' - ' + schedule.roomName) : (schedule.roomId || '-')) + '</div></div>'
            + '<div class="col-md-12"><hr class="my-2 border-slate-100"></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Tổng ca nhận khám</div><div class="fw-bold text-dark mt-1" style="font-size:0.95rem;">' + escapeHtml(schedule.bookedCount !== undefined ? schedule.bookedCount : (schedule.bookedAppointments || 0)) + ' / ' + escapeHtml(schedule.maxPatients || '-') + ' ca</div></div>'
            + '<div class="col-md-6"><div class="text-muted small fw-semibold text-uppercase" style="font-size:0.72rem; letter-spacing:0.05em;">Đặt hẹn Online</div><div class="fw-bold text-dark mt-1" style="font-size:0.95rem;">' + escapeHtml(schedule.onlineBookedCount !== undefined ? schedule.onlineBookedCount : (schedule.onlineBooked || 0)) + ' / ' + escapeHtml(schedule.onlineQuota !== undefined ? schedule.onlineQuota : '-') + ' ca</div></div>'
            + '</div></div>'
            + '<div class="modal-footer border-0 pt-0 px-4 pb-4">'
            + '<button type="button" class="btn btn-secondary px-4 py-2" data-bs-dismiss="modal" style="border-radius:10px; font-weight:600; font-size:0.85rem; background-color:#64748b; border:none;">Đóng</button>'
            + '</div>'
            + '</div></div>';

    } catch (err) {
        container.innerHTML = '<div class="modal-dialog modal-dialog-centered"><div class="modal-content border-0 shadow-lg" style="border-radius:12px;"><div class="modal-header border-0 pb-0"><h5 class="modal-title fw-bold text-danger">Lỗi tải dữ liệu</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div><div class="modal-body p-4 text-danger">Không thể tải thông tin chi tiết lịch trực bác sĩ.</div></div></div>';
    }
}
window.openDoctorScheduleDetailModal = openDoctorScheduleDetailModal;

document.addEventListener('click', function (event) {
    const staffDetailButton = event.target.closest('.staff-schedule-detail-action');
    if (staffDetailButton) {
        event.preventDefault();
        openStaffScheduleDetailModal(staffDetailButton.getAttribute('data-staff-schedule-id'));
        return;
    }
    const docDetailButton = event.target.closest('.schedule-detail-action');
    if (docDetailButton) {
        event.preventDefault();
        openDoctorScheduleDetailModal(docDetailButton.getAttribute('data-schedule-id'));
    }
});

function attachLabScheduleValidation(form) {
    if (!form || form.dataset.labValidationBound === 'true') return;
    form.dataset.labValidationBound = 'true';
    const today = new Date().toISOString().slice(0, 10);
    const setInvalid = function (field, message) {
        if (!field) return;
        field.setCustomValidity(message || '');
        const feedback = field.parentElement ? field.parentElement.querySelector('.invalid-feedback') : null;
        if (feedback && message) feedback.textContent = message;
    };
    const validate = function () {
        if (form.staffType && form.staffType.value !== 'doctor_lab') return true;
        let ok = true;
        const workDate = form.workDate;
        const start = form.startTime;
        const end = form.endTime;
        const workload = form.maxWorkload;
        setInvalid(workDate, '');
        setInvalid(start, '');
        setInvalid(end, '');
        setInvalid(workload, '');
        if (workDate && workDate.value && workDate.value < today) {
            setInvalid(workDate, 'Ngày trực không được ở quá khứ.');
            ok = false;
        }
        if (start && end) {
            if (!start.value) {
                setInvalid(start, 'Vui lòng chọn giờ bắt đầu.');
                ok = false;
            }
            if (!end.value || (start.value && end.value <= start.value)) {
                setInvalid(end, 'Giờ kết thúc phải sau giờ bắt đầu.');
                ok = false;
            }
            const hiddenSlot = form.querySelector('[data-lab-time-slot]');
            if (hiddenSlot && start.value && end.value && end.value > start.value) {
                hiddenSlot.value = start.value + '-' + end.value;
            }
        }
        if (workload) {
            const value = Number(workload.value);
            if (!Number.isFinite(value) || value < 1 || value > 500) {
                setInvalid(workload, 'Số mẫu tối đa/ca phải từ 1 đến 500.');
                ok = false;
            }
        }
        return ok && form.checkValidity();
    };
    form.addEventListener('submit', function (event) {
        if (!validate()) {
            event.preventDefault();
            event.stopPropagation();
        }
        form.classList.add('was-validated');
    });
    ['input', 'change'].forEach(function (eventName) {
        form.addEventListener(eventName, validate);
    });
}

document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('#createLabScheduleModal form').forEach(attachLabScheduleValidation);

    // AI Suggestion inside Create Doctor Schedule Modal
    const createModal = document.getElementById('createScheduleModal');
    if (createModal) {
        const docSelect = createModal.querySelector('select[name="doctorId"]');
        const dateInput = createModal.querySelector('input[name="workDate"]');
        const suggestBtn = document.getElementById('aiSuggestTimeBtn');
        const feedbackSpan = document.getElementById('aiSuggestionFeedback');
        const slotInput = createModal.querySelector('input[name="timeSlot"]');

        const checkInputs = () => {
            if (docSelect && docSelect.value && dateInput && dateInput.value) {
                suggestBtn.classList.remove('d-none');
            } else {
                suggestBtn.classList.add('d-none');
                feedbackSpan.textContent = '';
            }
        };

        if (docSelect) docSelect.addEventListener('change', checkInputs);
        if (dateInput) dateInput.addEventListener('change', checkInputs);

        if (suggestBtn) {
            suggestBtn.addEventListener('click', async function (e) {
                e.preventDefault();
                const docId = docSelect.value;
                const dateVal = dateInput.value;
                if (!docId || !dateVal) return;

                feedbackSpan.innerHTML = '<span class="text-secondary">🤖 Đang lấy gợi ý...</span>';
                try {
                    const resp = await fetch(adminContextPath + '/admin?action=aiSuggestTime&doctorId='
                        + encodeURIComponent(docId) + '&workDate=' + encodeURIComponent(dateVal), {
                        headers: { 'Accept': 'application/json' }
                    });
                    if (!resp.ok) throw new Error('HTTP ' + resp.status);
                    const data = await resp.json();
                    if (data && data.success && data.suggestedTime) {
                        feedbackSpan.innerHTML = '<span class="badge cursor-pointer px-2 py-1 rounded-2" style="background:#f3e8ff; color:#6b21a8; border:1px solid #e9d5ff; font-weight:600;" id="aiApplySuggestedTime">'
                            + 'Khuyên dùng: ' + escapeHtml(data.suggestedTime) + ' (Bấm để áp dụng)</span>';

                        document.getElementById('aiApplySuggestedTime').addEventListener('click', function () {
                            if (slotInput) {
                                slotInput.value = data.suggestedTime;
                                feedbackSpan.innerHTML = '<span class="text-success">Đã áp dụng!</span>';
                            }
                        });
                    } else {
                        feedbackSpan.innerHTML = '<span class="text-warning">' + escapeHtml(data.message || 'Không có gợi ý.') + '</span>';
                    }
                } catch (err) {
                    feedbackSpan.innerHTML = '<span class="text-danger">Lỗi kết nối AI</span>';
                }
            });
        }
    }

    // ==========================================
    // WEEKLY CALENDAR CONTROLLER
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

        document.getElementById('calGenerateAiBtn')?.addEventListener('click', generateCalendarAiSchedule);
        document.getElementById('calConfirmAiBtn')?.addEventListener('click', confirmCalendarAiSchedule);

        // Tải lịch ngay khi khởi tạo nếu pane đang mở
        if (!document.getElementById('weeklyCalendarPane')?.hasAttribute('hidden')) {
            loadWeeklyCalendar();
        }
    }

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

    function generateCalendarAiSchedule() {
        const confirmBtn = document.getElementById('calConfirmAiBtn');
        if (confirmBtn) confirmBtn.classList.remove('d-none');

        const picker = document.getElementById('calendarWeekPicker');
        const baseDate = new Date(picker.value || new Date());
        const monday = getMondayOfDate(baseDate);

        const proposed = [
            { id: 9901, staff: 'Dr. Nguyễn Văn AI', role: 'Doctor', room: 'Phòng 101', date: formatDateIso(monday), start: '08:00', end: '12:00', timeSlot: 'Morning', status: 'Suggested', isPreview: true },
            { id: 9902, staff: 'KTV. Trần Thị AI', role: 'Lab', room: 'Phòng Xét nghiệm Máu', date: formatDateIso(monday), start: '08:00', end: '12:00', timeSlot: 'Morning', status: 'Suggested', isPreview: true },
            { id: 9903, staff: 'Lễ tân Lê Văn AI', role: 'Reception', room: 'Quầy tiếp nhận 1', date: formatDateIso(monday), start: '13:00', end: '17:00', timeSlot: 'Afternoon', status: 'Suggested', isPreview: true }
        ];

        currentWeeklySchedules = [...currentWeeklySchedules, ...proposed];
        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        const datesMap = {};
        days.forEach((dayKey, idx) => {
            const dateObj = new Date(monday);
            dateObj.setDate(monday.getDate() + idx);
            datesMap[dayKey] = formatDateIso(dateObj);
        });

        days.forEach(dayKey => {
            ['0800', '1300'].forEach(timeKey => {
                const cell = document.getElementById(`cell-${dayKey}-${timeKey}`);
                if (cell) cell.innerHTML = '';
            });
        });

        renderWeeklyCalendarCards(currentWeeklySchedules, datesMap);
    }

    async function confirmCalendarAiSchedule() {
        try {
            const resp = await fetch(`${adminContextPath}/admin?action=confirmAISchedule`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            });
            const data = await resp.json();
            if (data.success) {
                alert(data.message || 'Đã lưu lịch AI vào CSDL thành công!');
                document.getElementById('calConfirmAiBtn')?.classList.add('d-none');
                loadWeeklyCalendar();
            }
        } catch (err) {
            alert('Lỗi xác nhận lịch AI: ' + err.message);
        }
    }
});
