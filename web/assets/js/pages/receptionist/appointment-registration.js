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
            doctorSelect.innerHTML = '<option value="">Ch\u1ECDn b\u00E1c s\u0129</option>';
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
        scheduleSelect.innerHTML = '<option value="">\u0110ang t\u1EA3i ca kh\u00E1m...</option>';
        if (!doctorId) {
            scheduleSelect.innerHTML = '<option value="">Ch\u1ECDn b\u00E1c s\u0129 tr\u01B0\u1EDBc</option>';
            return;
        }
        try {
            const data = await utils.requestJson(utils.apiBase() + '/schedules?doctorId=' + encodeURIComponent(doctorId));
            scheduleSelect.innerHTML = '<option value="">Ch\u1ECDn ca kh\u00E1m</option>';
            (data.slots || []).forEach(function (slot) {
                const option = document.createElement('option');
                option.value = slot.scheduleId;
                option.textContent = slot.label + ' - c\u00F2n ' + slot.available + ' ch\u1ED7';
                scheduleSelect.appendChild(option);
            });
            if (!data.slots || data.slots.length === 0) {
                scheduleSelect.innerHTML = '<option value="">B\u00E1c s\u0129 ch\u01B0a c\u00F3 ca tr\u1ED1ng</option>';
            }
        } catch (error) {
            scheduleSelect.innerHTML = '<option value="">' + error.message + '</option>';
        }
    }

    async function submitForm(event) {
        event.preventDefault();
        const phone = document.getElementById('registerPatientPhone').value.trim();
        if (!validVietnamesePhone(phone)) {
            showResult('S\u1ED1 \u0111i\u1EC7n tho\u1EA1i Vi\u1EC7t Nam kh\u00F4ng h\u1EE3p l\u1EC7.', 'danger');
            return;
        }
        const dob = document.getElementById('registerPatientDob').value;
        if (dob && (new Date(dob + 'T00:00:00') > new Date())) {
            showResult('Ng\u00E0y sinh kh\u00F4ng \u0111\u01B0\u1EE3c l\u1EDBn h\u01A1n ng\u00E0y hi\u1EC7n t\u1EA1i.', 'danger');
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
                '<h3 class="h5">\u0110\u0103ng k\u00FD kh\u00E1m th\u00E0nh c\u00F4ng</h3>'
                + '<p class="mb-1">M\u00E3 b\u1EC7nh nh\u00E2n: <strong>' + utils.escapeHtml(data.patientId) + '</strong></p>'
                + '<p class="mb-1">Th\u1EDDi gian kh\u00E1m: <strong>' + utils.escapeHtml(data.appointmentTime) + '</strong></p>'
                + '<p class="mb-0">S\u1ED1 th\u1EE9 t\u1EF1: <strong>S\u1ED1 ' + utils.escapeHtml(data.queueNumber) + '</strong></p>',
                'success'
            );
            form.reset();
            loadDoctors();
            scheduleSelect.innerHTML = '<option value="">Ch\u1ECDn b\u00E1c s\u0129 tr\u01B0\u1EDBc</option>';
        } catch (error) {
            showResult(error.message, 'danger');
        }
    }

    doctorSelect.addEventListener('change', loadSchedules);
    form.addEventListener('submit', submitForm);
    document.getElementById('resetRegistrationBtn').addEventListener('click', function () {
        form.reset();
        result.className = 'result-card mt-4 d-none';
        scheduleSelect.innerHTML = '<option value="">Ch\u1ECDn b\u00E1c s\u0129 tr\u01B0\u1EDBc</option>';
    });
    document.addEventListener('DOMContentLoaded', loadDoctors);
})();
