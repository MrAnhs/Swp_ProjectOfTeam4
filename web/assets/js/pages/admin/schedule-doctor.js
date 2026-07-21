/**
 * =========================================================================
 * MODULE: QUẢN LÝ LỊCH TRỰC BÁC SĨ KHÁM (DOCTOR SCHEDULE MANAGEMENT)
 * =========================================================================
 * File này xử lý các tương tác liên quan đến Bác sĩ khám (xếp ca, chuyển ca,
 * sửa ca trực và hiển thị danh sách bệnh nhân đã đặt lịch trong ca).
 */

// ==========================================
// 1. CHUYỂN GIAO CA TRỰC (TRANSFER SCHEDULE)
// ==========================================

/**
 * Mở modal chuyển giao ca trực và tải danh sách bác sĩ thay thế qua AJAX.
 * @param {string|number} scheduleId - ID của ca trực hiện tại cần chuyển
 * @param {string} doctorName - Tên bác sĩ hiện tại
 * @param {string} department - Chuyên khoa
 * @param {string} workDate - Ngày trực
 * @param {string} timeSlot - Khung giờ trực
 */
async function openTransferModal(scheduleId, doctorName, department, workDate, timeSlot) {
    const modalEl = document.getElementById('transferScheduleModal');
    const bsModal = new bootstrap.Modal(modalEl);
    
    // Hiển thị thông tin ca trực hiện tại đang được chọn
    document.getElementById('transferSelectedInfo').textContent = doctorName + ' - ' + department + ' - ' + workDate + ' - ' + timeSlot;
    
    const select = document.getElementById('transferTargetDoctor');
    select.innerHTML = '<option>Đang tải...</option>';
    
    try {
        const resp = await fetch(adminContextPath + '/admin?action=getTransferCandidates&scheduleId=' + encodeURIComponent(scheduleId), {
            headers: { 'Accept': 'application/json' }
        });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        
        const currentId = data.currentDoctorId || null;
        const items = data.items || [];
        
        let options = '<option value="">-- Chọn bác sĩ thay thế --</option>';
        for (const d of items) {
            // Không hiển thị lại bác sĩ hiện tại trong danh sách chuyển
            if (currentId && String(d.doctorId) === String(currentId)) continue;
            options += '<option value="' + d.doctorId + '">' + escapeHtml(d.fullName) + ' - ' + escapeHtml(d.department) + '</option>';
        }
        select.innerHTML = options;
    } catch (err) {
        select.innerHTML = '<option value="">Không tải được danh sách bác sĩ</option>';
    }
    
    // Gán ID ca trực vào nút xác nhận
    document.getElementById('transferConfirmBtn').setAttribute('data-schedule-id', scheduleId);
    bsModal.show();
}

/**
 * Lắng nghe sự kiện click xác nhận chuyển giao ca trực
 */
document.getElementById('transferConfirmBtn')?.addEventListener('click', async function () {
    const scheduleId = this.getAttribute('data-schedule-id');
    const targetDoctorId = document.getElementById('transferTargetDoctor').value;
    const alertBox = document.getElementById('transferAlert');
    alertBox.className = 'alert d-none';
    
    if (!targetDoctorId) {
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = 'Vui lòng chọn bác sĩ nhận ca.';
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
        try { json = await resp.json(); } catch (e) {}
        
        if (json && json.success) {
            alertBox.className = 'alert alert-success';
            alertBox.textContent = json.message || 'Đã chuyển giao ca trực';
            
            // Cập nhật tên bác sĩ trực tiếp trên dòng của bảng biểu mà không cần reload trang
            const row = document.querySelector('tr[data-schedule-id="' + scheduleId + '"]');
            if (row) {
                row.setAttribute('data-doctor-name', json.targetDoctorName || '');
                const firstTd = row.querySelector('td');
                if (firstTd) firstTd.textContent = json.targetDoctorName || firstTd.textContent;
            }
            
            setTimeout(() => {
                const bsModal = bootstrap.Modal.getInstance(document.getElementById('transferScheduleModal'));
                if (bsModal) bsModal.hide();
            }, 900);
        } else {
            const msg = (json && json.message) ? json.message : ('HTTP ' + resp.status);
            alertBox.className = 'alert alert-danger';
            alertBox.textContent = 'Không thể chuyển giao ca: ' + msg;
        }
    } catch (err) {
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = 'Lỗi khi gửi yêu cầu: ' + err.message;
    }
});

window.openTransferModal = openTransferModal;

/**
 * Trích xuất dữ liệu từ hàng (tr) và mở modal chuyển giao ca trực
 * @param {HTMLElement} el - Element nút bấm chuyển ca trên hàng
 */
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
window.openTransferModalFromRow = openTransferModalFromRow;


// ==========================================
// 2. CHỈNH SỬA CA TRỰC BÁC SĨ (EDIT DOCTOR SCHEDULE)
// ==========================================

/**
 * Mở modal chỉnh sửa thông tin ca trực của bác sĩ qua AJAX.
 * @param {string|number} scheduleId - ID ca trực cần sửa
 */
async function openEditScheduleModal(scheduleId) {
    const modalHtml = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <form id="editScheduleForm">
                            <div class="modal-header">
                                <h5 class="modal-title">Chỉnh sửa ca trực</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <div id="editScheduleAlert" class="alert d-none" role="alert"></div>
                                <input type="hidden" name="scheduleId" id="editScheduleId">
                                <input type="hidden" name="csrfToken" value="${adminCsrfToken}">
                                <div class="mb-3">
                                    <label class="form-label">Bác sĩ</label>
                                    <select id="editDoctorId" name="doctorId" class="form-select" required></select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Khung giờ</label>
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
                                    <label class="form-label">Số bệnh nhân tối đa</label>
                                    <input type="number" id="editMaxPatients" name="maxPatients" class="form-control" min="1" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Slot online</label>
                                    <input type="number" id="editOnlineQuota" name="onlineQuota" class="form-control" min="0">
                                    <div class="form-text">Nếu để trống, hệ thống sẽ tự đặt theo cấu hình an toàn mặc định.</div>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Trạng thái</label>
                                    <select id="editStatus" name="status" class="form-select">
                                        <option value="Available">Khả dụng</option>
                                        <option value="Full">Đã đầy</option>
                                        <option value="Cancelled">Đã hủy</option>
                                    </select>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                                <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
                            </div>
                        </form>
                    </div>
                </div>`;

    // Khởi tạo container động chứa modal edit
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

    try {
        const resp = await fetch(adminContextPath + '/admin?action=getSchedule&scheduleId=' + encodeURIComponent(scheduleId), { headers: { 'Accept': 'application/json' } });
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        const data = await resp.json();
        if (!data || !data.schedule) throw new Error('Invalid response');

        // Điền dữ liệu vào form
        document.getElementById('editScheduleId').value = data.schedule.scheduleId;
        document.getElementById('editMaxPatients').value = data.schedule.maxPatients || '';
        document.getElementById('editOnlineQuota').value = data.schedule.onlineQuota !== undefined && data.schedule.onlineQuota !== null ? data.schedule.onlineQuota : '';
        document.getElementById('editTimeSlot').value = data.schedule.timeSlot || '';
        document.getElementById('editStatus').value = data.schedule.status || 'Available';

        const doctorSelect = document.getElementById('editDoctorId');
        doctorSelect.innerHTML = '<option>Đang tải...</option>';
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
            alert.textContent = 'Không tải được dữ liệu ca trực.';
        }
    }

    // Đăng ký sự kiện submit AJAX cho form chỉnh sửa
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
                // Cập nhật giá trị trực tiếp trên dòng của bảng
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
                    if (reserveText) reserveText.textContent = 'Dự phòng: ' + reservedSlots + ' slot';
                    
                    const onlineQuota = Number(row.dataset.onlineQuota || 0);
                    const onlineBooked = Number(row.dataset.onlineBookedCount || 0);
                    const quotaCell = row.querySelector('td:nth-child(6)');
                    if (quotaCell) {
                        quotaCell.innerHTML = '<div class="fw-semibold">' + onlineBooked + ' / ' + onlineQuota + '</div>'
                            + '<small class="text-muted d-block">Slot online</small>'
                            + getOnlineQuotaBadge(onlineBooked, onlineQuota);
                    }
                    const statusCell = row.querySelector('td:nth-child(8)');
                    if (statusCell) statusCell.innerHTML = '<span class="badge text-bg-' + (payload.status === 'Available' ? 'success' : (payload.status === 'Full' ? 'danger' : 'dark')) + '">' + (payload.status === 'Available' ? '<i class="bi bi-check-circle"></i> Khả dụng' : (payload.status === 'Full' ? '<i class="bi bi-exclamation-circle"></i> Đã đầy' : '<i class="bi bi-x-circle"></i> Đã hủy')) + '</span>';
                }
                showTempAlert('Cập nhật ca trực thành công.', 'success');
            } else {
                const alertEl = container.querySelector('#editScheduleAlert');
                if (alertEl) {
                    alertEl.className = 'alert alert-danger';
                    alertEl.textContent = 'Không thể cập nhật ca trực.';
                }
            }
        } catch (err) {
            const alertEl = container.querySelector('#editScheduleAlert');
            if (alertEl) {
                alertEl.className = 'alert alert-danger';
                alertEl.textContent = 'Lỗi khi gửi yêu cầu cập nhật.';
            }
        }
    });

    bsModal.show();
}
window.openEditScheduleModal = openEditScheduleModal;


// ==========================================
// 3. CHI TIẾT CA TRỰC BÁC SĨ (SCHEDULE DETAIL)
// ==========================================

/**
 * Mở modal xem chi tiết ca trực bác sĩ khám
 * @param {string|number} scheduleId 
 */
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


// ==========================================
// 4. DANH SÁCH BỆNH NHÂN TRONG CA (APPOINTMENTS LIST)
// ==========================================

/**
 * Đăng ký sự kiện click vào hàng lịch trực để xem danh sách bệnh nhân
 */
document.addEventListener('click', function (e) {
    const row = e.target.closest('tbody tr');
    if (!row) return;
    
    // Bỏ qua nếu bấm vào các button hành động hoặc select trong hàng
    if (e.target.closest('button') || e.target.closest('form') || e.target.closest('a') || e.target.closest('select')) return;

    const scheduleId = row.dataset.scheduleId;
    const doctorName = row.dataset.doctorName || 'Không xác định';
    const timeSlot = row.querySelector('td:nth-child(4)')?.textContent || '';
    const workDate = row.querySelector('td:nth-child(3)')?.textContent || '';

    if (!scheduleId || isNaN(Number(scheduleId))) return;

    const titleEl = document.getElementById('appointmentsModalTitle');
    if (titleEl) {
        titleEl.textContent = doctorName + ' (' + workDate + ' ' + timeSlot + ')';
    }

    const modal = new bootstrap.Modal(document.getElementById('scheduleAppointmentsModal'));
    modal.show();

    // Gọi AJAX tải danh sách lịch khám của ca trực này
    fetch(adminContextPath + '/admin?action=scheduleAppointments&scheduleId=' + scheduleId)
        .then(async response => {
            const ct = response.headers.get('content-type') || '';
            if (response.status === 401) {
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
                const txt = await response.text();
                const snippet = txt.replace(/\s+/g, ' ').substring(0, 400);
                const tbody = document.getElementById('appointmentsTableBody');
                const low = snippet.toLowerCase();
                const looksLikeLogin = low.indexOf('đăng nhập') !== -1 || low.indexOf('login') !== -1 || low.indexOf('j_username') !== -1 || low.indexOf('<form') !== -1;
                if (looksLikeLogin) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>Phiên làm việc có thể đã hết. Bạn sẽ được chuyển đến trang đăng nhập...</td></tr>';
                    setTimeout(() => {
                        window.location.href = adminLoginUrl;
                    }, 1200);
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

/**
 * Trả về mã màu tương ứng với trạng thái khám bệnh
 * @param {string} status 
 * @returns {string} Badge HTML
 */
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
