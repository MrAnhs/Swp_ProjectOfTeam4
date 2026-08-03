(function () {
    const utils = window.ReceptionistUtils;
    const result = document.getElementById('registrationResult');
    const lookupInput = document.getElementById('patientLookupKeyword');
    const lookupButton = document.getElementById('patientLookupBtn');
    const patientFieldsContainer = document.getElementById('patientFieldsContainer');

    const filterDepartment = document.getElementById('filterDepartment');
    const filterDate = document.getElementById('filterDate');
    const filterSession = document.getElementById('filterSession');
    const searchDoctorName = document.getElementById('searchDoctorName');

    const doctorCardsList = document.getElementById('doctorCardsList');
    const doctorCountElem = document.getElementById('bookingDoctorCount');
    const filterDescElem = document.getElementById('bookingFilterDescription');

    let allActiveDoctors = [];
    let currentPatientRevisitDates = [];

    function showResult(html, type) {
        result.className = 'result-card my-3 alert alert-' + (type || 'info');
        result.innerHTML = html;
        result.classList.remove('d-none');
        try {
            result.scrollIntoView({ behavior: 'smooth', block: 'center' });
        } catch (e) {}
    }

    function validVietnamesePhone(phone) {
        return /^(0|\+84)(3|5|7|8|9)\d{8}$/.test(phone);
    }

    function isSlotPassed(workDateStr, timeSlotStr) {
        if (!workDateStr) return false;
        const now = new Date();
        const todayStr = now.getFullYear() + '-' +
            String(now.getMonth() + 1).padStart(2, '0') + '-' +
            String(now.getDate()).padStart(2, '0');

        if (workDateStr < todayStr) return true;

        if (workDateStr === todayStr && timeSlotStr) {
            const parts = timeSlotStr.split('-');
            let timeToCompare = parts.length > 1 ? parts[1].trim() : parts[0].trim();
            const timeMatch = timeToCompare.match(/(\d{1,2}):(\d{2})/);
            if (timeMatch) {
                const slotEndHour = parseInt(timeMatch[1], 10);
                const slotEndMin = parseInt(timeMatch[2], 10);
                const currentHour = now.getHours();
                const currentMin = now.getMinutes();

                if (currentHour > slotEndHour || (currentHour === slotEndHour && currentMin >= slotEndMin)) {
                    return true;
                }
            }
        }
        return false;
    }

    function setDefaultDate() {
        if (filterDate) {
            const today = new Date().toISOString().split('T')[0];
            filterDate.min = today;
            if (!filterDate.value || filterDate.value < today) {
                filterDate.value = today;
            }
        }
    }

    function formatDeptName(dept) {
        if (!dept || !dept.trim()) return 'Chưa cập nhật';
        let d = dept.trim();
        while (d.toLowerCase().startsWith('khoa ')) {
            d = d.substring(5).trim();
        }
        return 'Khoa ' + d;
    }

    function normalizeGenderForSelect(val) {
        if (!val) return 'Male';
        const s = String(val).trim().toLowerCase();
        if (s === 'female' || s === 'nỿ' || s === 'nu' || s === 'f') return 'Female';
        if (s === 'other' || s === 'khác' || s === 'khac' || s === 'o') return 'Other';
        return 'Male';
    }

    function formatDateDisplay(dateStr) {
        if (!dateStr) return '';
        try {
            const d = new Date(dateStr + 'T00:00:00');
            const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
            const dayName = days[d.getDay()];
            const dayNum = String(d.getDate()).padStart(2, '0');
            const monthNum = String(d.getMonth() + 1).padStart(2, '0');
            const yearNum = d.getFullYear();
            return dayName + ', ' + dayNum + '/' + monthNum + '/' + yearNum;
        } catch (e) {
            return dateStr;
        }
    }

    function isMorningSlot(timeSlot) {
        if (!timeSlot) return true;
        const lower = timeSlot.toLowerCase();
        if (lower.includes('sáng') || lower.includes('morning')) return true;
        if (lower.includes('chiều') || lower.includes('afternoon')) return false;
        const match = lower.match(/^(\d{1,2}):/);
        if (match) {
            const hour = parseInt(match[1], 10);
            return hour < 12;
        }
        return true;
    }

    function fillPatient(patient) {
        const normGender = normalizeGenderForSelect(patient.gender);
        const values = {
            registerPatientName: patient.fullName || '',
            registerPatientPhone: patient.phone || '',
            registerPatientEmail: patient.email || '',
            registerPatientDob: patient.dateOfBirth || '',
            registerPatientGender: normGender,
            registerPatientAddress: patient.address || ''
        };
        Object.entries(values).forEach(function (entry) {
            const input = document.getElementById(entry[0]);
            if (input) input.value = entry[1];
        });
    }

    function clearPatientFields() {
        fillPatient({});
        currentPatientRevisitDates = [];
        if (patientFieldsContainer) {
            patientFieldsContainer.classList.add('d-none');
        }
    }

    async function lookupPatient() {
        const keyword = lookupInput.value.trim();
        if (!keyword) {
            showResult('Vui lòng nhập số điện thoại hoặc họ tên bệnh nhân.', 'warning');
            if (patientFieldsContainer) patientFieldsContainer.classList.add('d-none');
            return;
        }
        lookupButton.disabled = true;
        try {
            const data = await utils.requestJson(utils.apiBase() + '/patients/search?keyword=' + encodeURIComponent(keyword));
            if (data && data.patient && data.patient.fullName) {
                fillPatient(data.patient);
                currentPatientRevisitDates = data.revisitDates || [];

                if (patientFieldsContainer) {
                    patientFieldsContainer.classList.remove('d-none');
                }

                let revisitBadge = '';
                if (currentPatientRevisitDates.length > 0) {
                    const datesStr = currentPatientRevisitDates.map(function (d) { return formatDateDisplay(d); }).join(', ');
                    revisitBadge = ' <span class="badge text-bg-info ms-1">Lịch tái khám: ' + utils.escapeHtml(datesStr) + '</span>';
                }

                showResult('Đã tìm thấy bệnh nhân <strong>' + utils.escapeHtml(data.patient.fullName) + '</strong>.' + revisitBadge + ' Vui lòng chọn ca khám bác sĩ bên dưới.', 'success');
            } else {
                clearPatientFields();
                showResult('Số điện thoại này chưa được đăng ký trên hệ thống.', 'danger');
            }
        } catch (error) {
            clearPatientFields();
            showResult('Số điện thoại này chưa được đăng ký trên hệ thống.', 'danger');
        } finally {
            lookupButton.disabled = false;
        }
    }

    function populateDepartmentOptions(doctors) {
        if (!filterDepartment) return;
        const currentSel = filterDepartment.value;
        const departments = new Set();
        doctors.forEach(function (doc) {
            if (doc.department && doc.department.trim()) {
                let d = doc.department.trim();
                while (d.toLowerCase().startsWith('khoa ')) d = d.substring(5).trim();
                departments.add(d);
            }
        });
        filterDepartment.innerHTML = '<option value="">Tất cả khoa khám</option>';
        departments.forEach(function (dep) {
            const opt = document.createElement('option');
            opt.value = dep;
            opt.textContent = 'Khoa ' + dep;
            if (dep === currentSel) opt.selected = true;
            filterDepartment.appendChild(opt);
        });
    }

    function createSlotButton(doctor, slot, card) {
        const label = document.createElement('label');
        label.className = 'doctor-time-slot';

        const radio = document.createElement('input');
        radio.type = 'radio';
        radio.name = 'selected_schedule_' + doctor.doctorId;
        radio.value = slot.scheduleId;

        const time = document.createElement('strong');
        time.className = 'doctor-time-range';
        time.textContent = slot.timeSlot || 'Ca khám';

        const avail = document.createElement('small');
        avail.className = 'doctor-time-availability';
        avail.textContent = 'Còn ' + (slot.available != null ? slot.available : 0) + ' chỗ';

        const room = document.createElement('small');
        room.className = 'doctor-time-room';
        room.textContent = 'Phòng: Chưa phân phòng';

        radio.addEventListener('change', function () {
            card.dataset.selectedScheduleId = slot.scheduleId;
            card.querySelectorAll('.doctor-time-slot').forEach(function (s) {
                s.classList.toggle('active', s.contains(radio));
            });
        });

        label.append(radio, time, avail, room);
        return label;
    }

    function createSessionGroup(title, iconClass, doctor, slots, card) {
        const group = document.createElement('div');
        group.className = 'doctor-session-group';

        const heading = document.createElement('h4');
        const icon = document.createElement('i');
        icon.className = iconClass + ' me-1';
        const text = document.createElement('span');
        text.textContent = title;
        heading.append(icon, text);

        const slotsDiv = document.createElement('div');
        slotsDiv.className = 'doctor-time-slots';
        slots.forEach(function (slot) {
            slotsDiv.appendChild(createSlotButton(doctor, slot, card));
        });

        group.append(heading, slotsDiv);
        return group;
    }

    function createDoctorCard(doctor, dateStr, schedules) {
        const card = document.createElement('article');
        card.className = 'doctor-booking-card mb-4';
        card.dataset.doctorId = doctor.doctorId;

        // Card Header
        const header = document.createElement('div');
        header.className = 'doctor-booking-card__header';

        const identity = document.createElement('div');
        identity.className = 'doctor-booking-card__identity';

        const avatar = document.createElement('span');
        avatar.className = 'doctor-avatar doctor-avatar--outline';
        avatar.innerHTML = '<i class="bi bi-person-fill"></i>';

        const info = document.createElement('div');
        const name = document.createElement('h3');
        name.textContent = doctor.fullName || 'Bác sĩ';
        const dept = document.createElement('p');
        dept.textContent = 'Chuyên khoa: ' + formatDeptName(doctor.department);
        info.append(name, dept);
        identity.append(avatar, info);

        const dateBadge = document.createElement('span');
        dateBadge.className = 'doctor-date-badge';
        dateBadge.innerHTML = '<i class="bi bi-calendar-check me-1"></i>';
        const dateText = document.createElement('span');
        dateText.textContent = formatDateDisplay(dateStr);
        dateBadge.append(dateText);

        header.append(identity, dateBadge);

        // Schedules Area
        const scheduleArea = document.createElement('div');
        scheduleArea.className = 'doctor-booking-card__schedules';

        const schedHeading = document.createElement('div');
        schedHeading.className = 'doctor-schedule-heading';
        const headingTitle = document.createElement('strong');
        headingTitle.textContent = 'Giờ khám còn trống';
        const headingHint = document.createElement('span');
        headingHint.textContent = 'Chọn một khung giờ để đặt lịch';
        schedHeading.append(headingTitle, headingHint);
        scheduleArea.append(schedHeading);

        const morningSlots = schedules.filter(function (s) { return isMorningSlot(s.timeSlot); });
        const afternoonSlots = schedules.filter(function (s) { return !isMorningSlot(s.timeSlot); });

        if (morningSlots.length > 0) {
            scheduleArea.append(createSessionGroup('Buổi sáng', 'bi bi-sun', doctor, morningSlots, card));
        }
        if (afternoonSlots.length > 0) {
            scheduleArea.append(createSessionGroup('Buổi chiều', 'bi bi-sunset', doctor, afternoonSlots, card));
        }

        // Card Footer with Action Controls (Image 3)
        const footer = document.createElement('div');
        footer.className = 'doctor-booking-card__footer d-flex align-items-center justify-content-between flex-wrap gap-2 pt-3 border-top mt-3';

        const actionControls = document.createElement('div');
        actionControls.className = 'd-flex align-items-center gap-2 flex-wrap';

        const visitTypeLabel = document.createElement('label');
        visitTypeLabel.className = 'form-label mb-0 fw-semibold text-muted small';
        visitTypeLabel.textContent = 'Loại đăng ký:';

        const visitTypeSelect = document.createElement('select');
        visitTypeSelect.className = 'form-select form-select-sm doctor-visit-type';
        visitTypeSelect.style.width = '130px';
        visitTypeSelect.innerHTML = '<option value="New">Khám mới</option><option value="Revisit">Tái khám</option>';

        actionControls.append(visitTypeLabel, visitTypeSelect);

        const bookBtn = document.createElement('button');
        bookBtn.type = 'button';
        bookBtn.className = 'btn btn-success doctor-book-btn';
        bookBtn.innerHTML = 'Xác nhận đặt lịch <i class="bi bi-arrow-right ms-1"></i>';

        bookBtn.addEventListener('click', function () {
            bookAppointmentForDoctor(doctor, card, visitTypeSelect.value, bookBtn);
        });

        footer.append(actionControls, bookBtn);
        card.append(header, scheduleArea, footer);
        return card;
    }

    async function bookAppointmentForDoctor(doctor, card, visitType, bookBtn) {
        if (!patientFieldsContainer || patientFieldsContainer.classList.contains('d-none')) {
            showResult('Vui lòng tìm kiếm số điện thoại bệnh nhân trước khi đặt lịch.', 'warning');
            return;
        }

        const patientName = document.getElementById('registerPatientName').value.trim();
        const patientPhone = document.getElementById('registerPatientPhone').value.trim();
        const patientEmail = document.getElementById('registerPatientEmail').value.trim();
        const patientDob = document.getElementById('registerPatientDob').value.trim();
        const patientGender = document.getElementById('registerPatientGender').value;
        const patientAddress = document.getElementById('registerPatientAddress').value.trim();

        if (!patientPhone || !patientName) {
            showResult('Vui lòng nhập đầy đủ thông tin bệnh nhân.', 'warning');
            return;
        }

        const selectedScheduleId = card.dataset.selectedScheduleId;
        if (!selectedScheduleId) {
            showResult('Vui lòng chọn khung giờ khám còn trống của bác sĩ ' + utils.escapeHtml(doctor.fullName) + '.', 'warning');
            return;
        }

        // Revisit Client-side Validation
        if (visitType === 'Revisit') {
            const selectedDate = filterDate ? filterDate.value : new Date().toISOString().split('T')[0];
            const hasRevisitOnDate = currentPatientRevisitDates.includes(selectedDate);
            if (!hasRevisitOnDate) {
                showResult('Bệnh nhân không có lịch tái khám vào ngày ' + formatDateDisplay(selectedDate) + '. Vui lòng chọn đăng ký Khám mới.', 'danger');
                return;
            }
        }

        bookBtn.disabled = true;
        const body = new URLSearchParams();
        body.set('patientName', patientName);
        body.set('patientPhone', patientPhone);
        body.set('patientEmail', patientEmail);
        body.set('patientDob', patientDob);
        body.set('patientGender', patientGender);
        body.set('patientAddress', patientAddress);
        body.set('visitType', visitType);
        body.set('doctorId', doctor.doctorId);
        body.set('scheduleId', selectedScheduleId);

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
                '<h3 class="h5 mb-2">Đăng ký khám thành công</h3>'
                + '<p class="mb-1">Bệnh nhân: <strong>' + utils.escapeHtml(patientName) + '</strong> (' + utils.escapeHtml(patientPhone) + ')</p>'
                + '<p class="mb-1">Bác sĩ: <strong>' + utils.escapeHtml(doctor.fullName) + '</strong></p>'
                + '<p class="mb-1">Thời gian khám: <strong>' + utils.escapeHtml(data.appointmentTime) + '</strong></p>'
                + '<p class="mb-0">Số thứ tự: <strong>Số ' + utils.escapeHtml(data.queueNumber) + '</strong></p>',
                'success'
            );

            clearPatientFields();
            if (lookupInput) lookupInput.value = '';
            await loadFilteredDoctorCards();
        } catch (error) {
            showResult(error.message, 'danger');
        } finally {
            bookBtn.disabled = false;
        }
    }

    async function loadFilteredDoctorCards() {
        const selectedDep = filterDepartment ? filterDepartment.value.toLowerCase().trim() : '';
        const nameQuery = searchDoctorName ? searchDoctorName.value.toLowerCase().trim() : '';
        const selectedDate = filterDate ? filterDate.value : new Date().toISOString().split('T')[0];
        const selectedSession = filterSession ? filterSession.value : 'all';

        doctorCardsList.innerHTML = '<div class="text-center py-4 col-12 text-muted"><div class="spinner-border text-primary mb-2" role="status"></div> <div>Đang tải danh sách bác sĩ...</div></div>';

        // 1. Filter candidate doctors by department and name search
        const candidateDocs = allActiveDoctors.filter(function (doc) {
            let docDep = (doc.department || '').toLowerCase().trim();
            while (docDep.startsWith('khoa ')) docDep = docDep.substring(5).trim();
            const docName = (doc.fullName || '').toLowerCase().trim();
            const matchDep = !selectedDep || docDep === selectedDep;
            const matchName = !nameQuery || docName.includes(nameQuery);
            return matchDep && matchName;
        });

        // 2. Concurrently fetch & filter available schedules for candidate doctors
        const doctorSchedulesResults = await Promise.all(candidateDocs.map(async function (doctor) {
            try {
                const data = await utils.requestJson(utils.apiBase() + '/schedules?doctorId=' + encodeURIComponent(doctor.doctorId));
                let slots = data.slots || [];

                // Filter slots by date and exclude passed time slots
                if (selectedDate) {
                    slots = slots.filter(function (s) {
                        const dateMatch = !s.workDate || s.workDate === selectedDate;
                        const passed = isSlotPassed(s.workDate || selectedDate, s.timeSlot);
                        return dateMatch && !passed;
                    });
                }

                // Filter slots by session
                if (selectedSession !== 'all') {
                    slots = slots.filter(function (s) {
                        const isMorning = isMorningSlot(s.timeSlot);
                        return selectedSession === 'morning' ? isMorning : !isMorning;
                    });
                }

                return { doctor: doctor, slots: slots };
            } catch (err) {
                return { doctor: doctor, slots: [] };
            }
        }));

        // 3. Filter out doctors who have NO available slots for the selected date & session
        const validDoctorCards = doctorSchedulesResults.filter(function (item) {
            return item.slots && item.slots.length > 0;
        });

        // 4. Update Count Badge & Description accurately
        const count = validDoctorCards.length;
        doctorCountElem.innerHTML = '<i class="bi bi-people me-1"></i> Tìm thấy ' + count + ' bác sĩ có ca khám phù hợp';

        let desc = selectedDep ? formatDeptName(selectedDep) : 'Tất cả khoa';
        desc += ', lịch còn trống ngày ' + formatDateDisplay(selectedDate) + ' theo bộ lọc đã chọn.';
        filterDescElem.textContent = desc;

        // 5. Render Doctor Cards or Empty State Banner
        doctorCardsList.replaceChildren();

        if (count === 0) {
            doctorCardsList.innerHTML = '<div class="text-center py-5 text-muted"><i class="bi bi-calendar-x fs-1 d-block mb-2"></i><strong>Không tìm thấy bác sĩ có ca khám phù hợp</strong><p class="small text-muted">Không có bác sĩ nào có ca khám còn trống ngày ' + formatDateDisplay(selectedDate) + ' theo bộ lọc. Bạn hãy thử chọn ngày khác hoặc đổi khoa khám.</p></div>';
            return;
        }

        validDoctorCards.forEach(function (item) {
            const card = createDoctorCard(item.doctor, selectedDate, item.slots);
            doctorCardsList.appendChild(card);
        });
    }

    async function initDoctors() {
        try {
            const data = await utils.requestJson(utils.apiBase() + '/doctors');
            allActiveDoctors = data.doctors || [];
            populateDepartmentOptions(allActiveDoctors);
            await loadFilteredDoctorCards();
        } catch (err) {
            doctorCardsList.innerHTML = '<div class="text-danger text-center py-4">Không thể tải danh sách bác sĩ: ' + utils.escapeHtml(err.message) + '</div>';
        }
    }

    if (filterDepartment) filterDepartment.addEventListener('change', loadFilteredDoctorCards);
    if (searchDoctorName) searchDoctorName.addEventListener('input', loadFilteredDoctorCards);
    if (filterDate) {
        filterDate.addEventListener('change', () => {
            const today = new Date().toISOString().split('T')[0];
            if (filterDate.value && filterDate.value < today) {
                alert('Ngày khám không được chọn ngày đã qua!');
                filterDate.value = today;
            }
            loadFilteredDoctorCards();
        });
    }
    if (filterSession) filterSession.addEventListener('change', loadFilteredDoctorCards);

    lookupButton.addEventListener('click', lookupPatient);
    lookupInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            lookupPatient();
        }
    });

    document.addEventListener('DOMContentLoaded', function () {
        setDefaultDate();
        initDoctors();
    });
})();
