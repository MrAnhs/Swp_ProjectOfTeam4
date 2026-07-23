(function () {
    const utils = window.ReceptionistUtils;
    const form = document.getElementById('appointmentRegistrationForm');
    const result = document.getElementById('registrationResult');
    const lookupInput = document.getElementById('patientLookupKeyword');
    const lookupButton = document.getElementById('patientLookupBtn');

    function showResult(html, type) {
        if (type === 'success') {
            result.className = 'result-card mt-4';
        } else {
            result.className = 'result-card mt-4 alert alert-' + (type || 'info');
        }
        result.innerHTML = html;
        result.classList.remove('d-none');
        result.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone) || /^\d+$/.test(phone);
    }

    // Check if time slot is in the morning
    function isMorning(timeSlot) {
        const hour = parseInt(timeSlot.substring(0, 2), 10);
        return !isNaN(hour) && hour < 12;
    }

    // Check if a slot on a specific date has already ended
    function isSlotEnded(workDate, timeSlot) {
        if (!workDate || !timeSlot) return true;
        try {
            const parts = timeSlot.split('-');
            if (parts.length < 2) return false;
            const endPart = parts[1].trim(); // e.g. "14:00"
            const endParts = endPart.split(':');
            if (endParts.length < 2) return false;
            
            const endHour = parseInt(endParts[0], 10);
            const endMin = parseInt(endParts[1], 10);
            
            const dateParts = workDate.split('-');
            if (dateParts.length !== 3) return false;
            
            const year = parseInt(dateParts[0], 10);
            const month = parseInt(dateParts[1], 10) - 1;
            const day = parseInt(dateParts[2], 10);
            
            const endTime = new Date(year, month, day, endHour, endMin, 0);
            return endTime <= new Date();
        } catch (e) {
            return false;
        }
    }

    function formatDate(dateValue) {
        if (!dateValue) return '';
        const parts = dateValue.split('-');
        if (parts.length === 3) {
            return parts[2] + '/' + parts[1] + '/' + parts[0];
        }
        return dateValue;
    }

    function todayValue() {
        const today = new Date();
        return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
    }

    function prefillFromQuery() {
        const params = new URLSearchParams(window.location.search);
        const patient = {
            fullName: params.get('patientName'),
            phone: params.get('patientPhone'),
            email: params.get('patientEmail'),
            dateOfBirth: params.get('patientDob'),
            gender: params.get('patientGender'),
            address: params.get('patientAddress')
        };
        if (patient.fullName && patient.phone) {
            fillPatient(patient);
            showResult('\u0110\u00E3 t\u1EF1 \u0111\u1ED9ng \u0111i\u1EC1n th\u00F4ng tin b\u1EC7nh nh\u00E2n. Vui l\u00F2ng ch\u1ECDn b\u00E1c s\u0129 v\u00E0 ca kh\u00E1m \u0111\u1EC3 ho\u00E0n t\u1EA5t.', 'info');
        }
    }

    function fillPatient(patient) {
        const values = {
            registerPatientName: patient.fullName || '',
            registerPatientPhone: patient.phone || '',
            registerPatientEmail: patient.email || '',
            registerPatientDob: patient.dateOfBirth || '',
            registerPatientGender: patient.gender || 'Male',
            registerPatientAddress: patient.address || ''
        };
        
        // Populate hidden inputs
        Object.entries(values).forEach(function (entry) {
            const input = document.getElementById(entry[0]);
            if (input) input.value = entry[1];
        });

        // Set preview labels
        document.getElementById('previewName').textContent = patient.fullName || '-';
        document.getElementById('previewPhone').textContent = patient.phone || '-';
        document.getElementById('previewDob').textContent = patient.dateOfBirth || '-';
        document.getElementById('previewGender').textContent = patient.gender === 'Male' ? 'Nam' : (patient.gender === 'Female' ? 'N\u1EE1' : 'Kh\u00E1c');
        document.getElementById('previewAddress').textContent = patient.address || 'Ch\u01B0a c\u1EADp nh\u1EADt';

        // Toggle UI panels
        document.getElementById('selectedPatientCard').classList.remove('d-none');
    }

    async function lookupPatient() {
        const keyword = lookupInput.value.trim();
        if (!keyword) {
            showResult('Vui l\u00F2ng nh\u1EADp s\u1ED1 \u0111i\u1EC7n tho\u1EA1i ho\u1EB7c h\u1ECD t\u00EAn b\u1EC7nh nh\u00E2n.', 'danger');
            return;
        }
        lookupButton.disabled = true;
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients/search?keyword=' + encodeURIComponent(keyword));
            if (!data.patient) {
                showResult('Kh\u00F4ng t\u00ECm th\u1EA5y b\u1EC7nh nh\u00E2n n\u00E0o c\u00F3 th\u00F4ng tin tr\u00EAn.', 'danger');
                return;
            }
            fillPatient(data.patient);
            showResult('\u0110\u00E3 t\u00ECm th\u1EA5y v\u00E0 \u0111i\u1EC1n th\u00F4ng tin b\u1EC7nh nh\u00E2n. Vui l\u00F2ng ch\u1ECDn b\u00E1c s\u0129 v\u00E0 ca kh\u00E1m.', 'info');
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
            let doctors = data.doctors || [];
            
            // Populate department filter options if not already done
            const depSelect = document.getElementById('filterDepartment');
            if (depSelect.options.length === 1) { // Only has the placeholder
                const departments = [...new Set(doctors.map(d => d.department).filter(Boolean))];
                departments.forEach(function (dep) {
                    const opt = document.createElement('option');
                    opt.value = dep;
                    opt.textContent = dep;
                    depSelect.appendChild(opt);
                });
            }
            
            // Filter doctors by department and name
            if (department) {
                doctors = doctors.filter(d => d.department === department);
            }
            if (searchName) {
                doctors = doctors.filter(d => d.fullName && d.fullName.toLowerCase().includes(searchName));
            }
            
            if (doctors.length === 0) {
                cardsList.innerHTML = '<div class="alert alert-warning text-center col-12">Kh\u00F4ng t\u00ECm th\u1EA5y b\u1EC7nh nh\u00E2n n\u00E0o ph\u00F9 h\u1EE3p.</div>';
                updateMatchingSummary();
                return;
            }
            
            cardsList.innerHTML = '';
            
            // Render each doctor card and load their schedules
            doctors.forEach(function (doctor) {
                const col = document.createElement('div');
                col.className = 'col-md-6 mb-3 d-none';
                col.id = 'col-doc-' + doctor.doctorId;
                col.innerHTML = `
                    <article class="doctor-booking-card h-100 d-flex flex-column" id="card-doc-${doctor.doctorId}" data-doctor-id="${doctor.doctorId}">
                        <div class="doctor-booking-card__header">
                            <div class="doctor-booking-card__identity">
                                <span class="doctor-avatar"><i class="bi bi-person-fill"></i></span>
                                <div>
                                    <h3>${utils.escapeHtml(doctor.fullName)}</h3>
                                    <p>Chuy\u00EAn khoa: ${utils.escapeHtml(doctor.department || 'Ch\u01B0a c\u1EADp nh\u1EADt')}</p>
                                </div>
                            </div>
                        </div>
                        <div class="doctor-booking-card__schedules flex-grow-1">
                            <div class="doctor-schedule-heading">
                                <strong>Gi\u1EDD kh\u00E1m c\u00F2n tr\u1ED1ng</strong>
                                <span>Ch\u1ECDn m\u1ED9t khung gi\u1EDD \u0111\u1EC3 \u0111\u0103ng k\u00FD</span>
                            </div>
                            <div class="slots-container" id="slots-doc-${doctor.doctorId}">
                                <div class="text-center py-2"><span class="spinner-border spinner-border-sm text-secondary"></span> \u0110ang t\u1EA3i l\u1ECBch...</div>
                            </div>
                        </div>
                        <div class="doctor-booking-card__footer d-flex flex-column gap-2">
                            <div class="w-100">
                                <select class="form-select form-select-sm visit-type-select" id="visit-type-${doctor.doctorId}" style="font-size: 13px;">
                                    <option value="New">Kh\u00E1m m\u1EDBi</option>
                                    <option value="Revisit">T\u00E1i kh\u00E1m</option>
                                </select>
                            </div>
                            <button type="button" class="btn btn-success btn-sm w-100 book-doctor-btn" id="btn-book-${doctor.doctorId}" data-doctor-id="${doctor.doctorId}" disabled>
                                <i class="bi bi-calendar-check me-1"></i> \u0110\u0103ng k\u00FD kh\u00E1m
                            </button>
                        </div>
                    </article>
                `;
                cardsList.appendChild(col);
                
                // Add click listener to the newly generated card button
                const btn = col.querySelector('.book-doctor-btn');
                btn.addEventListener('click', function (e) {
                    e.preventDefault();
                    submitBooking();
                });
                
                // Fetch schedules for this doctor card
                loadSchedulesForCard(doctor.doctorId);
            });
            
            // Trigger summary update after small timeout
            setTimeout(updateMatchingSummary, 300);
            
        } catch (error) {
            cardsList.innerHTML = '<div class="alert alert-danger col-12">L\u1ED7i khi t\u1EA3i danh s\u00E1ch b\u00E1c s\u0129: ' + utils.escapeHtml(error.message) + '</div>';
        }
    }

    function createSlotElement(doctorId, slot) {
        const uniqueId = `slot-${doctorId}-${slot.scheduleId}`;
        const label = document.createElement('label');
        label.className = 'doctor-time-slot';
        
        label.innerHTML = `
            <input type="radio" class="slot-radio-btn" name="globalScheduleId" id="${uniqueId}" value="${slot.scheduleId}" data-doctor-id="${doctorId}">
            <strong>${utils.escapeHtml(slot.timeSlot)}</strong>
            <small>C\u00F2n ${slot.available} ch\u1ED7</small>
            <small class="doctor-time-room">Ph\u00F2ng: ${utils.escapeHtml(slot.roomName || 'Ch\u01B0a ph\u00E2n ph\u00F2ng')}</small>
            <small class="doctor-time-location">${utils.escapeHtml(slot.roomLocation || 'Ch\u01B0a c\u1EADp nh\u1EADt v\u1ECB tr\u00ED')}</small>
        `;
        return label;
    }

    async function loadSchedulesForCard(doctorId) {
        const container = document.getElementById('slots-doc-' + doctorId);
        const cardCol = document.getElementById('col-doc-' + doctorId);
        try {
            const data = await utils.requestJson(utils.apiBase() + '/schedules?doctorId=' + encodeURIComponent(doctorId));
            const slots = data.slots || [];
            
            // Filter slots on client side
            const selectedDate = document.getElementById('filterDate').value;
            const selectedSession = document.getElementById('filterSession').value;
            
            let filteredSlots = slots;
            if (selectedDate) {
                filteredSlots = filteredSlots.filter(s => s.workDate === selectedDate);
            }
            if (selectedSession === 'morning') {
                filteredSlots = filteredSlots.filter(s => isMorning(s.timeSlot));
            } else if (selectedSession === 'afternoon') {
                filteredSlots = filteredSlots.filter(s => !isMorning(s.timeSlot));
            }
            
            // Filter out slots that have already ended
            filteredSlots = filteredSlots.filter(s => !isSlotEnded(s.workDate, s.timeSlot));
            
            if (filteredSlots.length === 0) {
                if (cardCol) cardCol.classList.add('d-none');
                updateMatchingSummary();
                return;
            }
            
            if (cardCol) cardCol.classList.remove('d-none');
            container.innerHTML = '';
            
            let morningSlots = filteredSlots.filter(s => isMorning(s.timeSlot));
            let afternoonSlots = filteredSlots.filter(s => !isMorning(s.timeSlot));
            
            if (morningSlots.length > 0) {
                const group = document.createElement('div');
                group.className = 'doctor-session-group';
                group.innerHTML = '<h4><i class="bi bi-sun me-1"></i> Bu\u1ED5i s\u00E1ng</h4>';
                const slotsDiv = document.createElement('div');
                slotsDiv.className = 'doctor-time-slots';
                morningSlots.forEach(function (slot) {
                    slotsDiv.appendChild(createSlotElement(doctorId, slot));
                });
                group.appendChild(slotsDiv);
                container.appendChild(group);
            }
            
            if (afternoonSlots.length > 0) {
                const group = document.createElement('div');
                group.className = 'doctor-session-group';
                group.innerHTML = '<h4><i class="bi bi-sunset me-1"></i> Bu\u1ED5i chi\u1EC1u</h4>';
                const slotsDiv = document.createElement('div');
                slotsDiv.className = 'doctor-time-slots';
                afternoonSlots.forEach(function (slot) {
                    slotsDiv.appendChild(createSlotElement(doctorId, slot));
                });
                group.appendChild(slotsDiv);
                container.appendChild(group);
            }
            
            // Add change listener
            container.querySelectorAll('.slot-radio-btn').forEach(function (radio) {
                radio.addEventListener('change', function () {
                    if (this.checked) {
                        document.getElementById('registerDoctor').value = this.dataset.doctorId;
                        document.getElementById('registerScheduleSlot').value = this.value;
                        
                        // Toggle active class on all slot labels
                        document.querySelectorAll('.doctor-time-slot').forEach(function (slotLabel) {
                            slotLabel.classList.toggle('active', slotLabel.contains(radio));
                        });
                        
                        // Enable current doctor card book button
                        const activeBtn = document.getElementById('btn-book-' + doctorId);
                        if (activeBtn) activeBtn.disabled = false;
                        
                        // Disable book button on all other doctor cards
                        document.querySelectorAll('.book-doctor-btn').forEach(function (btn) {
                            if (btn.id !== 'btn-book-' + doctorId) {
                                btn.disabled = true;
                            }
                        });
                        
                        document.querySelectorAll('.doctor-booking-card').forEach(function (c) {
                            c.classList.toggle('active', c.dataset.doctorId === String(doctorId));
                        });
                    }
                });
            });
            
            updateMatchingSummary();
            
        } catch (error) {
            container.innerHTML = '<div class="text-danger small py-1">L\u1ED7i t\u1EA3i l\u1ECBch.</div>';
            if (cardCol) cardCol.classList.add('d-none');
            updateMatchingSummary();
        }
    }

    async function submitBooking() {
        // Check if patient details are loaded
        const patientName = document.getElementById('registerPatientName').value;
        if (!patientName) {
            showResult('Vui l\u00F2ng t\u00ECm ki\u1EBFFm b\u1EC7nh nh\u00E2n ho\u1EB7c \u0111\u0103ng k\u00FD b\u1EC7nh nh\u00E2n m\u1EDBi tr\u01B0\u1EDBc khi \u0111\u0103ng k\u00FD kh\u00E1m.', 'danger');
            return;
        }

        const phone = document.getElementById('registerPatientPhone').value.trim();
        if (!validVietnamesePhone(phone)) {
            showResult('S\u1ED1 \u0111i\u1EC7n tho\u1EA1i Vi\u1EC7t Nam kh\u00F4ng h\u1EE3p l\u1EC7.', 'danger');
            return;
        }
        
        const selectedDoctorId = document.getElementById('registerDoctor').value;

        // Visit type from select box inside card
        const visitTypeSelect = document.getElementById('visit-type-' + selectedDoctorId);
        const visitType = visitTypeSelect ? visitTypeSelect.value : 'New';
        document.getElementById('registerVisitType').value = visitType;

        const activeBtn = document.getElementById('btn-book-' + selectedDoctorId);
        const originalHtml = activeBtn ? activeBtn.innerHTML : '';
        
        // Show loading spinner
        if (activeBtn) {
            document.querySelectorAll('.book-doctor-btn').forEach(btn => btn.disabled = true);
            activeBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> \u0110ang \u0111\u0103ng k\u00FD...';
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

            // Get selected doctor and schedule info from the DOM for the success receipt view
            const docCard = document.getElementById('card-doc-' + selectedDoctorId);
            const docNameText = docCard ? docCard.querySelector('.doctor-booking-card__identity h3').textContent.trim() : '';
            let deptText = docCard ? docCard.querySelector('.doctor-booking-card__identity p').textContent.trim() : '';
            if (deptText.startsWith('Chuyên khoa:')) {
                deptText = deptText.replace('Chuyên khoa:', '').trim();
            } else if (deptText.startsWith('Chuy\u00EAn khoa:')) {
                deptText = deptText.replace('Chuy\u00EAn khoa:', '').trim();
            }
            
            const activeSlotLabel = document.querySelector('.doctor-time-slot.active');
            const timeSlotText = activeSlotLabel ? activeSlotLabel.querySelector('strong').textContent.trim() : '';
            const roomNameText = activeSlotLabel ? activeSlotLabel.querySelector('.doctor-time-room').textContent.replace('Phòng: ', '').replace('Ph\u00F2ng: ', '').trim() : 'Ch\u01B0a ph\u00E2n ph\u00F2ng';
            const roomLocationText = activeSlotLabel ? activeSlotLabel.querySelector('.doctor-time-location').textContent.trim() : 'Ch\u01B0a c\u1EADp nh\u1EADt';
            
            const successHtml = `
                <div class="booking-success-container p-4 bg-white rounded-3 border border-success-subtle shadow-sm">
                    <div class="d-flex align-items-center gap-2 mb-2 text-success">
                        <i class="bi bi-check-circle-fill fs-4" style="color: #0f766e;"></i>
                        <h3 class="h4 mb-0 fw-bold" style="color: #0f766e;">\u0110\u1EB7t l\u1ECBch th\u00E0nh c\u00F4ng</h3>
                    </div>
                    <p class="text-muted mb-4">L\u1ECBch h\u1EB9n \u0111\u00E3 \u0111\u01B0\u1EE3c t\u1EA1o v\u00E0 \u0111ang \u1EDF tr\u1EA1ng th\u00E1i ch\u1EDD kh\u00E1m.</p>
                    
                    <div class="row g-3 text-start">
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">M\u00E3 l\u1ECBch h\u1EB9n</div>
                                <div class="fw-bold text-dark">#${data.appointmentId}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">B\u00E1c s\u0129</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(docNameText)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">Chuy\u00EAn khoa</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(deptText)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">Ng\u00E0y gi\u1EDD</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(data.appointmentTime)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">Ca kh\u00E1m</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(timeSlotText)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">Ph\u00F2ng kh\u00E1m</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(roomNameText)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">V\u1ECB tr\u00ED</div>
                                <div class="fw-bold text-dark">${utils.escapeHtml(roomLocationText)}</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="p-3 bg-light rounded-3 h-100">
                                <div class="text-muted small mb-1">S\u1ED1 th\u1EE9 t\u1EF1</div>
                                <div class="fw-bold text-dark">${data.queueNumber}</div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="d-flex justify-content-end gap-2 mt-4">
                        <button type="button" class="btn btn-secondary px-4 btn-close-result">\u0110\u00F3ng</button>
                        <a href="${window.ReceptionistConfig.contextPath}/receptionist/billing" class="btn btn-success px-4" style="background-color: #0f766e; border-color: #0f766e;"><i class="bi bi-wallet2 me-1"></i> Thanh to\u00E1n h\u00F3a \u0111\u01A1n</a>
                    </div>
                </div>
            `;
            
            showResult(successHtml, 'success');
            
            // Add close button listener
            const closeBtn = result.querySelector('.btn-close-result');
            if (closeBtn) {
                closeBtn.addEventListener('click', function () {
                    result.classList.add('d-none');
                });
            }
            
            resetPatientSelection();
        } catch (error) {
            showResult(error.message, 'danger');
            if (activeBtn) {
                activeBtn.disabled = false;
                activeBtn.innerHTML = originalHtml;
            }
        }
    }

    function resetPatientSelection() {
        form.reset();
        
        // Reset hidden values
        document.getElementById('registerPatientName').value = '';
        document.getElementById('registerPatientPhone').value = '';
        document.getElementById('registerPatientEmail').value = '';
        document.getElementById('registerPatientDob').value = '';
        document.getElementById('registerPatientGender').value = '';
        document.getElementById('registerPatientAddress').value = '';
        document.getElementById('registerDoctor').value = '';
        document.getElementById('registerScheduleSlot').value = '';
        document.getElementById('registerVisitType').value = 'New';
        document.getElementById('registerNote').value = '';
        
        // Reset filter values
        document.getElementById('filterDepartment').value = '';
        document.getElementById('filterDate').value = todayValue();
        document.getElementById('filterSession').value = 'all';
        document.getElementById('searchDoctorName').value = '';
        
        // Reset UI
        document.getElementById('selectedPatientCard').classList.add('d-none');

        // Reset search field
        lookupInput.value = '';

        // Deselect slots
        document.querySelectorAll('.slot-radio-btn').forEach(function(radio) {
            radio.checked = false;
        });
        document.querySelectorAll('.doctor-time-slot').forEach(function(slotLabel) {
            slotLabel.classList.remove('active');
        });
        document.querySelectorAll('.doctor-booking-card').forEach(function(c) {
            c.classList.remove('active');
        });
        
        // Reload doctor cards with reset filters
        loadDoctorCards();
    }

    // Set up filtering events
    document.getElementById('filterDepartment').addEventListener('change', loadDoctorCards);
    document.getElementById('filterDate').addEventListener('change', loadDoctorCards);
    document.getElementById('filterSession').addEventListener('change', loadDoctorCards);
    
    let searchTimeout;
    document.getElementById('searchDoctorName').addEventListener('input', function () {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(loadDoctorCards, 300);
    });

    form.addEventListener('submit', function (e) {
        e.preventDefault();
        submitBooking();
    });

    lookupButton.addEventListener('click', lookupPatient);
    lookupInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            lookupPatient();
        }
    });
    
    document.addEventListener('DOMContentLoaded', function () {
        // Set default filterDate to today
        const dateFilter = document.getElementById('filterDate');
        if (dateFilter && !dateFilter.value) {
            dateFilter.value = todayValue();
            dateFilter.min = todayValue();
        }

        loadDoctorCards();
        prefillFromQuery();
    });
})();
