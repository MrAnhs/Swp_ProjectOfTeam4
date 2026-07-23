(function () {
    const utils = window.ReceptionistUtils;
    const form = document.getElementById('patientRegistrationForm');
    const result = document.getElementById('patientRegistrationResult');
    const submitButton = form.querySelector('button[type="submit"]');

    function showResult(html, type) {
        result.className = 'result-card mt-4 alert alert-' + (type || 'info');
        result.innerHTML = html;
    }

    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone);
    }

    function appointmentUrl(patient) {
        const params = new URLSearchParams({
            patientId: patient.patientId || '', patientName: patient.fullName || '',
            patientPhone: patient.phone || '', patientEmail: patient.email || '',
            patientDob: patient.dateOfBirth || '', patientGender: patient.gender || '',
            patientAddress: patient.address || ''
        });
        return utils.apiBase().replace('/api', '/appointments/new') + '?' + params.toString();
    }

    async function submitForm(event) {
        event.preventDefault();
        const phone = document.getElementById('patientRegisterPhone').value.trim();
        const dob = document.getElementById('patientRegisterDob').value;
        if (!validVietnamesePhone(phone)) {
            showResult('S\u1ed1 \u0111i\u1ec7n tho\u1ea1i Vi\u1ec7t Nam kh\u00f4ng h\u1ee3p l\u1ec7.', 'danger');
            return;
        }
        if (dob && new Date(dob + 'T00:00:00') > new Date()) {
            showResult('Ng\u00e0y sinh kh\u00f4ng \u0111\u01b0\u1ee3c l\u1edbn h\u01a1n ng\u00e0y hi\u1ec7n t\u1ea1i.', 'danger');
            return;
        }
        submitButton.disabled = true;
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients', {
                method: 'POST',
                headers: { Accept: 'application/json', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
                body: new URLSearchParams(new FormData(form)).toString()
            });
            const patient = data.patient || {};
            const credentialNotice = patient.temporaryPassword
                ? '<p class="mb-3">M\u1eadt kh\u1ea9u t\u1ea1m th\u1eddi: <strong>' + utils.escapeHtml(patient.temporaryPassword) + '</strong></p>'
                : '<p class="mb-3">B\u1ec7nh nh\u00e2n n\u00e0y \u0111\u00e3 c\u00f3 h\u1ed3 s\u01a1 tr\u00ean h\u1ec7 th\u1ed1ng.</p>';
            showResult('<h3 class="h5">T\u1ea1o h\u1ed3 s\u01a1 b\u1ec7nh nh\u00e2n th\u00e0nh c\u00f4ng</h3>'
                + '<p class="mb-3">M\u00e3 b\u1ec7nh nh\u00e2n: <strong>' + utils.escapeHtml(patient.patientId) + '</strong></p>'
                + credentialNotice
                + '<div class="d-flex gap-2">'
                + '<a class="btn btn-success" href="' + appointmentUrl(patient) + '"><i class="bi bi-calendar-plus me-1"></i>Ti\u1ebfn h\u00e0nh \u0111\u0103ng k\u00fd kh\u00e1m ngay</a>'
                + (patient.temporaryPassword ? '<button class="btn btn-primary" id="sendEmailBtn" type="button"><i class="bi bi-envelope me-1"></i>G\u1eedi email t\u00e0i kho\u1ea3n</button>' : '')
                + '</div>', 'success');

            const sendBtn = document.getElementById('sendEmailBtn');
            if (sendBtn) {
                sendBtn.addEventListener('click', async function () {
                    sendBtn.disabled = true;
                    sendBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>\u0110ang g\u1eedi...';
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
                        sendBtn.innerHTML = '<i class="bi bi-check-circle me-1"></i>\u0110\u00e3 g\u1eedi th\u00e0nh c\u00f4ng!';
                    } catch (error) {
                        alert(error.message);
                        sendBtn.disabled = false;
                        sendBtn.className = 'btn btn-danger';
                        sendBtn.innerHTML = '<i class="bi bi-exclamation-triangle me-1"></i>G\u1eedi l\u1ea1i email';
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
    document.getElementById('resetPatientRegistrationBtn').addEventListener('click', function () {
        form.reset();
        result.className = 'result-card mt-4 d-none';
    });
})();
