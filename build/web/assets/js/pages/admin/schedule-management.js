const adminContextPath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
const adminCsrfToken = window.AdminConfig && window.AdminConfig.csrfToken ? window.AdminConfig.csrfToken : '';
const adminLoginUrl = window.AdminConfig && window.AdminConfig.loginUrl ? window.AdminConfig.loginUrl : adminContextPath + '/login.jsp';

// Transfer schedule AJAX support
            async function openTransferModal(scheduleId, doctorName, department, workDate, timeSlot) {
                const modalEl = document.getElementById('transferScheduleModal');
                const bsModal = new bootstrap.Modal(modalEl);
                document.getElementById('transferSelectedInfo').textContent = doctorName + ' - ' + department + ' - ' + workDate + ' - ' + timeSlot;
                const select = document.getElementById('transferTargetDoctor');
                select.innerHTML = '<option>\u0110ang t\u1EA3i...</option>';
                try {
                    const resp = await fetch(adminContextPath + '/admin?action=getTransferCandidates&scheduleId=' + encodeURIComponent(scheduleId), {
                        headers: { 'Accept': 'application/json' }
                    });
                    if (!resp.ok) throw new Error('HTTP ' + resp.status);
                    const data = await resp.json();
                    const currentId = data.currentDoctorId || null;
                    const items = data.items || [];
                    let options = '<option value="">-- Ch\u1ECDn b\u00E1c s\u0129 thay th\u1EBF --</option>';
                    for (const d of items) {
                        if (currentId && String(d.doctorId) === String(currentId)) continue; // skip current doctor
                        options += '<option value="' + d.doctorId + '">' + escapeHtml(d.fullName) + ' - ' + escapeHtml(d.department) + '</option>';
                    }
                    select.innerHTML = options;
                } catch (err) {
                    select.innerHTML = '<option value="">Kh\u00F4ng t\u1EA3i \u0111\u01B0\u1EE3c danh s\u00E1ch b\u00E1c s\u0129</option>';
                }
                // attach schedule id to confirm button
                document.getElementById('transferConfirmBtn').setAttribute('data-schedule-id', scheduleId);
                bsModal.show();
            }

            function escapeHtml(str) {
                const div = document.createElement('div');
                div.textContent = str || '';
                return div.innerHTML;
            }

            document.getElementById('transferConfirmBtn').addEventListener('click', async function () {
                const scheduleId = this.getAttribute('data-schedule-id');
                const targetDoctorId = document.getElementById('transferTargetDoctor').value;
                const alertBox = document.getElementById('transferAlert');
                alertBox.className = 'alert d-none';
                if (!targetDoctorId) {
                    alertBox.className = 'alert alert-danger';
                    alertBox.textContent = 'Vui l\u00F2ng ch\u1ECDn b\u00E1c s\u0129 nh\u1EADn ca.';
                    return;
                }
                try {
                    const params = new URLSearchParams();
                    params.set('action', 'transferSchedule');
                    params.set('scheduleId', scheduleId);
                    params.set('targetDoctorId', targetDoctorId);
                    params.set('csrfToken', adminCsrfToken);
                    const resp = await fetch(adminContextPath + '/admin', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                            'X-Requested-With': 'XMLHttpRequest'
                        },
                        body: params.toString()
                    });
                    let json = null;
                    try { json = await resp.json(); } catch (e) { /* ignore parse error */ }
                    if (json && json.success) {
                        alertBox.className = 'alert alert-success';
                        alertBox.textContent = json.message || '\u0110\u00E3 chuy\u1EC3n giao ca tr\u1EF1c';
                        // Update table row in-place if present
                        const row = document.querySelector('tr[data-schedule-id="' + scheduleId + '"]');
                        if (row) {
                            row.setAttribute('data-doctor-name', json.targetDoctorName || '');
                            const firstTd = row.querySelector('td');
                            if (firstTd) firstTd.textContent = json.targetDoctorName || firstTd.textContent;
                        }
                        // close modal after short delay
                        setTimeout(() => {
                            const bsModal = bootstrap.Modal.getInstance(document.getElementById('transferScheduleModal'));
                            if (bsModal) bsModal.hide();
                        }, 900);
                    } else {
                        const msg = (json && json.message) ? json.message : ('HTTP ' + resp.status);
                        alertBox.className = 'alert alert-danger';
                        alertBox.textContent = 'Kh\u00F4ng th\u1EC3 chuy\u1EC3n giao ca: ' + msg;
                    }
                } catch (err) {
                    alertBox.className = 'alert alert-danger';
                    alertBox.textContent = 'L\u1ED7i khi g\u1EEDi y\u00EAu c\u1EA7u: ' + err.message;
                }
            });

            // Expose helper to global for inline onclick
            window.openTransferModal = openTransferModal;

            // Helper: find row data and open modal
            function openTransferModalFromRow(el) {
                const tr = el.closest('tr');
                if (!tr) return;
                const scheduleId = tr.getAttribute('data-schedule-id');
                const doctorName = tr.getAttribute('data-doctor-name') || tr.querySelector('td')?.textContent || '';
                const department = tr.getAttribute('data-department') || '';
                const workDate = tr.querySelector('td:nth-child(3)')?.textContent.trim() || '';
                const timeSlot = tr.querySelector('td:nth-child(4)')?.textContent.trim() || '';
                openTransferModal(scheduleId, doctorName, department, workDate, timeSlot);
            }

// Edit schedule: open modal, populate with schedule data, save via AJAX
            async function openEditScheduleModal(scheduleId) {
                const modalHtml = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <form id="editScheduleForm">
                            <div class="modal-header">
                                <h5 class="modal-title">Ch\u1EC9nh s\u1EEDa ca tr\u1EF1c</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <div id="editScheduleAlert" class="alert d-none" role="alert"></div>
                                <input type="hidden" name="scheduleId" id="editScheduleId">
                                <input type="hidden" name="csrfToken" value="${adminCsrfToken}">
                                <div class="mb-3">
                                    <label class="form-label">B\u00E1c s\u0129</label>
                                    <select id="editDoctorId" name="doctorId" class="form-select" required></select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Khung gi\u1EDD</label>
                                    <select id="editTimeSlot" name="timeSlot" class="form-select" required>
                                        <option value="07:00-09:00">07:00-09:00</option>
                                        <option value="09:00-11:00">09:00-11:00</option>
                                        <option value="11:00-13:00">11:00-13:00</option>
                                        <option value="13:00-15:00">13:00-15:00</option>
                                        <option value="15:00-17:00">15:00-17:00</option>
                                        <option value="17:00-19:00">17:00-19:00</option>
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">S\u1ED1 b\u1EC7nh nh\u00E2n t\u1ED1i \u0111a</label>
                                    <input type="number" id="editMaxPatients" name="maxPatients" class="form-control" min="1" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Slot online</label>
                                    <input type="number" id="editOnlineQuota" name="onlineQuota" class="form-control" min="0">
                                    <div class="form-text">N\u1EBFu \u0111\u1EC3 tr\u1ED1ng, h\u1EC7 th\u1ED1ng s\u1EBD t\u1EF1 \u0111\u1EB7t theo c\u1EA5u h\u00ECnh an to\u00E0n m\u1EB7c \u0111\u1ECBnh.</div>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Tr\u1EA1ng th\u00E1i</label>
                                    <select id="editStatus" name="status" class="form-select">
                                        <option value="Available">Kh\u1EA3 d\u1EE5ng</option>
                                        <option value="Full">\u0110\u00E3 \u0111\u1EA7y</option>
                                        <option value="Cancelled">\u0110\u00E3 h\u1EE7y</option>
                                    </select>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button>
                                <button type="submit" class="btn btn-primary">L\u01B0u thay \u0111\u1ED5i</button>
                            </div>
                        </form>
                    </div>
                </div>`;

                // create modal container
                let container = document.getElementById('editScheduleModalContainer');
                if (!container) {
                    container = document.createElement('div');
                    container.id = 'editScheduleModalContainer';
                    container.className = 'modal fade';
                    container.tabIndex = -1;
                    document.body.appendChild(container);
                }
                container.innerHTML = modalHtml;
                const bsModal = new bootstrap.Modal(container);

                // fetch schedule details
                try {
                    const resp = await fetch(adminContextPath + '/admin?action=getSchedule&scheduleId=' + encodeURIComponent(scheduleId), { headers: { 'Accept': 'application/json' } });
                    if (!resp.ok) throw new Error('HTTP ' + resp.status);
                    const data = await resp.json();
                    if (!data || !data.schedule) throw new Error('Invalid response');

                    // populate form
                    document.getElementById('editScheduleId').value = data.schedule.scheduleId;
                    document.getElementById('editMaxPatients').value = data.schedule.maxPatients || '';
                    document.getElementById('editOnlineQuota').value = data.schedule.onlineQuota !== undefined && data.schedule.onlineQuota !== null ? data.schedule.onlineQuota : '';
                    document.getElementById('editTimeSlot').value = data.schedule.timeSlot || '';
                    document.getElementById('editStatus').value = data.schedule.status || 'Available';

                    // populate doctors list
                    const doctorSelect = document.getElementById('editDoctorId');
                    doctorSelect.innerHTML = '<option>\u0110ang t\u1EA3i...</option>';
                    const doctors = data.doctors || [];
                    let opts = '';
                    for (const d of doctors) {
                        opts += '<option value="' + d.doctorId + '"' + (d.doctorId == data.schedule.doctorId ? ' selected' : '') + '>' + escapeHtml(d.fullName) + ' - ' + escapeHtml(d.department) + '</option>';
                    }
                    doctorSelect.innerHTML = opts;

                } catch (err) {
                    const alert = document.getElementById('editScheduleAlert');
                    if (alert) {
                        alert.className = 'alert alert-danger';
                        alert.textContent = 'Kh\u00F4ng t\u1EA3i \u0111\u01B0\u1EE3c d\u1EEF li\u1EC7u ca tr\u1EF1c.';
                    }
                }

                // submit handler
                container.querySelector('#editScheduleForm').addEventListener('submit', async function (e) {
                    e.preventDefault();
                    const form = e.target;
                    const payload = {
                        scheduleId: form.scheduleId.value,
                        doctorId: form.doctorId.value,
                        timeSlot: form.timeSlot.value,
                        maxPatients: form.maxPatients.value,
                        onlineQuota: form.onlineQuota.value,
                        status: form.status.value,
                        csrfToken: form.csrfToken ? form.csrfToken.value : ''
                    };
                    try {
                        const params = new URLSearchParams();
                        params.set('action', 'updateSchedule');
                        Object.keys(payload).forEach(function (key) {
                            params.set(key, payload[key] == null ? '' : payload[key]);
                        });
                        const resp = await fetch(adminContextPath + '/admin?action=updateSchedule', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest', 'X-CSRF-Token': payload.csrfToken },
                            body: params.toString()
                        });
                        if (resp.ok) {
                            bsModal.hide();
                            // update row in table
                            const row = document.querySelector('tr[data-schedule-id="' + payload.scheduleId + '"]');
                            if (row) {
                                row.querySelector('td:nth-child(4)').textContent = payload.timeSlot;
                                row.setAttribute('data-max-patients', payload.maxPatients);
                                const resolvedOnlineQuota = payload.onlineQuota
                                    ? Number(payload.onlineQuota)
                                    : calculateDefaultOnlineQuota(Number(payload.maxPatients || 0));
                                const reservedSlots = Math.max(0, Number(payload.maxPatients || 0) - resolvedOnlineQuota);
                                row.setAttribute('data-online-quota', resolvedOnlineQuota);
                                row.setAttribute('data-reserved-slots', reservedSlots);
                                row.querySelector('td:nth-child(5) div').textContent = (row.dataset.bookedAppointments || 0) + ' / ' + payload.maxPatients;
                                const reserveText = row.querySelector('td:nth-child(5) small:nth-of-type(2)');
                                if (reserveText) reserveText.textContent = 'D\u1EF1 ph\u00F2ng: ' + reservedSlots + ' slot';
                                const onlineQuota = Number(row.dataset.onlineQuota || 0);
                                const onlineBooked = Number(row.dataset.onlineBookedCount || 0);
                                const quotaCell = row.querySelector('td:nth-child(6)');
                                if (quotaCell) {
                                    quotaCell.innerHTML = '<div class="fw-semibold">' + onlineBooked + ' / ' + onlineQuota + '</div>'
                                        + '<small class="text-muted d-block">Slot online</small>'
                                        + getOnlineQuotaBadge(onlineBooked, onlineQuota);
                                }
                                // update status badge
                                const statusCell = row.querySelector('td:nth-child(8)');
                                if (statusCell) statusCell.innerHTML = '<span class="badge text-bg-' + (payload.status === 'Available' ? 'success' : (payload.status === 'Full' ? 'danger' : 'dark')) + '">' + (payload.status === 'Available' ? '<i class="bi bi-check-circle"></i> Kh\u1EA3 d\u1EE5ng' : (payload.status === 'Full' ? '<i class="bi bi-exclamation-circle"></i> \u0110\u00E3 \u0111\u1EA7y' : '<i class="bi bi-x-circle"></i> \u0110\u00E3 h\u1EE7y')) + '</span>';
                            }
                            showTempAlert('C\u1EADp nh\u1EADt ca tr\u1EF1c th\u00E0nh c\u00F4ng.', 'success');
                        } else {
                            const alertEl = container.querySelector('#editScheduleAlert');
                            if (alertEl) {
                                alertEl.className = 'alert alert-danger';
                                alertEl.textContent = 'Khong the cap nhat ca truc.';
                            }
                        }
                    } catch (err) {
                        const alertEl = container.querySelector('#editScheduleAlert');
                        if (alertEl) {
                            alertEl.className = 'alert alert-danger';
                            alertEl.textContent = 'L\u1ED7i khi g\u1EEDi y\u00EAu c\u1EA7u c\u1EADp nh\u1EADt.';
                        }
                    }
                });

                bsModal.show();
            }

            function showTempAlert(message, type) {
                const div = document.createElement('div');
                div.className = 'alert alert-' + (type || 'info');
                div.textContent = message;
                document.querySelector('.admin-content-col').insertAdjacentElement('afterbegin', div);
                setTimeout(() => div.remove(), 3000);
            }

            function escapeHtml(s) {
                if (!s) return '';
                return String(s).replace(/[&<>"']/g, function (c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":"&#39;"}[c]; });
            }

const adminScheduleEndpoint = window.AdminConfig && window.AdminConfig.adminEndpoint ? window.AdminConfig.adminEndpoint : adminContextPath + '/admin';

                                                          function escapeHtmlForSchedule(value) {
                                                              const div = document.createElement('div');
                                                              div.textContent = value == null ? '' : String(value);
                                                              return div.innerHTML;
                                                          }

                                                          function getIsoDateOffset(dayOffset) {
                                                              const date = new Date();
                                                              date.setDate(date.getDate() + dayOffset);
                                                              return date.toISOString().slice(0, 10);
                                                          }

                                                          function formatVietnameseDate(isoDate) {
                                                              const parts = String(isoDate || '').split('-');
                                                              if (parts.length !== 3) {
                                                                  return isoDate || '';
                                                              }
                                                              return parts[2] + '/' + parts[1] + '/' + parts[0];
                                                          }


                                                          function countShiftTemplateLines() {
                                                              const textarea = document.querySelector('textarea[name="shiftTemplates"]');
                                                              return textarea ? textarea.value.split(/\r?\n/).filter(line => line.trim().includes('|')).length : 0;
                                                          }

                                                          const departmentMapping = {
                                                              'N\u1ED9i ti\u1EBFt - Ti\u1EC3u \u0111\u01B0\u1EDDng': 'Endocrinology',
                                                              'Endocrinology': 'Endocrinology',
                                                              'Tim m\u1EA1ch': 'Cardiology',
                                                              'Cardiology': 'Cardiology',
                                                              'Th\u1EADn h\u1ECDc': 'Nephrology',
                                                              'Nephrology': 'Nephrology',
                                                              'T\u1ED5ng qu\u00E1t': 'General',
                                                              'General': 'General'
                                                          };

                                                          function buildCustomShiftTemplate() {
                                                              const startTimeInput = document.getElementById('aiStartTime');
                                                              const endTimeInput = document.getElementById('aiEndTime');
                                                              const slotDurationInput = document.getElementById('aiSlotDuration');
                                                              const deptList = document.getElementById('aiDepartmentList');
                                                              
                                                              if (!startTimeInput || !endTimeInput || !slotDurationInput || !deptList) {
                                                                  return [];
                                                              }
                                                              
                                                              const startTime = startTimeInput.value;
                                                              const endTime = endTimeInput.value;
                                                              const slotMinutes = parseInt(slotDurationInput.value);
                                                              
                                                              if (!startTime || !endTime || isNaN(slotMinutes)) {
                                                                  return [];
                                                              }
                                                              
                                                              const departments = Array.from(deptList.querySelectorAll('.badge'))
                                                                  .map(badge => badge.getAttribute('data-dept'))
                                                                  .filter(dept => dept);
                                                              
                                                              if (departments.length === 0) {
                                                                  return [];
                                                              }
                                                              
                                                              const slots = [];
                                                              try {
                                                                  const [startHour, startMin] = startTime.split(':').map(Number);
                                                                  const [endHour, endMin] = endTime.split(':').map(Number);
                                                                  
                                                                  let currentMinutes = startHour * 60 + startMin;
                                                                  const endMinutes = endHour * 60 + endMin;
                                                                  let deptIndex = 0;
                                                                  
                                                                  while (currentMinutes + slotMinutes <= endMinutes) {
                                                                      const slotStart = Math.floor(currentMinutes / 60);
                                                                      const slotStartMin = currentMinutes % 60;
                                                                      const slotEnd = Math.floor((currentMinutes + slotMinutes) / 60);
                                                                      const slotEndMin = (currentMinutes + slotMinutes) % 60;
                                                                      
                                                                      const timeSlot = String(slotStart).padStart(2, '0') + ':' + String(slotStartMin).padStart(2, '0')
                                                                          + '-' + String(slotEnd).padStart(2, '0') + ':' + String(slotEndMin).padStart(2, '0');
                                                                      
                                                                      const dept = departments[deptIndex % departments.length];
                                                                      slots.push(timeSlot + '|' + dept);
                                                                      
                                                                      currentMinutes += slotMinutes;
                                                                      deptIndex++;
                                                                  }
                                                              } catch (e) {
                                                                  console.error('Error building custom shift template:', e);
                                                              }
                                                              
                                                              return slots;
                                                          }

                                                          function updateTemplatePreview() {
                                                              const textarea = document.querySelector('textarea[name="shiftTemplates"]');
                                                              if (textarea) {
                                                                  const slots = buildCustomShiftTemplate();
                                                                  textarea.value = slots.join('\n');
                                                              }
                                                              updateAiMaxSchedules();
                                                          }

                                                          function getSelectedWeekdays() {
                                                              return Array.from(document.querySelectorAll('input[name="selectedWeekdays"]:checked'))
                                                                      .map(input => Number(input.value));
                                                          }

                                                          function countSelectedTargetDates(startValue, endValue) {
                                                              if (!startValue || !endValue) {
                                                                  return 0;
                                                              }
                                                              const selected = new Set(getSelectedWeekdays());
                                                              const cursor = new Date(startValue + 'T00:00:00');
                                                              const end = new Date(endValue + 'T00:00:00');
                                                              let count = 0;
                                                              while (cursor <= end) {
                                                                  const jsDay = cursor.getDay();
                                                                  const isoDay = jsDay === 0 ? 7 : jsDay;
                                                                  if (selected.has(isoDay)) {
                                                                      count++;
                                                                  }
                                                                  cursor.setDate(cursor.getDate() + 1);
                                                              }
                                                              return count;
                                                          }

                                                          function getDoctorsPerShift() {
                                                              const input = document.getElementById('aiDoctorsPerShift');
                                                              const value = input ? Number(input.value) : 1;
                                                              return Number.isFinite(value) && value > 0 ? value : 1;
                                                          }

                                                          function updateAiMaxSchedules() {
                                                              const startDate = document.getElementById('aiStartDate');
                                                              const endDate = document.getElementById('aiEndDate');
                                                              const maxSchedules = document.getElementById('aiMaxSchedules');
                                                              const summary = document.getElementById('aiScheduleSummary');
                                                              if (!startDate || !endDate || !maxSchedules || !startDate.value || !endDate.value) {
                                                                  return;
                                                              }
                                                              const days = countSelectedTargetDates(startDate.value, endDate.value);
                                                              const shifts = countShiftTemplateLines();
                                                              const doctorsPerShift = getDoctorsPerShift();
                                                              const total = days * shifts * doctorsPerShift;
                                                              maxSchedules.value = total;
                                                              if (summary) {
                                                                  summary.textContent = 'H\u1EC7 th\u1ED1ng s\u1EBD t\u1EA1o ra: ' + days + ' ng\u00E0y x ' + shifts
                                                                          + ' ca x ' + doctorsPerShift + ' b\u00E1c s\u0129/ca = ' + total
                                                                          + ' slot l\u1ECBch tr\u1EF1c, sau \u0111\u00F3 Gemini \u0111i\u1EC1n b\u00E1c s\u0129.';
                                                              }
                                                          }
                                                          function setAiScheduleBusy(isBusy) {
                                                              const toolbarButton = document.getElementById('aiScheduleGeminiBtn');
                                                              const submitButton = document.getElementById('aiScheduleSubmitBtn');
                                                              const loadingBox = document.getElementById('aiScheduleLoading');
                                                              const detail = document.getElementById('aiScheduleLoadingDetail');
                                                              if (toolbarButton) {
                                                                  toolbarButton.disabled = isBusy;
                                                              }
                                                              if (submitButton) {
                                                                  submitButton.disabled = isBusy;
                                                                  submitButton.innerHTML = isBusy
                                                                          ? '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Gemini \u0111ang ph\u00E2n b\u1ED5...'
                                                                          : '<i class="fa-solid fa-rocket me-2"></i>Ti\u1EBFn h\u00E0nh ph\u00E2n b\u1ED5 b\u1EB1ng AI';
                                                              }
                                                              if (loadingBox) {
                                                                  loadingBox.classList.toggle('d-none', !isBusy);
                                                                  loadingBox.classList.toggle('d-flex', isBusy);
                                                              }
                                                              if (detail) {
                                                                  detail.textContent = isBusy ? '\u0110ang ghi l\u1ECBch tr\u1EF1c th\u1EADt v\u00E0o h\u1EC7 th\u1ED1ng...' : '';
                                                              }
                                                          }

                                                          function buildScheduleRow(schedule) {
                                                              const maxPatients = Number(schedule.maxPatients || 20);
                                                              const activeAppointments = Number(schedule.activeAppointments || 0);
                                                              const bookedAppointments = Number(schedule.bookedAppointments || schedule.bookedCount || activeAppointments || 0);
                                                              const loadPct = maxPatients > 0 ? Math.round((bookedAppointments * 100) / maxPatients) : 0;
                                                              const onlineQuota = schedule.onlineQuota !== undefined && schedule.onlineQuota !== null
                                                                      ? Number(schedule.onlineQuota)
                                                                      : calculateDefaultOnlineQuota(maxPatients);
                                                              const onlineBookedCount = Number(schedule.onlineBookedCount || 0);
                                                              const reservedSlots = schedule.reservedSlots !== undefined && schedule.reservedSlots !== null
                                                                      ? Number(schedule.reservedSlots)
                                                                      : Math.max(0, maxPatients - onlineQuota);

                                                              const departmentMap = {
                                                                  Endocrinology: 'N\u1ED9i ti\u1EBFt - Ti\u1EC3u \u0111\u01B0\u1EDDng',
                                                                  Cardiology: 'Tim m\u1EA1ch',
                                                                  Nephrology: 'Th\u1EADn h\u1ECDc',
                                                                  General: 'T\u1ED5ng qu\u00E1t'
                                                              };
                                                              const department = departmentMap[schedule.department] || (schedule.department || 'Ch\u01B0a x\u00E1c \u0111\u1ECBnh');

                                                              const isGemini = schedule.source === 'Gemini AI';
                                                              const sourceLabel = isGemini ? 'Gemini AI t\u1EA1o l\u1ECBch' : 'C\u00E2n b\u1EB1ng t\u1EA3i d\u1EF1 ph\u00F2ng';
                                                              const sourceIcon = isGemini ? 'fa-brain' : 'fa-scale-balanced';

                                                              const status = schedule.effectiveStatus || schedule.status || 'Available';

                                                              let statusBadge = '<span class="badge text-bg-success"><i class="bi bi-check-circle"></i> Kh\u1EA3 d\u1EE5ng</span>';

                                                              if (status === 'Expired') {
                                                                  statusBadge = '<span class="badge text-bg-secondary"><i class="bi bi-clock"></i> \u0110\u00E3 qua</span>';
                                                              } else if (status === 'Cancelled') {
                                                                  statusBadge = '<span class="badge text-bg-dark"><i class="bi bi-x-circle"></i> \u0110\u00E3 h\u1EE7y</span>';
                                                              } else if (status === 'Full') {
                                                                  statusBadge = '<span class="badge text-bg-danger"><i class="bi bi-exclamation-circle"></i> \u0110\u00E3 \u0111\u1EA7y</span>';
                                                              }

                                                              let actionColumn = '<span class="badge ai-schedule-badge" title="'
                                                                      + escapeHtmlForSchedule(schedule.reason || '')
                                                                      + '"><i class="fa-solid fa-database me-1"></i>\u0110\u00E3 l\u01B0u DB</span>';

                                                              if (status === 'Expired') {
                                                                  actionColumn = '<button type="button" class="btn btn-sm btn-outline-secondary" disabled>'
                                                                          + '<i class="bi bi-clock"></i> \u0110\u00E3 qua'
                                                                          + '</button>';
                                                              } else if (status === 'Cancelled') {
                                                                  actionColumn = '<button type="button" class="btn btn-sm btn-outline-dark" disabled>'
                                                                          + '<i class="bi bi-x-circle"></i> \u0110\u00E3 h\u1EE7y'
                                                                          + '</button>';
                                                              }

                                                              return '<tr class="ai-generated-row" data-schedule-id="' + (schedule.scheduleId || '') + '" data-doctor-name="' + escapeHtmlForSchedule(schedule.doctorName)
                                                                      + '" data-department="' + escapeHtmlForSchedule(schedule.department || '')
                                                                      + '" data-load-pct="' + loadPct + '" data-active-appointments="' + activeAppointments + '" data-booked-appointments="' + bookedAppointments
                                                                      + '" data-online-booked-count="' + onlineBookedCount + '" data-max-patients="' + maxPatients
                                                                      + '" data-online-quota="' + onlineQuota + '" data-reserved-slots="' + reservedSlots + '">'

                                                                      + '<td><span class="fw-semibold">' + escapeHtmlForSchedule(schedule.doctorName)
                                                                      + '</span><div class="small text-purple"><i class="fa-solid ' + sourceIcon + ' me-1"></i>'
                                                                      + sourceLabel + '</div></td>'

                                                                      + '<td>' + escapeHtmlForSchedule(department) + '</td>'

                                                                      + '<td>' + escapeHtmlForSchedule(formatVietnameseDate(schedule.workDate)) + '</td>'

                                                                      + '<td>' + escapeHtmlForSchedule(schedule.timeSlot) + '</td>'

                                                                      + '<td><div style="background-color: #f0f8f4; padding: 6px 10px; border-radius: 4px; font-weight: 500; text-align: center;">'
                                                                      + bookedAppointments + ' / ' + maxPatients + '</div>'
                                                                      + '<small class="text-muted d-block text-center mt-1">\u0110\u00E3 check-in/\u0111ang kh\u00E1m: ' + activeAppointments + '</small>'
                                                                      + '<small class="text-muted d-block text-center">D\u1EF1 ph\u00F2ng: ' + reservedSlots + ' slot</small></td>'

                                                                      + '<td class="text-center">'
                                                                      + '<div class="fw-semibold">' + onlineBookedCount + ' / ' + onlineQuota + '</div>'
                                                                      + '<small class="text-muted d-block">Slot online</small>'
                                                                      + getOnlineQuotaBadge(onlineBookedCount, onlineQuota)
                                                                      + '</td>'

                                                                      + '<td class="schedule-load-cell">'
                                                                      + '<div class="schedule-load-wrap" title="' + (loadPct >= 100 ? 'Qu\u00E1 t\u1EA3i' : (loadPct >= 80 ? 'C\u1EADn \u0111\u1EA7y' : 'B\u00ECnh th\u01B0\u1EDDng')) + '">'
                                                                      + '<div class="progress schedule-load-progress">'
                                                                      + '<div class="progress-bar ' + (loadPct >= 100 ? 'bg-danger' : (loadPct >= 80 ? 'bg-warning' : 'bg-success')) + '" role="progressbar" style="width: ' + (loadPct > 100 ? 100 : loadPct) + '%;" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' + loadPct + '"></div>'
                                                                      + '</div>'
                                                                      + '<span class="badge schedule-load-percent ' + (loadPct >= 100 ? 'text-bg-danger' : (loadPct >= 80 ? 'text-bg-warning' : 'text-bg-success')) + '">' + loadPct + '%</span>'
                                                                      + '<small class="text-muted schedule-load-state">' + (loadPct >= 100 ? 'Qu\u00E1 t\u1EA3i' : (loadPct >= 80 ? 'C\u1EADn \u0111\u1EA7y' : 'B\u00ECnh th\u01B0\u1EDDng')) + '</small>'
                                                                      + '</div>'
                                                                      + '</td>'

                                                                      + '<td>' + statusBadge + '</td>'

                                                                      + '<td>' + actionColumn + '</td>'

                                                                      + '</tr>';
                                                          }

                                                          function appendCreatedSchedules(schedules) {
                                                              const tbody = document.getElementById('scheduleTableBody');
                                                              if (!tbody || !Array.isArray(schedules) || schedules.length === 0) {
                                                                  return;
                                                              }
                                                              const emptyRow = tbody.querySelector('td[colspan="9"]');
                                                              if (emptyRow) {
                                                                  emptyRow.closest('tr').remove();
                                                              }
                                                              tbody.insertAdjacentHTML('afterbegin', schedules.map(buildScheduleRow).join(''));
                                                          }

                                                          function showAiScheduleMessage(message, isSuccess) {
                                                              const alertBox = document.getElementById('aiScheduleModalAlert');
                                                              if (!alertBox) {
                                                                  return;
                                                              }
                                                              alertBox.className = 'alert border-0 fw-semibold ' + (isSuccess ? 'alert-success' : 'alert-danger');
                                                              alertBox.innerHTML = '<i class="fa-solid ' + (isSuccess ? 'fa-circle-check' : 'fa-triangle-exclamation') + ' me-2"></i>' + escapeHtmlForSchedule(message);
                                                          }

                                                          document.addEventListener('DOMContentLoaded', function () {
                                                              const startDate = document.getElementById('aiStartDate');
                                                              const endDate = document.getElementById('aiEndDate');
                                                              const form = document.getElementById('aiScheduleForm');
                                                              const startTimeInput = document.getElementById('aiStartTime');
                                                              const endTimeInput = document.getElementById('aiEndTime');
                                                              const slotDurationInput = document.getElementById('aiSlotDuration');
                                                              const departmentInput = document.getElementById('aiDepartmentInput');
                                                              const addDepartmentBtn = document.getElementById('aiAddDepartmentBtn');
                                                              const departmentList = document.getElementById('aiDepartmentList');
                                                              
                                                              if (startDate && !startDate.value) {
                                                                  startDate.value = getIsoDateOffset(1);
                                                              }
                                                              if (endDate && !endDate.value) {
                                                                  endDate.value = getIsoDateOffset(7);
                                                              }
                                                              
                                                              // Handle department badge removal
                                                              if (departmentList) {
                                                                  departmentList.addEventListener('click', function(e) {
                                                                      if (e.target.classList.contains('badge')) {
                                                                          e.target.remove();
                                                                          updateTemplatePreview();
                                                                      }
                                                                  });
                                                              }
                                                              
                                                              // Handle add department button
                                                              if (addDepartmentBtn && departmentInput && departmentList) {
                                                                  addDepartmentBtn.addEventListener('click', function() {
                                                                      const dept = departmentInput.value.trim();
                                                                      if (!dept) return;
                                                                      
                                                                      const normalizedDept = Object.keys(departmentMapping).find(key => 
                                                                          key.toLowerCase() === dept.toLowerCase()
                                                                      ) || dept;
                                                                      
                                                                      const exists = Array.from(departmentList.querySelectorAll('.badge'))
                                                                          .some(badge => badge.getAttribute('data-dept') === normalizedDept);
                                                                      
                                                                      if (!exists) {
                                                                          const badge = document.createElement('span');
                                                                          badge.className = 'badge bg-info text-dark cursor-pointer';
                                                                          badge.setAttribute('data-dept', normalizedDept);
                                                                          badge.textContent = normalizedDept + ' \u2715';
                                                                          departmentList.appendChild(badge);
                                                                          departmentInput.value = '';
                                                                          updateTemplatePreview();
                                                                      }
                                                                  });
                                                                  
                                                                  departmentInput.addEventListener('keypress', function(e) {
                                                                      if (e.key === 'Enter') {
                                                                          e.preventDefault();
                                                                          addDepartmentBtn.click();
                                                                      }
                                                                  });
                                                              }
                                                              
                                                              // Setup update triggers
                                                              [startDate, endDate, document.getElementById('aiDoctorsPerShift'), 
                                                               startTimeInput, endTimeInput, slotDurationInput,
                                                               ...document.querySelectorAll('input[name="selectedWeekdays"]')].forEach(element => {
                                                                  if (element) {
                                                                      element.addEventListener('input', function() {
                                                                          if (element === startTimeInput || element === endTimeInput || element === slotDurationInput) {
                                                                              updateTemplatePreview();
                                                                          } else {
                                                                              updateAiMaxSchedules();
                                                                          }
                                                                      });
                                                                      element.addEventListener('change', function() {
                                                                          if (element === startTimeInput || element === endTimeInput || element === slotDurationInput) {
                                                                              updateTemplatePreview();
                                                                          } else {
                                                                              updateAiMaxSchedules();
                                                                          }
                                                                      });
                                                                  }
                                                              });
                                                              
                                                              updateTemplatePreview();
                                                              if (!form) {
                                                                  return;
                                                              }

                                                              form.addEventListener('submit', async function (event) {
                                                                  event.preventDefault();
                                                                  
                                                                  // Update hidden fields from custom design inputs
                                                                  if (startTimeInput && endTimeInput && slotDurationInput) {
                                                                      document.querySelector('input[name="startTime"]').value = startTimeInput.value || '07:00';
                                                                      document.querySelector('input[name="endTime"]').value = endTimeInput.value || '19:00';
                                                                      document.querySelector('input[name="slotMinutes"]').value = slotDurationInput.value || '60';
                                                                  }
                                                                  
                                                                  const formData = new FormData(form);
                                                                  const params = new URLSearchParams();
                                                                  params.set('action', 'aiCreateSchedules');
                                                                  formData.forEach((value, key) => params.append(key, value));

                                                                  if (getSelectedWeekdays().length === 0) {
                                                                      showAiScheduleMessage('Vui l\u00F2ng ch\u1ECDn \u00EDt nh\u1EA5t m\u1ED9t ng\u00E0y \u00E1p d\u1EE5ng trong tu\u1EA7n.', false);
                                                                      return;
                                                                  }
                                                                  if (Number(document.getElementById('aiMaxSchedules').value) <= 0) {
                                                                      showAiScheduleMessage('Kho\u1EA3ng ng\u00E0y \u0111\u00E3 ch\u1ECDn kh\u00F4ng c\u00F3 ng\u00E0y \u00E1p d\u1EE5ng ph\u00F9 h\u1EE3p.', false);
                                                                      return;
                                                                  }

                                                                  setAiScheduleBusy(true);
                                                                  try {
                                                                      const response = await fetch(adminScheduleEndpoint, {
                                                                          method: 'POST',
                                                                          headers: {
                                                                              'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                                                                              'Accept': 'application/json'
                                                                          },
                                                                          body: params.toString()
                                                                      });
                                                                      if (!response.ok) {
                                                                          throw new Error('HTTP ' + response.status);
                                                                      }
                                                                      const data = await response.json();
                                                                      showAiScheduleMessage(data.message || '\u0110\u00E3 x\u1EED l\u00FD y\u00EAu c\u1EA7u l\u1EADp l\u1ECBch.', data.success);
                                                                      if (data.success) {
                                                                          appendCreatedSchedules(data.items || []);
                                                                          window.setTimeout(() => {
                                                                              const modalEl = document.getElementById('aiScheduleModal');
                                                                              const instance = bootstrap.Modal.getInstance(modalEl);
                                                                              if (instance) {
                                                                                  instance.hide();
                                                                              }
                                                                          }, 900);
                                                                      }
                                                                  } catch (error) {
                                                                      showAiScheduleMessage('Kh\u00F4ng th\u1EC3 t\u1EA1o l\u1ECBch b\u1EB1ng Gemini: ' + error.message, false);
                                                                  } finally {
                                                                      setAiScheduleBusy(false);
                                                                  }
                                                              });
                                                          });

// Event listener b\u1EA5p v\u00E0o h\u00E0ng schedule \u0111\u1EC3 xem b\u1EC7nh nh\u00E2n
            document.addEventListener('click', function(e) {
                const row = e.target.closest('tbody tr');
                if (!row) return;
                
                // B\u1ECF qua n\u1EBFu b\u1EA5p v\u00E0o button ho\u1EB7c form elements
                if (e.target.closest('button') || e.target.closest('form')) return;
                
                // L\u1EA5y schedule ID t\u1EEB data attribute
                const scheduleId = row.dataset.scheduleId;
                const doctorName = row.dataset.doctorName || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh';
                const timeSlot = row.querySelector('td:nth-child(4)')?.textContent || '';
                const workDate = row.querySelector('td:nth-child(3)')?.textContent || '';
                
                if (!scheduleId) return;
                
                // C\u1EADp nh\u1EADt ti\u00EAu \u0111\u1EC1 modal
                const titleEl = document.getElementById('appointmentsModalTitle');
                if (titleEl) {
                    titleEl.textContent = doctorName + ' (' + workDate + ' ' + timeSlot + ')';
                }
                
                // M\u1EDF modal
                const modal = new bootstrap.Modal(document.getElementById('scheduleAppointmentsModal'));
                modal.show();
                
                // T\u1EA3i danh s\u00E1ch b\u1EC7nh nh\u00E2n
                fetch(adminContextPath + '/admin?action=scheduleAppointments&scheduleId=' + scheduleId)
                    .then(async response => {
                        const ct = response.headers.get('content-type') || '';
                        if (response.status === 401) {
                            // Session expired for AJAX request - try to show message then redirect
                            if (ct.toLowerCase().indexOf('application/json') !== -1) {
                                const err = await response.json().catch(() => null);
                                const msg = (err && err.message) ? err.message : 'Phi\u00EAn l\u00E0m vi\u1EC7c \u0111\u00E3 h\u1EBFt, vui l\u00F2ng \u0111\u0103ng nh\u1EADp l\u1EA1i.';
                                const tbody = document.getElementById('appointmentsTableBody');
                                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>' + escapeHtmlForSchedule(msg) + '</td></tr>';
                            } else {
                                const tbody = document.getElementById('appointmentsTableBody');
                                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>Phi\u00EAn l\u00E0m vi\u1EC7c c\u00F3 th\u1EC3 \u0111\u00E3 h\u1EBFt. B\u1EA1n s\u1EBD \u0111\u01B0\u1EE3c chuy\u1EC3n \u0111\u1EBFn \u0111\u0103ng nh\u1EADp...</td></tr>';
                            }
                            setTimeout(() => { window.location.href = adminLoginUrl; }, 1200);
                            return Promise.reject(new Error('HTTP 401'));
                        }
                        if (!response.ok) throw new Error('HTTP ' + response.status);
                        if (ct.toLowerCase().indexOf('application/json') === -1) {
                            // Non-JSON response (likely HTML error or login page)
                            const txt = await response.text();
                            const snippet = txt.replace(/\s+/g, ' ').substring(0, 400);
                            const tbody = document.getElementById('appointmentsTableBody');
                            // Detect common signs of login page or server error
                            const low = snippet.toLowerCase();
                            const looksLikeLogin = low.indexOf('\u0111\u0103ng nh\u1EADp') !== -1 || low.indexOf('login') !== -1 || low.indexOf('j_username') !== -1 || low.indexOf('<form') !== -1;
                            if (looksLikeLogin) {
                                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-warning py-3"><i class="bi bi-exclamation-triangle me-2"></i>Phi\u00EAn l\u00E0m vi\u1EC7c c\u00F3 th\u1EC3 \u0111\u00E3 h\u1EBFt. B\u1EA1n s\u1EBD \u0111\u01B0\u1EE3c chuy\u1EC3n \u0111\u1EBFn trang \u0111\u0103ng nh\u1EADp...</td></tr>';
                                // Redirect to login after short delay
                                setTimeout(() => {
                                    window.location.href = adminLoginUrl;
                                }, 1200);
                                // Stop further processing
                                return Promise.reject(new Error('Session expired - redirecting to login'));
                            }
                            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-danger py-3"><i class="bi bi-exclamation-circle me-2"></i>Server tr\u1EA3 v\u1EC1 n\u1ED9i dung kh\u00F4ng h\u1EE3p l\u1EC7: ' + escapeHtmlForSchedule(snippet) + '</td></tr>';
                            return Promise.reject(new Error('Server returned non-JSON response'));
                        }
                        return response.json();
                    })
                    .then(data => {
                        const tbody = document.getElementById('appointmentsTableBody');
                        if (!data.items || data.items.length === 0) {
                            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3">Ch\u01B0a c\u00F3 b\u1EC7nh nh\u00E2n n\u00E0o \u0111\u1EB7t l\u1ECBch</td></tr>';
                            return;
                        }

                        tbody.innerHTML = data.items.map(item => {
                            const statusBadge = getStatusBadge(item.status);
                            return '<tr>'
                                + '<td><strong>' + escapeHtmlForSchedule(item.appointmentTime || '') + '</strong></td>'
                                + '<td>' + escapeHtmlForSchedule(item.patientName || '') + '</td>'
                                + '<td>' + getBookingSourceBadge(item.bookingSource) + '</td>'
                                + '<td>' + statusBadge + '</td>'
                                + '</tr>';
                        }).join('');
                    })
                    .catch(error => {
                        const tbody = document.getElementById('appointmentsTableBody');
                        const msg = error && error.message ? error.message : 'L\u1ED7i khi t\u1EA3i d\u1EEF li\u1EC7u';
                        tbody.innerHTML = '<tr><td colspan="4" class="text-center text-danger py-3"><i class="bi bi-exclamation-circle me-2"></i>' + escapeHtmlForSchedule(msg) + '</td></tr>';
                    });
            }, false);
            
            function getStatusBadge(status) {
                const statusMap = {
                    'Waiting': '<span class="badge text-bg-warning"><i class="bi bi-calendar-check me-1"></i>\u0110\u00E3 \u0111\u1EB7t l\u1ECBch</span>',
                    'Checked_In': '<span class="badge text-bg-primary"><i class="bi bi-person-check me-1"></i>\u0110\u00E3 check-in</span>',
                    'In_Progress': '<span class="badge text-bg-info"><i class="bi bi-play-circle me-1"></i>\u0110ang kh\u00E1m</span>',
                    'Completed': '<span class="badge text-bg-success"><i class="bi bi-check-circle me-1"></i>Ho\u00E0n t\u1EA5t</span>',
                    'Absent': '<span class="badge text-bg-secondary"><i class="bi bi-x-circle me-1"></i>Kh\u00F4ng c\u00F3 m\u1EB7t</span>',
                    'Cancelled': '<span class="badge text-bg-danger"><i class="bi bi-trash me-1"></i>\u0110\u00E3 h\u1EE7y</span>'
                };
                return statusMap[status] || '<span class="badge text-bg-secondary">' + (status || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh') + '</span>';
            }

            function calculateDefaultOnlineQuota(maxPatients) {
                if (maxPatients <= 1) {
                    return Math.max(0, maxPatients);
                }
                let quota = Math.ceil(maxPatients * 0.6);
                if (quota >= maxPatients) {
                    quota = maxPatients - 1;
                }
                return Math.max(1, quota);
            }

            function getOnlineQuotaBadge(onlineBooked, onlineQuota) {
                if (onlineBooked > onlineQuota) {
                    return '<span class="badge text-bg-danger mt-1">V\u01B0\u1EE3t quota online</span>';
                }
                if (onlineBooked >= onlineQuota) {
                    return '<span class="badge text-bg-warning mt-1">H\u1EBFt slot online</span>';
                }
                return '<span class="badge text-bg-success mt-1">C\u00F2n slot online</span>';
            }

            function getBookingSourceBadge(source) {
                const normalized = (source || '').toString().trim();
                const sourceMap = {
                    'Online': '<span class="badge text-bg-success"><i class="bi bi-globe2 me-1"></i>Online</span>',
                    'Receptionist': '<span class="badge text-bg-primary"><i class="bi bi-person-badge me-1"></i>L\u1EC5 t\u00E2n</span>',
                    'Admin': '<span class="badge text-bg-dark"><i class="bi bi-shield-lock me-1"></i>Admin</span>',
                    'Walk_In': '<span class="badge text-bg-warning text-dark"><i class="bi bi-door-open me-1"></i>Walk-in</span>',
                    'Emergency_Routing': '<span class="badge text-bg-danger"><i class="bi bi-lightning-charge me-1"></i>\u0110i\u1EC1u ph\u1ED1i</span>'
                };
                if (!normalized) {
                    return '<span class="badge text-bg-secondary">Kh\u00F4ng r\u00F5</span>';
                }
                return sourceMap[normalized] || '<span class="badge text-bg-secondary">' + escapeHtmlForSchedule(normalized) + '</span>';
            }
            
            // H\u00E0m escapeHtml \u0111\u1EC3 tr\u00E1nh XSS
            function escapeHtmlForSchedule(text) {
                if (!text) return '';
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }
