/**
 * =========================================================================
 * MODULE: QUẢN LÝ LỊCH TRỰC NHÂN VIÊN LỄ TÂN & LAB (STAFF SCHEDULE MANAGEMENT)
 * =========================================================================
 * File này xử lý các ca trực của Lễ tân (Receptionist) và Bác sĩ xét nghiệm (Lab).
 */

// Global Context Fallbacks
const adminContextPath = (window.AdminConfig && window.AdminConfig.contextPath) ? window.AdminConfig.contextPath : (typeof window.adminContextPath !== 'undefined' ? window.adminContextPath : '');
const adminCsrfToken = (window.AdminConfig && window.AdminConfig.csrfToken) ? window.AdminConfig.csrfToken : (typeof window.adminCsrfToken !== 'undefined' ? window.adminCsrfToken : '');
const adminLoginUrl = (window.AdminConfig && window.AdminConfig.loginUrl) ? window.AdminConfig.loginUrl : (typeof window.adminLoginUrl !== 'undefined' ? window.adminLoginUrl : adminContextPath + '/login.jsp');

if (typeof window.escapeHtml !== 'function') {
    window.escapeHtml = function (s) {
        if (!s) return '';
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": "&#39;" }[c];
        });
    };
}
if (typeof window.escapeHtmlForSchedule !== 'function') {
    window.escapeHtmlForSchedule = window.escapeHtml;
}

// ==========================================
// 1. CONFIGURATION & HELPERS FOR STAFF ROLES
// ==========================================

/**
 * Trả về cấu hình nhãn giao diện tương ứng với loại nhân sự (Lễ tân / Lab)
 * @param {string} staffType - Loại nhân sự ('Receptionist' hoặc 'doctor_lab')
 */
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

/**
 * Định dạng tên hiển thị của trạng thái ca trực nhân viên
 * @param {string} status 
 */
function formatStaffStatus(status) {
    const value = String(status || 'Scheduled');
    if (value === 'Expired') return 'Đã qua';
    if (value === 'Cancelled') return 'Đã hủy';
    if (value === 'Completed') return 'Hoàn tất';
    return 'Đã xếp lịch';
}

/**
 * Kiểm tra trạng thái hiện tại có phải là trạng thái cuối cùng hay không (không được sửa)
 * @param {string} status 
 */
function isFinalStaffStatus(status) {
    return ['Expired', 'Cancelled', 'Completed'].includes(String(status || ''));
}

/**
 * Đảm bảo container của modal được thêm vào DOM
 * @param {string} id 
 */
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

/**
 * Trả về endpoint GET thông tin ca trực của nhân viên
 * @param {string|number} staffScheduleId 
 */
function staffScheduleUrl(staffScheduleId) {
    return adminContextPath + '/admin?action=getStaffSchedule&staffScheduleId=' + encodeURIComponent(staffScheduleId);
}


// ==========================================
// 2. CHI TIẾT & SỬA LỊCH TRỰC NHÂN VIÊN
// ==========================================

/**
 * Mở modal xem chi tiết ca trực của Lễ tân / Bác sĩ xét nghiệm
 * @param {string|number} staffScheduleId 
 */
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

/**
 * Mở modal chỉnh sửa ca trực của Lễ tân / Bác sĩ xét nghiệm
 * @param {string|number} staffScheduleId 
 */
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


// ==========================================
// 3. XÁC THỰC RÀNG BUỘC PHÂN CA NHÂN VIÊN
// ==========================================

/**
 * Đăng ký bộ lắng nghe xác thực (validation) cho biểu mẫu ca trực lễ tân/lab
 * @param {HTMLFormElement} form 
 */
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
        return ok;
    };

    form.addEventListener('submit', async function (e) {
        if (!validate() || !form.checkValidity()) {
            e.preventDefault();
            e.stopPropagation();
            form.classList.add('was-validated');
            return;
        }
        e.preventDefault();

        const payload = new URLSearchParams();
        Array.from(form.elements).forEach(el => {
            if (el.name && !el.disabled) {
                payload.set(el.name, el.value);
            }
        });

        try {
            const resp = await fetch(form.action, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
                body: payload.toString()
            });
            const text = await resp.text();
            let json = null;
            try { json = JSON.parse(text); } catch (err) { }
            if (json && json.success) {
                const modalEl = form.closest('.modal');
                if (modalEl) {
                    const inst = bootstrap.Modal.getInstance(modalEl);
                    if (inst) inst.hide();
                }
                showTempAlert(json.message || 'Thành công', 'success');
                setTimeout(() => window.location.reload(), 800);
            } else {
                const errMsg = (json && json.message) ? json.message : 'Lỗi từ hệ thống.';
                alert('Không thể lưu ca trực: ' + errMsg);
            }
        } catch (err) {
            alert('Lỗi kết nối: ' + err.message);
        }
    });

    Array.from(form.elements).forEach(el => {
        if (['workDate', 'startTime', 'endTime', 'maxWorkload'].includes(el.name)) {
            el.addEventListener('change', validate);
            el.addEventListener('input', validate);
        }
    });
}
window.attachLabScheduleValidation = attachLabScheduleValidation;

const safeOnReadyStaff = typeof window.onReady === 'function' ? window.onReady : function (fn) {
    if (document.readyState === 'interactive' || document.readyState === 'complete') {
        setTimeout(fn, 0);
    } else {
        document.addEventListener('DOMContentLoaded', fn);
    }
};

safeOnReadyStaff(function () {
    const labForm = document.querySelector('form[action$="/admin"] input[value="create-staff-schedule"]')?.closest('form');
    if (labForm) {
        attachLabScheduleValidation(labForm);
    }
});
