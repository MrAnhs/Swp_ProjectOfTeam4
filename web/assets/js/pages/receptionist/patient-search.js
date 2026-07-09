(function () {
    const utils = window.ReceptionistUtils;
    const phoneInput = document.getElementById('patientSearchPhone');
    const searchButton = document.getElementById('patientSearchBtn');
    const result = document.getElementById('patientSearchResult');
    const empty = document.getElementById('patientSearchEmpty');

    function renderEmpty(message) {
        result.classList.add('d-none');
        empty.classList.remove('d-none');
        empty.textContent = message || 'Chưa có dữ liệu tra cứu.';
    }

    function item(label, value) {
        return '<div class="result-item"><div class="result-label">' + utils.escapeHtml(label)
            + '</div><div class="result-value">' + utils.escapeHtml(value || 'Chưa có thông tin') + '</div></div>';
    }

    function renderPatient(data) {
        const patient = data.patient || {};
        const appointment = data.nextAppointment;
        let html = '<h3 class="h5 mb-3">Thông tin bệnh nhân</h3><div class="result-grid">';
        html += item('Họ tên', patient.fullName);
        html += item('Số điện thoại', patient.phone);
        html += item('Email', patient.email);
        html += item('Ngày sinh', patient.dateOfBirth);
        html += item('Giới tính', patient.gender);
        html += item('Địa chỉ', patient.address);
        html += item('Tổng số lịch hẹn', data.historyCount);
        html += '</div><hr><h3 class="h5 mb-3">Lịch hẹn gần nhất</h3>';
        if (appointment) {
            html += '<div class="result-grid">';
            html += item('Bác sĩ', appointment.doctorName);
            html += item('Thời gian', appointment.appointmentTime);
            html += item('Loại đặt lịch', appointment.bookingType);
            html += item('Số thứ tự', appointment.queueNumber ? 'Số ' + appointment.queueNumber : '');
            html += item('Trạng thái', appointment.status);
            html += '</div>';
        } else {
            html += '<div class="empty-state">Bệnh nhân chưa có lịch hẹn.</div>';
        }
        result.innerHTML = html;
        result.classList.remove('d-none');
        empty.classList.add('d-none');
    }

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

    searchButton.addEventListener('click', searchPatient);
    phoneInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') searchPatient();
    });
})();
