(function () {
    const utils = window.ReceptionistUtils;
    const form = document.getElementById('appointmentRegistrationForm');
    const doctorSelect = document.getElementById('registerDoctor');
    const scheduleSelect = document.getElementById('registerScheduleSlot');
    const result = document.getElementById('registrationResult');

    function showResult(html, type) {
        result.className = 'result-card mt-4 alert alert-' + (type || 'info');
        result.innerHTML = html;
    }

    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone);
    }

    async function loadDoctors() {
        try {
            const data = await utils.requestJson(utils.apiBase() + '/doctors');
            doctorSelect.innerHTML = '<option value="">Chọn bác sĩ</option>';
            (data.doctors || []).forEach(function (doctor) {
                const option = document.createElement('option');
                option.value = doctor.doctorId;
                option.textContent = doctor.fullName + (doctor.department ? ' - ' + doctor.department : '');
                doctorSelect.appendChild(option);
            });
        } catch (error) {
            doctorSelect.innerHTML = '<option value="">' + error.message + '</option>';
        }
    }

    async function loadSchedules() {
        const doctorId = doctorSelect.value;
        scheduleSelect.innerHTML = '<option value="">Đang tải ca khám...</option>';
        if (!doctorId) {
            scheduleSelect.innerHTML = '<option value="">Chọn bác sĩ trước</option>';
            return;
        }
        try {
            const data = await utils.requestJson(utils.apiBase() + '/schedules?doctorId=' + encodeURIComponent(doctorId));
            scheduleSelect.innerHTML = '<option value="">Chọn ca khám</option>';
            (data.slots || []).forEach(function (slot) {
                const option = document.createElement('option');
                option.value = slot.scheduleId;
                option.textContent = slot.label + ' - còn ' + slot.available + ' chỗ';
                scheduleSelect.appendChild(option);
            });
            if (!data.slots || data.slots.length === 0) {
                scheduleSelect.innerHTML = '<option value="">Bác sĩ chưa có ca trống</option>';
            }
        } catch (error) {
            scheduleSelect.innerHTML = '<option value="">' + error.message + '</option>';
        }
    }

    async function submitForm(event) {
        event.preventDefault();
        const phone = document.getElementById('registerPatientPhone').value.trim();
        if (!validVietnamesePhone(phone)) {
            showResult('Số điện thoại Việt Nam không hợp lệ.', 'danger');
            return;
        }
        const dob = document.getElementById('registerPatientDob').value;
        if (dob && (new Date(dob + 'T00:00:00') > new Date())) {
            showResult('Ngày sinh không được lớn hơn ngày hiện tại.', 'danger');
            return;
        }

        const body = new URLSearchParams(new FormData(form));
        try {
            const data = await utils.requestJson(utils.apiBase() + '/appointments', {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: body.toString()
            });
            showResult(
                '<h3 class="h5">Đăng ký khám thành công</h3>'
                + '<p class="mb-1">Mã bệnh nhân: <strong>' + utils.escapeHtml(data.patientId) + '</strong></p>'
                + '<p class="mb-1">Thời gian khám: <strong>' + utils.escapeHtml(data.appointmentTime) + '</strong></p>'
                + '<p class="mb-0">Số thứ tự: <strong>Số ' + utils.escapeHtml(data.queueNumber) + '</strong></p>',
                'success'
            );
            form.reset();
            loadDoctors();
            scheduleSelect.innerHTML = '<option value="">Chọn bác sĩ trước</option>';
        } catch (error) {
            showResult(error.message, 'danger');
        }
    }

    doctorSelect.addEventListener('change', loadSchedules);
    form.addEventListener('submit', submitForm);
    document.getElementById('resetRegistrationBtn').addEventListener('click', function () {
        form.reset();
        result.className = 'result-card mt-4 d-none';
        scheduleSelect.innerHTML = '<option value="">Chọn bác sĩ trước</option>';
    });
    document.addEventListener('DOMContentLoaded', loadDoctors);
})();
