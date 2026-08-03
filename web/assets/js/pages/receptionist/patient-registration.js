(function () {
    // Quản lý đăng ký hồ sơ bệnh nhân mới tại quầy Lễ tân
    const utils = window.ReceptionistUtils;
    const form = document.getElementById('patientRegistrationForm');
    const result = document.getElementById('patientRegistrationResult');
    const submitButton = form.querySelector('button[type="submit"]');

    // Hiển thị hộp kết quả (thành công hoặc lỗi) trên giao diện
    function showResult(html, type) {
        result.className = 'result-card mt-4 alert alert-' + (type || 'info');
        result.innerHTML = html;
    }

    // Kiểm tra định dạng số điện thoại Việt Nam hợp lệ
    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone);
    }

    // Tạo URL chuyển hướng sang Đăng ký khám với thông tin bệnh nhân vừa tạo điền sẵn
    function appointmentUrl(patient) {
        const params = new URLSearchParams({
            patientId: patient.patientId || '', patientName: patient.fullName || '',
            patientPhone: patient.phone || '', patientEmail: patient.email || '',
            patientDob: patient.dateOfBirth || '', patientGender: patient.gender || '',
            patientAddress: patient.address || ''
        });
        return utils.apiBase().replace('/api', '/appointments/new') + '?' + params.toString();
    }

    // Xử lý gửi form đăng ký bệnh nhân mới lên server
    async function submitForm(event) {
        event.preventDefault();
        const phoneEl = document.getElementById('regPhone') || document.getElementById('patientRegisterPhone');
        const dobEl = document.getElementById('regDob') || document.getElementById('patientRegisterDob');
        const phone = phoneEl ? phoneEl.value.trim() : '';
        const dob = dobEl ? dobEl.value : '';

        // Kiểm tra hợp lệ số điện thoại phía Client
        if (!validVietnamesePhone(phone)) {
            showResult('Số điện thoại Việt Nam không hợp lệ (ví dụ 0912345678).', 'danger');
            return;
        }

        // Kiểm tra hợp lệ ngày sinh (không được lớn hơn hôm nay)
        if (dob && new Date(dob + 'T00:00:00') > new Date()) {
            showResult('Ngày sinh không được lớn hơn ngày hiện tại.', 'danger');
            return;
        }

        submitButton.disabled = true;
        try {
            // Gửi dữ liệu form qua POST API tới Server
            const data = await utils.requestJson(utils.apiBase() + '/patients', {
                method: 'POST',
                headers: { Accept: 'application/json', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
                body: new URLSearchParams(new FormData(form)).toString()
            });
            const patient = data.patient || {};

            // Nếu là bệnh nhân mới, hệ thống tự động sinh mật khẩu tạm thời
            const credentialNotice = patient.temporaryPassword
                ? '<p class="mb-3">Mật khẩu tạm thời: <strong>' + utils.escapeHtml(patient.temporaryPassword) + '</strong></p>'
                : '<p class="mb-3">Bệnh nhân này đã có hồ sơ trên hệ thống.</p>';

            // Hiển thị thông báo thành công và các nút liên kết hành động tiếp theo
            showResult('<h3 class="h5">Tạo hồ sơ bệnh nhân thành công</h3>'
                + '<p class="mb-3">Mã bệnh nhân: <strong>' + utils.escapeHtml(patient.patientId) + '</strong></p>'
                + credentialNotice
                + '<div class="d-flex gap-2">'
                + '<a class="btn btn-success" href="' + appointmentUrl(patient) + '"><i class="bi bi-calendar-plus me-1"></i>Tiến hành đăng ký khám ngay</a>'
                + (patient.temporaryPassword ? '<button class="btn btn-primary" id="sendEmailBtn" type="button"><i class="bi bi-envelope me-1"></i>Gửi email tài khoản</button>' : '')
                + '</div>', 'success');

            // Xử lý gửi email thông tin tài khoản cho bệnh nhân (nếu có mật khẩu tạm thời)
            const sendBtn = document.getElementById('sendEmailBtn');
            if (sendBtn) {
                sendBtn.addEventListener('click', async function () {
                    sendBtn.disabled = true;
                    sendBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>Đang gửi...';
                    try {
                        await utils.requestJson(utils.apiBase() + '/patients/send-email', {
                            method: 'POST',
                            headers: { Accept: 'application/json', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
                            body: new URLSearchParams({
                                email: patient.email,
                                fullName: patient.fullName,
                                temporaryPassword: patient.temporaryPassword
                            }).toString()
                        });
                        sendBtn.className = 'btn btn-success';
                        sendBtn.innerHTML = '<i class="bi bi-check-circle me-1"></i>Đã gửi thành công!';
                    } catch (error) {
                        alert(error.message);
                        sendBtn.disabled = false;
                        sendBtn.className = 'btn btn-danger';
                        sendBtn.innerHTML = '<i class="bi bi-exclamation-triangle me-1"></i>Gửi lại email';
                    }
                });
            }
            form.reset();
        } catch (error) {
            showResult(utils.escapeHtml(error.message), 'danger');
        } finally {
            submitButton.disabled = false;
        }
    }

    form.addEventListener('submit', submitForm);

    // Lắng nghe sự kiện bấm nút Làm mới (Reset form)
    document.getElementById('resetPatientRegistrationBtn').addEventListener('click', function () {
        form.reset();
        result.className = 'result-card mt-4 d-none';
    });
})();
