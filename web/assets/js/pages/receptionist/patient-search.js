(function () {
    const utils = window.ReceptionistUtils;
    const phoneInput = document.getElementById('patientSearchPhone');
    const searchButton = document.getElementById('patientSearchBtn');
    const result = document.getElementById('patientSearchResult');
    const empty = document.getElementById('patientSearchEmpty');

    function renderEmpty(message) {
        result.classList.add('d-none');
        empty.classList.remove('d-none');
        empty.textContent = message || 'Ch\u01B0a c\u00F3 d\u1EEF li\u1EC7u tra c\u1EE9u.';
    }

    function item(label, value) {
        return '<div class="result-item"><div class="result-label">' + utils.escapeHtml(label)
            + '</div><div class="result-value">' + utils.escapeHtml(value || 'Ch\u01B0a c\u00F3 th\u00F4ng tin') + '</div></div>';
    }

    function renderPatient(data) {
        const patient = data.patient || {};
        const appointment = data.nextAppointment;
        let html = '<h3 class="h5 mb-3">Th\u00F4ng tin b\u1EC7nh nh\u00E2n</h3><div class="result-grid">';
        html += item('H\u1ECD t\u00EAn', patient.fullName);
        html += item('S\u1ED1 \u0111i\u1EC7n tho\u1EA1i', patient.phone);
        html += item('Email', patient.email);
        html += item('Ng\u00E0y sinh', patient.dateOfBirth);
        html += item('Gi\u1EDBi t\u00EDnh', patient.gender);
        html += item('\u0110\u1ECBa ch\u1EC9', patient.address);
        html += item('T\u1ED5ng s\u1ED1 l\u1ECBch h\u1EB9n', data.historyCount);
        html += '</div><hr><h3 class="h5 mb-3">L\u1ECBch h\u1EB9n g\u1EA7n nh\u1EA5t</h3>';
        if (appointment) {
            html += '<div class="result-grid">';
            html += item('B\u00E1c s\u0129', appointment.doctorName);
            html += item('Th\u1EDDi gian', appointment.appointmentTime);
            html += item('Lo\u1EA1i \u0111\u1EB7t l\u1ECBch', appointment.bookingType);
            html += item('S\u1ED1 th\u1EE9 t\u1EF1', appointment.queueNumber ? 'S\u1ED1 ' + appointment.queueNumber : '');
            html += item('Tr\u1EA1ng th\u00E1i', appointment.status);
            html += '</div>';
        } else {
            html += '<div class="empty-state">B\u1EC7nh nh\u00E2n ch\u01B0a c\u00F3 l\u1ECBch h\u1EB9n.</div>';
        }
        result.innerHTML = html;
        result.classList.remove('d-none');
        empty.classList.add('d-none');
    }

    async function searchPatient() {
        const phone = phoneInput.value.trim();
        if (!phone) {
            renderEmpty('Vui l\u00F2ng nh\u1EADp s\u1ED1 \u0111i\u1EC7n tho\u1EA1i.');
            return;
        }
        searchButton.disabled = true;
        searchButton.textContent = '\u0110ang t\u00ECm...';
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients/search?phone=' + encodeURIComponent(phone));
            renderPatient(data);
        } catch (error) {
            renderEmpty(error.message);
        } finally {
            searchButton.disabled = false;
            searchButton.innerHTML = '<i class="bi bi-search me-1"></i>T\u00ECm ki\u1EBFm';
        }
    }

    searchButton.addEventListener('click', searchPatient);
    phoneInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') searchPatient();
    });
})();
