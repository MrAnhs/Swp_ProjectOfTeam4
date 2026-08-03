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
                            dateTitle.textContent = `ngày ${parts[2]}/${parts[1]}/${parts[0]}`;
                        } else {
                            dateTitle.textContent = `ngày ${selectedDate}`;
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
                badge.textContent = `${patients.length} bệnh nhân`;
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
                            dateLabel = `ngày ${parts[2]}/${parts[1]}/${parts[0]}`;
                        } else {
                            dateLabel = `ngày ${selectedDate}`;
                        }
                    }
                }
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">Không có bệnh nhân nào tái khám ${dateLabel}.</td>
                    </tr>
                `;
                return;
            }

            patients.forEach(p => {
                const tr = document.createElement('tr');
                
                // Tự động điền trước các thông tin bệnh nhân để truyền qua URL sang trang Đăng ký khám
                const prefillParams = new URLSearchParams({
                    patientName: p.patientName || '',
                    patientPhone: p.patientPhone || '',
                    patientEmail: p.patientEmail || '',
                    patientDob: p.patientDob || '',
                    patientGender: p.patientGender || '',
                    patientAddress: p.patientAddress || '',
                    visitType: 'Revisit', // Đánh dấu là loại hình Tái khám
                    revisitAppointmentId: p.revisitAppointmentId || ''
                }).toString();
                
                // URL đích dẫn tới trang đăng ký lịch khám mới kèm theo dữ liệu prefill
                const registerUrl = `${window.ReceptionistConfig.contextPath}/receptionist/appointments/new?${prefillParams}`;

                let actionHtml = '';
                // Kiểm tra xem bệnh nhân này đã được tạo lịch khám trong ngày hôm đó chưa
                if (p.activeAppointmentId) {
                    // Nếu đã đăng ký khám rồi thì hiển thị nhãn xanh lá "Đã đăng ký"
                    actionHtml = `<span class="badge bg-success-subtle text-success border border-success-subtle py-2 px-3 d-inline-flex align-items-center" style="font-size: 0.85rem; font-weight: 600;">
                                      <i class="bi bi-check-circle-fill me-1"></i>Đã đăng ký
                                  </span>`;
                } else {
                    // Nếu chưa thì hiển thị Nút màu xanh ngọc "Đăng ký khám" để chuyển qua trang xếp lịch
                    actionHtml = `<a href="${registerUrl}" class="btn btn-sm btn-primary" title="Đăng ký khám">
                                      <i class="bi bi-calendar-plus me-1"></i>Đăng ký khám
                                  </a>`;
                }

                tr.innerHTML = `
                    <td class="ps-3 fw-medium text-dark">${utils.escapeHtml(p.patientName)}</td>
                    <td>${utils.escapeHtml(p.patientPhone)}</td>
                    <td>${utils.escapeHtml(p.patientEmail || 'Chưa cập nhật')}</td>
                    <td><span class="badge bg-warning-subtle text-dark border border-warning-subtle" style="font-size: 0.85rem;">${utils.escapeHtml(p.revisitDate)}</span></td>
                    <td>${utils.escapeHtml(p.doctorName)}</td>
                    <td class="text-end pe-3">
                        <a href="tel:${p.patientPhone}" class="btn btn-sm btn-outline-success me-1" title="Gời điện nhắc nhở">
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
                    <td colspan="6" class="text-center text-danger py-4">Lỗi tải danh sách: ${utils.escapeHtml(error.message)}</td>
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
