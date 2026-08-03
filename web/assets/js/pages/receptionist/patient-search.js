(function () {
    // Quản lý việc tra cứu thông tin bệnh nhân và danh sách lịch hẹn khám của bệnh nhân đó
    const utils = window.ReceptionistUtils;
    const phoneInput = document.getElementById('patientSearchPhone');
    const searchButton = document.getElementById('patientSearchBtn');
    const result = document.getElementById('patientSearchResult');
    const empty = document.getElementById('patientSearchEmpty');
    const confirmCancelModalEl = document.getElementById('confirmCancelModal');
    const cancelModalMessage = document.getElementById('cancelModalMessage');
    const cancelReasonInput = document.getElementById('cancelReasonInput');
    const confirmCancelSubmitBtn = document.getElementById('confirmCancelSubmitBtn');

    let pendingCancelApptId = null; // Lưu ID lịch khám đang chờ xác nhận hủy
    let confirmCancelModalInstance = null; // Đối tượng modal xác nhận hủy lịch của Bootstrap

    // Hiển thị giao diện trống khi chưa tìm thấy bệnh nhân hoặc xảy ra lỗi
    function renderEmpty(message) {
        result.classList.add('d-none');
        empty.classList.remove('d-none');
        empty.textContent = message || 'Chưa có dữ liệu tra cứu.';
    }

    // Định dạng lại hiển thị giới tính
    function formatGender(g) {
        if (!g) return 'Chưa cập nhật';
        const lower = g.toLowerCase();
        if (lower === 'male' || lower === 'nam') return 'Nam';
        if (lower === 'female' || lower === 'nữ' || lower === 'nu') return 'Nữ';
        return g;
    }

    // Hiển thị nhãn trạng thái lịch khám với các biểu tượng và màu sắc tương ứng
    function renderStatusBadge(status) {
        const s = (status || '').toLowerCase();
        if (s === 'waiting') {
            return '<span class="status-pill status-pill-waiting"><i class="bi bi-clock-history"></i>Waiting (Chờ khám)</span>';
        } else if (s === 'checked_in') {
            return '<span class="status-pill status-pill-checkedin"><i class="bi bi-person-check-fill"></i>Checked_In</span>';
        } else if (s === 'in_progress') {
            return '<span class="status-pill status-pill-inprogress"><i class="bi bi-activity"></i>In_Progress</span>';
        } else if (s === 'completed') {
            return '<span class="status-pill status-pill-completed"><i class="bi bi-check-circle-fill"></i>Completed</span>';
        } else if (s === 'cancelled' || s === 'canceled') {
            return '<span class="status-pill status-pill-cancelled"><i class="bi bi-x-circle-fill"></i>Cancelled (Đã hủy)</span>';
        }
        return '<span class="status-pill">' + utils.escapeHtml(status) + '</span>';
    }

    // Sinh khối mã HTML cho một ô hiển thị thông tin (Tile)
    function infoTile(iconClass, label, value) {
        return '<div class="col-md-3 col-sm-6 mb-2">' +
               '  <div class="patient-info-tile">' +
               '    <div class="patient-tile-icon"><i class="bi ' + iconClass + '"></i></div>' +
               '    <div class="patient-tile-label">' + utils.escapeHtml(label) + '</div>' +
               '    <div class="patient-tile-value">' + utils.escapeHtml(value || 'Chưa có thông tin') + '</div>' +
               '  </div>' +
               '</div>';
    }

    // Vẽ giao diện thông tin bệnh nhân và danh sách lịch hẹn khám
    function renderPatient(data) {
        const patient = data.patient || {};
        const appointments = data.upcomingAppointments || (data.nextAppointment ? [data.nextAppointment] : []);
        const firstLetter = (patient.fullName || 'P').charAt(0).toUpperCase();

        let html = '';
        
        // 1. Khung Banner Hồ Sơ Cá Nhân Bệnh Nhân
        html += '<div class="patient-profile-banner">';
        html += '  <div class="d-flex align-items-center justify-content-between mb-4 flex-wrap gap-3 pb-3 border-bottom border-secondary border-opacity-25">';
        html += '    <div class="d-flex align-items-center gap-3">';
        html += '      <div class="patient-avatar-circle">' + firstLetter + '</div>';
        html += '      <div>';
        html += '        <h2 class="h4 fw-bold text-white mb-1">' + utils.escapeHtml(patient.fullName || 'Chưa rõ họ tên') + '</h2>';
        html += '        <div class="text-secondary small"><i class="bi bi-telephone me-1"></i>' + utils.escapeHtml(patient.phone || '') + '</div>';
        html += '      </div>';
        html += '    </div>';
        html += '    <span class="badge bg-success bg-opacity-25 text-success border border-success border-opacity-50 px-3 py-2 rounded-pill font-monospace"><i class="bi bi-person-vcard me-1"></i>BN-' + (patient.patientId || '00') + '</span>';
        html += '  </div>';

        // 2. Lưới thông tin chi tiết (Lọc thẻ Grid)
        html += '  <div class="row g-2">';
        html += infoTile('bi-person-fill', 'Họ tên', patient.fullName);
        html += infoTile('bi-telephone-fill', 'Số điện thoại', patient.phone);
        html += infoTile('bi-envelope-fill', 'Email', patient.email);
        html += infoTile('bi-calendar-event-fill', 'Ngày sinh', patient.dateOfBirth);
        html += infoTile('bi-gender-ambiguous', 'Giới tính', formatGender(patient.gender));
        html += infoTile('bi-geo-alt-fill', 'Địa chỉ', patient.address);
        html += infoTile('bi-bar-chart-line-fill', 'Tổng số lịch hẹn', data.historyCount != null ? (data.historyCount + ' lịch hẹn') : '0');
        html += '  </div>';
        html += '</div>';

        // 3. Khối danh sách các Lịch hẹn khám
        html += '<div class="d-flex align-items-center justify-content-between mb-3 mt-4">';
        html += '  <h3 class="h5 text-white fw-bold mb-0"><i class="bi bi-calendar2-week-fill me-2 text-info"></i>Danh sách lịch hẹn (' + appointments.length + ')</h3>';
        html += '</div>';
        
        if (appointments && appointments.length > 0) {
            appointments.forEach(function (app, idx) {
                // Xác định xem lịch hẹn có thể thực hiện hủy hay không (ca khám đang chờ)
                const canCancel = app.canCancel || (app.status && app.status.toLowerCase() === 'waiting');
                
                html += '<div class="appointment-card-custom">';
                html += '  <div class="appointment-header">';
                html += '    <div class="appointment-title"><i class="bi bi-bookmark-check-fill text-info"></i>Lịch hẹn #' + (appointments.length - idx) + '</div>';
                html += '    <div class="d-flex align-items-center gap-2">';
                html += '      ' + renderStatusBadge(app.status);
                if (canCancel) {
                    html += '  <button type="button" class="btn btn-cancel-custom btn-trigger-cancel ms-2" '
                        + 'data-id="' + app.appointmentId + '" '
                        + 'data-doctor="' + utils.escapeHtml(app.doctorName || 'Bác sĩ') + '" '
                        + 'data-time="' + utils.escapeHtml(app.appointmentTime || '') + '" '
                        + 'data-patient="' + utils.escapeHtml(patient.fullName || '') + '">'
                        + '<i class="bi bi-x-circle-fill me-1"></i>Hủy Lịch</button>';
                }
                html += '    </div>';
                html += '  </div>';
                
                html += '  <div class="row g-2">';
                html += infoTile('bi-person-badge-fill', 'Bác sĩ khám', app.doctorName);
                html += infoTile('bi-clock-fill', 'Thời gian hẹn', app.appointmentTime);
                html += infoTile('bi-laptop-fill', 'Loại đặt lịch', app.bookingType);
                html += infoTile('bi-hash', 'Số thứ tự', app.queueNumber ? ('STT: ' + app.queueNumber) : 'Chưa xếp');
                html += '  </div>';
                html += '</div>';
            });
        } else {
            html += '<div class="empty-state p-4 text-center text-secondary border border-secondary border-opacity-25 rounded-4"><i class="bi bi-calendar-x fs-1 d-block mb-2 text-muted"></i>Bệnh nhân này chưa có lịch hẹn nào.</div>';
        }

        result.innerHTML = html;
        result.classList.remove('d-none');
        empty.classList.add('d-none');

        // Gắn sự kiện click vào các nút Hủy lịch
        const cancelBtns = result.querySelectorAll('.btn-trigger-cancel');
        cancelBtns.forEach(function (btn) {
            btn.addEventListener('click', function () {
                pendingCancelApptId = this.getAttribute('data-id');
                const doctor = this.getAttribute('data-doctor');
                const time = this.getAttribute('data-time');
                const patientName = this.getAttribute('data-patient');

                cancelModalMessage.innerHTML = 'Bạn có chắc chắn muốn hủy lịch khám của bệnh nhân <strong class="text-white">' 
                    + utils.escapeHtml(patientName) + '</strong> vào lúc <strong class="text-warning">' 
                    + utils.escapeHtml(time) + '</strong> với <strong class="text-info">' 
                    + utils.escapeHtml(doctor) + '</strong> không?';
                
                cancelReasonInput.value = '';

                // Hiển thị hộp thoại Modal xác nhận của Bootstrap
                if (window.bootstrap && confirmCancelModalEl) {
                    confirmCancelModalInstance = window.bootstrap.Modal.getOrCreateInstance(confirmCancelModalEl);
                    confirmCancelModalInstance.show();
                }
            });
        });
    }

    // Thực hiện gọi API tìm kiếm thông tin bệnh nhân theo số điện thoại
    async function searchPatient() {
        const phone = phoneInput.value.trim();
        if (!phone) {
            renderEmpty('Vui lòng nhập số điện thoại.');
            return;
        }
        searchButton.disabled = true;
        searchButton.textContent = 'Đang tìm...';
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients/search?phone=' + encodeURIComponent(phone));
            renderPatient(data);
        } catch (error) {
            renderEmpty(error.message);
        } finally {
            searchButton.disabled = false;
            searchButton.innerHTML = '<i class="bi bi-search me-1"></i>Tìm kiếm';
        }
    }

    // Lắng nghe sự kiện click trên nút Xác nhận hủy lịch trong Modal
    if (confirmCancelSubmitBtn) {
        confirmCancelSubmitBtn.addEventListener('click', async function () {
            if (!pendingCancelApptId) return;
            const reason = cancelReasonInput.value.trim();
            confirmCancelSubmitBtn.disabled = true;
            confirmCancelSubmitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Đang hủy...';
            try {
                // Gửi yêu cầu hủy lịch khám qua POST API lên Server
                const response = await utils.requestJson(utils.apiBase() + '/appointments/cancel', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'appointmentId=' + encodeURIComponent(pendingCancelApptId) + '&reason=' + encodeURIComponent(reason)
                });
                if (confirmCancelModalInstance) {
                    confirmCancelModalInstance.hide();
                }
                alert(response.message || 'Đã hủy lịch khám thành công!');
                searchPatient(); // Tải lại danh sách lịch hẹn để cập nhật trạng thái mới
            } catch (err) {
                alert('Lỗi: ' + (err.message || 'Không thể hủy lịch khám.'));
            } finally {
                confirmCancelSubmitBtn.disabled = false;
                confirmCancelSubmitBtn.innerHTML = '<i class="bi bi-check-circle me-1"></i>Xác Nhận Hủy';
            }
        });
    }

    searchButton.addEventListener('click', searchPatient);
    phoneInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') searchPatient();
    });
})();
