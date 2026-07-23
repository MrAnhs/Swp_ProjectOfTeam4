(function () {
    const utils = window.ReceptionistUtils;

    async function loadStats() {
        try {
            const data = await utils.requestJson(utils.apiBase() + '/invoices/stats');
            const pending = document.getElementById('pendingInvoiceCount');
            const paid = document.getElementById('paidInvoiceCount');
            if (pending) pending.textContent = data.pendingCount || 0;
            if (paid) paid.textContent = data.paidCount || 0;
        } catch (error) {
            console.error(error);
        }
    }

    async function loadRevisitPatients() {
        const tableBody = document.getElementById('revisitTableBody');
        const badge = document.getElementById('revisitCountBadge');
        const datePicker = document.getElementById('revisitDatePicker');
        const dateTitle = document.getElementById('revisitDateTitle');
        if (!tableBody) return;

        try {
            const selectedDate = datePicker ? datePicker.value : '';
            
            // Cập nhật nhãn tiêu đề ngày (nếu có phần tử trong DOM)
            if (dateTitle) {
                if (!selectedDate) {
                    dateTitle.textContent = 'hôm nay';
                } else {
                    const today = new Date();
                    const yyyy = today.getFullYear();
                    const mm = String(today.getMonth() + 1).padStart(2, '0');
                    const dd = String(today.getDate()).padStart(2, '0');
                    const todayStr = `${yyyy}-${mm}-${dd}`;
                    
                    if (selectedDate === todayStr) {
                        dateTitle.textContent = 'hôm nay';
                    } else {
                        const parts = selectedDate.split('-');
                        if (parts.length === 3) {
                            dateTitle.textContent = `ng\u00E0y ${parts[2]}/${parts[1]}/${parts[0]}`;
                        } else {
                            dateTitle.textContent = `ng\u00E0y ${selectedDate}`;
                        }
                    }
                }
            }

            const url = utils.apiBase() + '/patients/revisit' + (selectedDate ? `?date=${selectedDate}` : '');
            console.log("DEBUG: Gọi API URL =", url);
            const data = await utils.requestJson(url);
            console.log("DEBUG: Dữ liệu API trả về =", data);
            const patients = data.patients || [];
            
            if (badge) {
                badge.textContent = `${patients.length} b\u1EC7nh nh\u00E2n`;
            }

            tableBody.innerHTML = '';
            if (patients.length === 0) {
                let dateLabel = 'hôm nay';
                if (selectedDate) {
                    const today = new Date();
                    const yyyy = today.getFullYear();
                    const mm = String(today.getMonth() + 1).padStart(2, '0');
                    const dd = String(today.getDate()).padStart(2, '0');
                    const todayStr = `${yyyy}-${mm}-${dd}`;
                    
                    if (selectedDate !== todayStr) {
                        const parts = selectedDate.split('-');
                        if (parts.length === 3) {
                            dateLabel = `ng\u00E0y ${parts[2]}/${parts[1]}/${parts[0]}`;
                        } else {
                            dateLabel = `ng\u00E0y ${selectedDate}`;
                        }
                    }
                }
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 b\u1EC7nh nh\u00E2n n\u00E0o t\u00E1i kh\u00E1m ${dateLabel}.</td>
                    </tr>
                `;
                return;
            }

            patients.forEach(p => {
                const tr = document.createElement('tr');
                
                // Prefill query link to receptionist register appointment
                const prefillParams = new URLSearchParams({
                    patientName: p.patientName || '',
                    patientPhone: p.patientPhone || '',
                    patientEmail: p.patientEmail || '',
                    patientDob: p.patientDob || '',
                    patientGender: p.patientGender || '',
                    patientAddress: p.patientAddress || '',
                    visitType: 'Revisit',
                    revisitAppointmentId: p.revisitAppointmentId || ''
                }).toString();
                
                const registerUrl = `${window.ReceptionistConfig.contextPath}/receptionist/appointments/new?${prefillParams}`;

                let actionHtml = '';
                if (p.activeAppointmentId) {
                    actionHtml = `<span class="badge bg-success-subtle text-success border border-success-subtle py-2 px-3 d-inline-flex align-items-center" style="font-size: 0.85rem; font-weight: 600;">
                                      <i class="bi bi-check-circle-fill me-1"></i>\u0110\u00e3 \u0111\u0103ng k\u00fd
                                  </span>`;
                } else {
                    actionHtml = `<a href="${registerUrl}" class="btn btn-sm btn-primary" title="\u0110\u0103ng k\u00FD kh\u00E1m">
                                      <i class="bi bi-calendar-plus me-1"></i>\u0110\u0103ng k\u00FD kh\u00E1m
                                  </a>`;
                }

                tr.innerHTML = `
                    <td class="ps-3 fw-medium text-dark">${utils.escapeHtml(p.patientName)}</td>
                    <td>${utils.escapeHtml(p.patientPhone)}</td>
                    <td>${utils.escapeHtml(p.patientEmail || 'Ch\u01B0a c\u1EADp nh\u1EADt')}</td>
                    <td><span class="badge bg-warning-subtle text-dark border border-warning-subtle" style="font-size: 0.85rem;">${utils.escapeHtml(p.revisitDate)}</span></td>
                    <td>${utils.escapeHtml(p.doctorName)}</td>
                    <td class="text-end pe-3">
                        <a href="tel:${p.patientPhone}" class="btn btn-sm btn-outline-success me-1" title="G\u1EDDi \u0111i\u1EC7n nh\u1EAFc nh\u1EDF">
                            <i class="bi bi-telephone"></i>
                        </a>
                        ${actionHtml}
                    </td>
                `;
                tableBody.appendChild(tr);
            });
        } catch (error) {
            console.error(error);
            tableBody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-danger py-4">L\u1ED7i t\u1EA3i danh s\u00E1ch: ${utils.escapeHtml(error.message)}</td>
                </tr>
            `;
        }
    }

    document.addEventListener('DOMContentLoaded', () => {
        loadStats();
        
        // Thiết lập giá trị mặc định cho ô chọn ngày là ngày hôm nay
        const datePicker = document.getElementById('revisitDatePicker');
        if (datePicker) {
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth() + 1).padStart(2, '0');
            const dd = String(today.getDate()).padStart(2, '0');
            datePicker.value = `${yyyy}-${mm}-${dd}`;
            
            datePicker.addEventListener('change', () => {
                loadRevisitPatients();
            });
        }
        
        loadRevisitPatients();
    });
})();
