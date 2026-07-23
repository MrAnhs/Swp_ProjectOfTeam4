(function () {
    const utils = window.ReceptionistUtils;
    const form = document.getElementById('appointmentRegistrationForm');
    const doctorSelect = document.getElementById('registerDoctor');
    const scheduleSelect = document.getElementById('registerScheduleSlot');
    const result = document.getElementById('registrationResult');
    const lookupInput = document.getElementById('patientLookupKeyword');
    const lookupButton = document.getElementById('patientLookupBtn');

    function showResult(html, type) {
        result.className = 'result-card mt-4 alert alert-' + (type || 'info');
        result.innerHTML = html;
    }

    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone);
    }

    function prefillFromQuery() {
        const params = new URLSearchParams(window.location.search);
        const values = {
            patientName: params.get('patientName'),
            patientPhone: params.get('patientPhone'),
            patientEmail: params.get('patientEmail'),
            patientDob: params.get('patientDob'),
            patientGender: params.get('patientGender'),
            patientAddress: params.get('patientAddress'),
            visitType: params.get('visitType'),
            revisitAppointmentId: params.get('revisitAppointmentId')
        };
        let hasValue = false;
        Object.entries(values).forEach(function (entry) {
            let inputId = '';
            if (entry[0] === 'patientName') inputId = 'registerPatientName';
            else if (entry[0] === 'patientPhone') inputId = 'registerPatientPhone';
            else if (entry[0] === 'patientEmail') inputId = 'registerPatientEmail';
            else if (entry[0] === 'patientDob') inputId = 'registerPatientDob';
            else if (entry[0] === 'patientGender') inputId = 'registerPatientGender';
            else if (entry[0] === 'patientAddress') inputId = 'registerPatientAddress';
            else if (entry[0] === 'visitType') inputId = 'registerVisitType';
            else if (entry[0] === 'revisitAppointmentId') inputId = 'registerRevisitAppointmentId';

            const input = document.getElementById(inputId);
            if (input && entry[1]) {
                input.value = entry[1];
                hasValue = true;
            }
        });
        if (hasValue) {
            showResult('\u0110\u00e3 t\u1ef1 \u0111\u1ed9ng \u0111i\u1ec1n th\u00f4ng tin b\u1ec7nh nh\u00e2n. Vui l\u00f2ng ch\u1ecdn b\u00e1c s\u0129 v\u00e0 ca kh\u00e1m \u0111\u1ec3 ho\u00e0n t\u1ea5t.', 'info');
        }
    }

    function fillPatient(patient) {
        const values = {
            registerPatientName: patient.fullName,
            registerPatientPhone: patient.phone,
            registerPatientEmail: patient.email,
            registerPatientDob: patient.dateOfBirth,
            registerPatientGender: patient.gender,
            registerPatientAddress: patient.address
        };
        Object.entries(values).forEach(function (entry) {
            const input = document.getElementById(entry[0]);
            if (input && entry[1] != null) input.value = entry[1];
        });
    }

    async function lookupPatient() {
        const keyword = lookupInput.value.trim();
        if (!keyword) {
            showResult('Vui l\u00f2ng nh\u1eadp s\u1ed1 \u0111i\u1ec7n tho\u1ea1i ho\u1eb7c h\u1ecd t\u00ean b\u1ec7nh nh\u00e2n.', 'danger');
            return;
        }
        lookupButton.disabled = true;
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients/search?keyword=' + encodeURIComponent(keyword));
            fillPatient(data.patient || {});
            showResult('\u0110\u00e3 t\u00ecm th\u1ea5y v\u00e0 \u0111i\u1ec1n th\u00f4ng tin b\u1ec7nh nh\u00e2n. Vui l\u00f2ng ch\u1ecdn b\u00e1c s\u0129 v\u00e0 ca kh\u00e1m.', 'info');
        } catch (error) {
            showResult(utils.escapeHtml(error.message), 'danger');
        } finally {
            lookupButton.disabled = false;
        }
    }

    function updateMatchingSummary() {
        const selectedDep = document.getElementById('filterDepartment').value;
        const selectedDate = document.getElementById('filterDate').value;
        
        const allCards = document.querySelectorAll('.doctor-booking-card');
        let visibleCount = 0;
        allCards.forEach(function (card) {
            const parentCol = card.closest('.col-md-6');
            if (parentCol && !parentCol.classList.contains('d-none')) {
                visibleCount++;
            }
        });
        
        document.getElementById('bookingDoctorCount').innerHTML = `<i class="bi bi-people-fill me-1"></i> T\u00ECm th\u1EA5y ${visibleCount} b\u00E1c s\u0129 ph\u00F9 h\u1EE3p`;
        
        let desc = '';
        if (selectedDep) {
            desc += `Khoa ${selectedDep}, `;
        } else {
            desc += `T\u1EA5t c\u1EA3 c\u00E1c khoa, `;
        }
        desc += `l\u1ECBch c\u00F2n tr\u1ED1ng ng\u00E0y ${formatDate(selectedDate)} theo b\u1ED9 l\u1ECDc \u0111\u00E3 ch\u1ECDn.`;
        document.getElementById('bookingFilterDescription').textContent = desc;
    }

    async function loadDoctorCards() {
        const department = document.getElementById('filterDepartment').value;
        const searchName = document.getElementById('searchDoctorName').value.toLowerCase().trim();
        const cardsList = document.getElementById('doctorCardsList');
        
        cardsList.innerHTML = '<div class="text-center py-4 col-12"><div class="spinner-border text-primary" role="status"></div> \u0110ang t\u1EA3i danh s\u00E1ch b\u00E1c s\u0129...</div>';
        
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
        const revisitAppointmentId = document.getElementById('registerRevisitAppointmentId').value.trim();
        const visitType = document.getElementById('registerVisitType').value;
        if (visitType === 'Revisit' && !revisitAppointmentId) {
            showResult('Vui lòng nhập mã lịch hẹn cũ cho trường hợp tái khám.', 'danger');
            return;
        }
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
        if (visitType === 'Revisit') {
            body.set('revisitAppointmentId', revisitAppointmentId);
        }
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
    document.addEventListener('DOMContentLoaded', function () {
        prefillFromQuery();
        loadDoctors();
    });
    lookupButton.addEventListener('click', lookupPatient);
    lookupInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            lookupPatient();
        }
    });
    document.getElementById('resetRegistrationBtn').addEventListener('click', function () {
        form.reset();
        result.className = 'result-card mt-4 d-none';
        scheduleSelect.innerHTML = '<option value="">Ch\u1ECDn b\u00E1c s\u0129 tr\u01B0\u1EDBc</option>';
    });
})();
