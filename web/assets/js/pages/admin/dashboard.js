const dashboardBasePath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
                                                    const csrfToken = window.AdminConfig && window.AdminConfig.csrfToken ? window.AdminConfig.csrfToken : '';
                                                    const todayPatientFlowData = window.AdminConfig && Array.isArray(window.AdminConfig.todayPatientFlowData) ? window.AdminConfig.todayPatientFlowData : [];
                                                    const todayRevenueByServiceData = window.AdminConfig && Array.isArray(window.AdminConfig.todayRevenueByServiceData) ? window.AdminConfig.todayRevenueByServiceData : [];
                                                    const todayStatusDistributionData = window.AdminConfig && Array.isArray(window.AdminConfig.todayStatusDistributionData) ? window.AdminConfig.todayStatusDistributionData : [];
                                                    const dailyAvailableBeds = Number(document.getElementById('dailyAvailableBeds') ? document.getElementById('dailyAvailableBeds').textContent : 15) || 15;
                                                    let dashboardQuickModalInstance = null;
                                                    let dashboardInvoiceDetailModalInstance = null;
                                                    let doctorQueueModalInstance = null;
                                                    let todayAppointmentsModalInstance = null;
                                                    let todayWaitingModalInstance = null;
                                                    let bedAvailabilityModalInstance = null;
                                                    let currentAccountFilter = 'all';
                                                    function revealKpiCards() {
                                                        const cards = document.querySelectorAll('.kpi-card');
                                                        cards.forEach((card, index) => {
                                                            window.setTimeout(() => {
                                                                card.classList.add('is-visible');
                                                            }, index * 90);
                                                        });
                                                    }

                                                    // Call revealKpiCards immediately if DOM is ready, or on DOMContentLoaded
                                                    if (document.readyState === 'loading') {
                                                        document.addEventListener('DOMContentLoaded', revealKpiCards);
                                                    } else {
                                                        // DOM is already ready, call immediately with a small delay to ensure rendering
                                                        window.setTimeout(revealKpiCards, 100);
                                                    }

                                                    function formatCurrency(value) {
                                                        return Number(value || 0).toLocaleString('vi-VN', {
                                                            minimumFractionDigits: 0,
                                                            maximumFractionDigits: 2
                                                        }) + ' VNĐ';
                                                    }

                                                    function escapeHtml(text) {
                                                        const div = document.createElement('div');
                                                        div.textContent = text == null ? '' : String(text);
                                                        return div.innerHTML;
                                                    }

                                                    function translateRole(role) {
                                                        const roleMap = {
                                                            'Patient': 'Bệnh nhân',
                                                            'Doctor': 'Bác sĩ',
                                                            'Receptionist': 'Lễ tân',
                                                            'Admin': 'Quản trị viên'
                                                        };
                                                        return roleMap[role] || role;
                                                    }

                                                    function translateAccountStatus(status) {
                                                        const statusMap = {
                                                            'Active': 'Hoạt động',
                                                            'Locked': 'Đã khóa'
                                                        };
                                                        return statusMap[status] || status;
                                                    }

                                                    function translateServiceStatus(status) {
                                                        const statusMap = {
                                                            'Active': 'Hoạt động',
                                                            'Inactive': 'Ngừng hoạt động'
                                                        };
                                                        return statusMap[status] || status;
                                                    }

                                                    async function fetchQuickData(action, params) {
                                                        const query = new URLSearchParams(params || {});
                                                        query.set('action', action);
                                                        const response = await fetch(dashboardBasePath + '/admin?' + query.toString(), {
                                                            headers: {'Accept': 'application/json'}
                                                        });
                                                        if (!response.ok) {
                                                            throw new Error('HTTP ' + response.status);
                                                        }
                                                        return response.json();
                                                    }

                                                    async function fetchServletJson(servletPath, params) {
                                                        const query = new URLSearchParams(params || {});
                                                        const response = await fetch(dashboardBasePath + servletPath + '?' + query.toString(), {
                                                            headers: {'Accept': 'application/json'}
                                                        });
                                                        if (!response.ok) {
                                                            throw new Error('HTTP ' + response.status);
                                                        }
                                                        return response.json();
                                                    }

                                                    async function postQuickAction(action, payload) {
                                                        const body = new URLSearchParams(payload || {});
                                                        body.set('action', action);
                                                        body.set('csrfToken', csrfToken);
                                                        const response = await fetch(dashboardBasePath + '/admin', {
                                                            method: 'POST',
                                                            headers: {
                                                                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                                                                'Accept': 'application/json'
                                                            },
                                                            body: body.toString()
                                                        });
                                                        if (!response.ok) {
                                                            throw new Error('HTTP ' + response.status);
                                                        }
                                                        return response.json();
                                                    }

                                                    function ensureQuickModals() {
                                                        if (!dashboardQuickModalInstance) {
                                                            dashboardQuickModalInstance = new bootstrap.Modal(document.getElementById('dashboardQuickModal'));
                                                        }
                                                        if (!dashboardInvoiceDetailModalInstance) {
                                                            dashboardInvoiceDetailModalInstance = new bootstrap.Modal(document.getElementById('dashboardInvoiceDetailModal'));
                                                        }
                                                        if (!doctorQueueModalInstance) {
                                                            doctorQueueModalInstance = new bootstrap.Modal(document.getElementById('doctorQueueModal'));
                                                        }
                                                        if (!todayAppointmentsModalInstance) {
                                                            todayAppointmentsModalInstance = new bootstrap.Modal(document.getElementById('todayAppointmentsModal'));
                                                        }
                                                        if (!todayWaitingModalInstance) {
                                                            todayWaitingModalInstance = new bootstrap.Modal(document.getElementById('todayWaitingModal'));
                                                        }
                                                        if (!bedAvailabilityModalInstance) {
                                                            bedAvailabilityModalInstance = new bootstrap.Modal(document.getElementById('bedAvailabilityModal'));
                                                        }
                                                    }

                                                    function getStatusMeta(status) {
                                                        const rawStatus = String(status || '').trim();
                                                        switch (rawStatus) {
                                                            case 'Waiting':
                                                                return {
                                                                    label: 'Chờ đợi',
                                                                    className: 'badge bg-warning text-dark status-badge-soft'
                                                                };
                                                            case 'Checked_In':
                                                                return {
                                                                    label: 'Đã check-in',
                                                                    className: 'badge bg-primary text-white status-badge-soft'
                                                                };
                                                            case 'In_Progress':
                                                                return {
                                                                    label: 'Đang khám',
                                                                    className: 'badge bg-info text-white status-badge-soft'
                                                                };
                                                            case 'Completed':
                                                                return {
                                                                    label: 'Hoàn tất',
                                                                    className: 'badge bg-success text-white status-badge-soft'
                                                                };
                                                            case 'Absent':
                                                                return {
                                                                    label: 'Không đến',
                                                                    className: 'badge bg-secondary text-white status-badge-soft'
                                                                };
                                                            default:
                                                                return {
                                                                    label: rawStatus || 'Không xác định',
                                                                    className: 'badge bg-secondary text-white status-badge-soft'
                                                                };
                                                        }
                                                    }

                                                    function renderTodayAppointmentsRows(items) {
                                                        const tbody = document.getElementById('todayAppointmentsTableBody');
                                                        if (!tbody) {
                                                            return;
                                                        }

                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Không có lịch hẹn hôm nay.</td></tr>';
                                                            return;
                                                        }

                                                        let html = '';
                                                        items.forEach((item, index) => {
                                                            const statusMeta = getStatusMeta(item.status);
                                                            html += '<tr>'
                                                                    + '<td>' + (index + 1) + '</td>'
                                                                    + '<td>' + escapeHtml(item.patientName || 'N/A') + '</td>'
                                                                    + '<td>' + escapeHtml(item.doctorName || 'Chưa phân công') + '</td>'
                                                                    + '<td>' + escapeHtml(item.appointmentDate || '') + '</td>'
                                                                    + '<td>' + escapeHtml(item.appointmentTime || '--:--') + '</td>'
                                                                    + '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>'
                                                                    + '</tr>';
                                                        });
                                                        tbody.innerHTML = html;
                                                    }

                                                    function renderTodayWaitingRows(items) {
                                                        const tbody = document.getElementById('todayWaitingTableBody');
                                                        if (!tbody) {
                                                            return;
                                                        }

                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Không có bệnh nhân đã check-in trong ngày.</td></tr>';
                                                            return;
                                                        }

                                                        let html = '';
                                                        items.forEach((item, index) => {
                                                            const waitMinutes = Number(item.waitingMinutes || 0);
                                                            const statusMeta = getStatusMeta(item.status || 'Waiting');
                                                            html += '<tr>'
                                                                    + '<td>' + (index + 1) + '</td>'
                                                                    + '<td>' + escapeHtml(item.patientName || 'N/A') + '</td>'
                                                                    + '<td>' + escapeHtml(item.department || 'Chưa xác định') + '</td>'
                                                                    + '<td>' + escapeHtml(item.appointmentTime || '--:--') + '</td>'
                                                                    + '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>'
                                                                    + '<td>' + waitMinutes + ' phút</td>'
                                                                    + '</tr>';
                                                        });
                                                        tbody.innerHTML = html;
                                                    }

                                                    async function openTodayAppointmentsModal() {
                                                        ensureQuickModals();
                                                        const tbody = document.getElementById('todayAppointmentsTableBody');
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Đang tải dữ liệu...</td></tr>';
                                                        }
                                                        todayAppointmentsModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getTodayAppointments');
                                                            renderTodayAppointmentsRows(data.items || []);
                                                        } catch (error) {
                                                            if (tbody) {
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Không thể tải danh sách ca khám hôm nay.</td></tr>';
                                                            }
                                                        }
                                                    }

                                                    async function openTodayWaitingModal() {
                                                        ensureQuickModals();
                                                        const tbody = document.getElementById('todayWaitingTableBody');
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Đang tải dữ liệu...</td></tr>';
                                                        }
                                                        todayWaitingModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getTodayWaiting');
                                                            renderTodayWaitingRows(data.items || []);
                                                        } catch (error) {
                                                            if (tbody) {
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Không thể tải danh sách bệnh nhân đã check-in.</td></tr>';
                                                            }
                                                        }
                                                    }

                                                    function openDoctorShiftModal() {
                                                        ensureQuickModals();
                                                        bedAvailabilityModalInstance.show();
                                                    }

                                                    function renderDoctorQueueRows(items) {
                                                        const tbody = document.getElementById('doctorQueueTableBody');
                                                        if (!tbody) {
                                                            return;
                                                        }

                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Không có bệnh nhân đã check-in cho bác sĩ này hôm nay.</td></tr>';
                                                            return;
                                                        }

                                                        let html = '';
                                                        items.forEach((item, index) => {
                                                            const statusMeta = getStatusMeta(item.status || 'Waiting');
                                                            const appointmentId = escapeHtml(item.appointmentId);
                                                            html += '<tr>';
                                                            html += '<td>' + (index + 1) + '</td>';
                                                            html += '<td>' + appointmentId + '</td>';
                                                            html += '<td>' + escapeHtml(item.patientName || 'N/A') + '</td>';
                                                            html += '<td>' + escapeHtml(item.appointmentTime || '--:--') + '</td>';
                                                            html += '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>';
                                                            html += '<td class="text-end"><a class="btn btn-sm btn-warning text-dark" href="' + dashboardBasePath + '/admin?action=exception&appointmentId=' + appointmentId + '">Điều phối ca này</a></td>';
                                                            html += '</tr>';
                                                        });
                                                        tbody.innerHTML = html;
                                                    }

                                                    async function openDoctorQueueModal(doctorId, doctorName, department) {
                                                        ensureQuickModals();
                                                        const title = document.getElementById('doctorQueueModalLabel');
                                                        const tbody = document.getElementById('doctorQueueTableBody');
                                                        if (title) {
                                                            title.textContent = 'Chi tiết hàng đợi - Bác sĩ: ' + (doctorName || '') + ' (' + (department || '') + ')';
                                                        }
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Đang tải dữ liệu...</td></tr>';
                                                        }

                                                        doctorQueueModalInstance.show();
                                                        try {
                                                            const response = await fetch(dashboardBasePath + '/admin?action=getDoctorQueueDetail&doctorId=' + encodeURIComponent(doctorId), {
                                                                headers: {'Accept': 'application/json'}
                                                            });
                                                            if (!response.ok) {
                                                                throw new Error('HTTP ' + response.status);
                                                            }
                                                            const data = await response.json();
                                                            renderDoctorQueueRows(data.items || []);
                                                        } catch (error) {
                                                            if (tbody) {
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Không thể tải danh sách bệnh nhân đã check-in.</td></tr>';
                                                            }
                                                        }
                                                    }

                                                    function setQuickModalContent(title, bodyHtml, footerHtml) {
                                                        document.getElementById('dashboardQuickModalLabel').textContent = title;
                                                        document.getElementById('dashboardQuickModalBody').innerHTML = bodyHtml;
                                                        document.getElementById('dashboardQuickModalFooter').innerHTML = footerHtml || '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>';
                                                    }

                                                    function renderAccountQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">Không có tài khoản phù hợp</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                const isLocked = String(item.status).toLowerCase() === 'locked';
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.fullName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.email) + '</td>';
                                                                rows += '<td>' + escapeHtml(translateRole(item.role)) + '</td>';
                                                                rows += '<td><span class="badge ' + (isLocked ? 'bg-danger' : 'bg-success') + '">' + escapeHtml(translateAccountStatus(item.status)) + '</span></td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm ' + (isLocked ? 'btn-success' : 'btn-outline-danger') + ' quick-toggle-account quick-action-btn" data-account-id="' + item.accountId + '" data-next-status="' + (isLocked ? 'active' : 'locked') + '">' + (isLocked ? 'Mở khóa' : 'Khóa') + '</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Quản lý nhanh tài khoản nhân sự',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>Họ tên</th><th>Email</th><th>Vai trò</th><th>Trạng thái</th><th class="text-end">Thao tác</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=listUsers">Mở quản lý tài khoản</a>'
                                                                );
                                                        if (data.summary) {
                                                            document.getElementById('kpiTotalAccounts').textContent = data.summary.totalAccounts;
                                                            document.getElementById('kpiActiveAccounts').textContent = data.summary.activeAccounts;
                                                            document.getElementById('kpiLockedAccounts').textContent = data.summary.lockedAccounts;
                                                        }
                                                    }

                                                    function renderLockedAccountModalRows(items) {
                                                        let rows = '';
                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            rows = '<tr><td colspan="4" class="text-center text-muted py-4">Không có tài khoản phù hợp</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                const status = String(item.status || 'locked');
                                                                const isLocked = status.toLowerCase() === 'locked';
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.fullName || item.full_name || 'N/A') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.email || 'N/A') + '</td>';
                                                                rows += '<td>' + escapeHtml(translateRole(item.role || 'N/A')) + '</td>';
                                                                rows += '<td><span class="badge ' + (isLocked ? 'bg-danger' : 'bg-success') + '">' + escapeHtml(translateAccountStatus(status)) + '</span></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh sách tài khoản đã khóa',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>Họ tên</th><th>Email</th><th>Vai trò</th><th>Trạng thái</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=listUsers">Mở quản lý tài khoản</a>'
                                                                );
                                                    }

                                                    function renderRevenueQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">Hôm nay chưa có hóa đơn thu tiền</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.invoiceId) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.payment_time || '--/--/---- --:--') + '</td>';
                                                                rows += '<td class="text-end fw-semibold">' + formatCurrency(item.finalAmount) + '</td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm btn-outline-primary quick-view-invoice" data-invoice-id="' + escapeHtml(item.invoiceId) + '">Xem chi tiết</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Hóa đơn thu tiền gần nhất trong ngày',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>Mã HD</th><th>Tên BN</th><th>Thời gian</th><th class="text-end">Thực thu</th><th class="text-end">Thao tác</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">Mở Báo cáo chuyên sâu</a>'
                                                                );
                                                    }

                                                    function renderServiceQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">Không có dịch vụ để hiển thị</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                const isActive = String(item.status).toLowerCase() === 'active';
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.serviceName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.serviceType) + '</td>';
                                                                rows += '<td class="text-end">' + formatCurrency(item.price) + '</td>';
                                                                rows += '<td><span class="badge ' + (isActive ? 'bg-success' : 'bg-secondary') + '">' + escapeHtml(translateServiceStatus(item.status)) + '</span></td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm ' + (isActive ? 'btn-outline-secondary' : 'btn-success') + ' quick-toggle-service quick-action-btn" data-service-id="' + item.serviceId + '" data-next-status="' + (isActive ? 'Inactive' : 'Active') + '">' + (isActive ? 'Ngưng dùng' : 'Kích hoạt') + '</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh sách dịch vụ y tế hiện tại',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>Dịch vụ</th><th>Loại</th><th class="text-end">Đơn giá</th><th>Trạng thái</th><th class="text-end">Thao tác</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=manageServices">Mở quản lý dịch vụ</a>'
                                                                );
                                                        if (data.summary) {
                                                            document.getElementById('kpiTotalServices').textContent = data.summary.activeServices;
                                                        }
                                                    }

                                                    function renderAppointmentQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="6" class="text-center text-muted py-4">Chưa có lượt khám hoàn tất</td></tr>';
                                                        } else {
                                                            items.forEach((item, index) => {
                                                                rows += '<tr>';
                                                                rows += '<td>' + (index + 1) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.doctorName || 'Chưa phân công') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentDate || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentTime || '') + '</td>';
                                                                rows += '<td><span class="badge bg-success">Đã hoàn tất</span></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh sách lượt khám hoàn tất',
                                                                '<div class="table-responsive">'
                                                                + '<table class="table table-sm table-hover quick-modal-table align-middle">'
                                                                + '<thead class="table-light">'
                                                                + '<tr>'
                                                                + '<th>STT</th>'
                                                                + '<th>BỆNH NHÂN</th>'
                                                                + '<th>BÁC SĨ</th>'
                                                                + '<th>NGÀY KHÁM</th>'
                                                                + '<th>GIỜ HẸN</th>'
                                                                + '<th>TRẠNG THÁI</th>'
                                                                + '</tr>'
                                                                + '</thead>'
                                                                + '<tbody>' + rows + '</tbody>'
                                                                + '</table>'
                                                                + '</div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>'
                                                                + '<a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">Mở Báo cáo chuyên sâu</a>'
                                                                );
                                                    }

                                                    function renderCompletedAppointmentsModalRows(items) {
                                                        let rows = '';
                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            rows = '<tr><td colspan="6" class="text-center text-muted py-4">Không có lượt khám hoàn tất</td></tr>';
                                                        } else {
                                                            items.forEach((item, index) => {
                                                                const statusMeta = getStatusMeta(item.status || 'Completed');
                                                                rows += '<tr>';
                                                                rows += '<td>' + (index + 1) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName || item.patient_name || 'N/A') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.doctorName || item.doctor_name || 'Chưa phân công') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentDate || item.appointment_date || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentTime || item.appointment_time || '--:--') + '</td>';
                                                                rows += '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh sách lượt khám hoàn tất',
                                                                '<div class="table-responsive">'
                                                                + '<table class="table table-sm table-hover quick-modal-table">'
                                                                + '<thead class="table-light">'
                                                                + '<tr>'
                                                                + '<th>STT</th>'
                                                                + '<th>Bệnh nhân</th>'
                                                                + '<th>Bác sĩ</th>'
                                                                + '<th>Ngày khám</th>'
                                                                + '<th>Giờ hẹn</th>'
                                                                + '<th>Trạng thái</th>'
                                                                + '</tr>'
                                                                + '</thead>'
                                                                + '<tbody>' + rows + '</tbody>'
                                                                + '</table>'
                                                                + '</div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>'
                                                                + '<a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">Mở Báo cáo chuyên sâu</a>'
                                                                );
                                                    }

                                                    async function openAccountQuickModal(filter) {
                                                        ensureQuickModals();
                                                        currentAccountFilter = filter || 'all';
                                                        setQuickModalContent('Quản lý nhanh tài khoản nhân sự', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAccountsData', {filter: currentAccountFilter});
                                                            renderAccountQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Quản lý nhanh tài khoản nhân sự', '<div class="alert alert-danger mb-0">Không thể tải dữ liệu tài khoản.</div>');
                                                        }
                                                    }

                                                    async function openRevenueQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Hóa đơn thu tiền gần nhất trong ngày', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickRevenueData');
                                                            renderRevenueQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Hóa đơn thu tiền gần nhất trong ngày', '<div class="alert alert-danger mb-0">Không thể tải dữ liệu hóa đơn.</div>');
                                                        }
                                                    }

                                                    async function openServiceQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh sách dịch vụ y tế hiện tại', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickServicesData');
                                                            renderServiceQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh sách dịch vụ y tế hiện tại', '<div class="alert alert-danger mb-0">Không thể tải dữ liệu dịch vụ.</div>');
                                                        }
                                                    }

                                                    async function openAppointmentQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Ca bệnh vừa hoàn tất trong ngày', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAppointmentsData');
                                                            renderAppointmentQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Ca bệnh vừa hoàn tất trong ngày', '<div class="alert alert-danger mb-0">Không thể tải dữ liệu lượt khám.</div>');
                                                        }
                                                    }

                                                    async function openLockedAccountsModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh sách tài khoản đã khóa', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAccountsData', {
                                                                filter: 'locked'
                                                            });
                                                            const items = Array.isArray(data) ? data : (Array.isArray(data.items) ? data.items : []);
                                                            renderLockedAccountModalRows(items);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh sách tài khoản đã khóa', '<div class="alert alert-danger mb-0">Không thể tải dữ liệu tài khoản đã khóa.</div>');
                                                        }
                                                    }

                                                    async function openCompletedAppointmentsModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh sách lượt khám hoàn tất', '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAppointmentsData');
                                                            const items = Array.isArray(data) ? data : (Array.isArray(data.items) ? data.items : []);
                                                            renderCompletedAppointmentsModalRows(items);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh sách lượt khám hoàn tất', '<div class="alert alert-danger mb-0">Không thể tải danh sách ca khám đã hoàn tất.</div>');
                                                        }
                                                    }

                                                    async function openInvoiceQuickDetail(invoiceId) {
                                                        ensureQuickModals();
                                                        document.getElementById('dashboardInvoiceDetailModalLabel').textContent = 'Chi tiết hóa đơn #' + invoiceId;
                                                        document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="text-muted py-4 text-center">Đang tải dữ liệu...</div>';
                                                        dashboardInvoiceDetailModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getInvoiceItems', {invoiceId: invoiceId});
                                                            const items = Array.isArray(data.items) ? data.items : [];
                                                            let rows = '';
                                                            if (items.length === 0) {
                                                                rows = '<tr><td colspan="4" class="text-center text-muted py-4">Hóa đơn chưa có dòng dịch vụ</td></tr>';
                                                            } else {
                                                                items.forEach(item => {
                                                                    rows += '<tr>';
                                                                    rows += '<td>' + escapeHtml(item.serviceName) + '</td>';
                                                                    rows += '<td class="text-end">' + escapeHtml(item.quantity) + '</td>';
                                                                    rows += '<td class="text-end">' + formatCurrency(item.unitPrice) + '</td>';
                                                                    rows += '<td class="text-end fw-semibold">' + formatCurrency(item.lineTotal) + '</td>';
                                                                    rows += '</tr>';
                                                                });
                                                            }
                                                            document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>Dịch vụ</th><th class="text-end">SL</th><th class="text-end">Đơn giá</th><th class="text-end">Thành tiền</th></tr></thead><tbody>' + rows + '</tbody></table></div>';
                                                        } catch (error) {
                                                            document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="alert alert-danger mb-0">Không thể tải chi tiết hóa đơn.</div>';
                                                        }
                                                    }

                                                    function applyQueueBadgeStyles() {
                                                        document.querySelectorAll('.queue-load-badge').forEach(badge => {
                                                            const waitingCount = Number(badge.dataset.waitingCount || badge.textContent || 0);
                                                            badge.classList.remove('bg-secondary', 'text-white', 'bg-warning', 'text-dark', 'bg-danger', 'animate-pulse', 'bg-success');
                                                            if (waitingCount === 0) {
                                                                badge.classList.add('bg-secondary', 'text-white');
                                                            } else if (waitingCount >= 1 && waitingCount <= 5) {
                                                                badge.classList.add('bg-warning', 'text-dark');
                                                            } else {
                                                                badge.classList.add('bg-danger', 'text-white', 'animate-pulse');
                                                            }
                                                        });
                                                    }
                                                    function showChartEmptyState(canvasId, message) {
                                                        const canvas = document.getElementById(canvasId);
                                                        if (!canvas) {
                                                            return;
                                                        }

                                                        const wrapper = canvas.parentElement;
                                                        if (!wrapper) {
                                                            return;
                                                        }

                                                        canvas.style.display = 'none';
                                                        const oldEmptyState = wrapper.querySelector('.chart-empty-state');
                                                        if (oldEmptyState) {
                                                            oldEmptyState.remove();
                                                        }

                                                        const emptyDiv = document.createElement('div');
                                                        emptyDiv.className = 'chart-empty-state';
                                                        emptyDiv.innerHTML = '<div><i class="fa-regular fa-folder-open"></i>' + escapeHtml(message) + '</div>';
                                                        wrapper.appendChild(emptyDiv);
                                                    }

                                                    function hideChartEmptyState(canvasId) {
                                                        const canvas = document.getElementById(canvasId);
                                                        if (!canvas) {
                                                            return;
                                                        }

                                                        const wrapper = canvas.parentElement;
                                                        if (!wrapper) {
                                                            return;
                                                        }

                                                        const oldEmptyState = wrapper.querySelector('.chart-empty-state');
                                                        if (oldEmptyState) {
                                                            oldEmptyState.remove();
                                                        }

                                                        canvas.style.display = 'block';
                                                    }
                                                    function renderTodayCharts() {
                                                        const flowRows = Array.isArray(todayPatientFlowData)
                                                                ? todayPatientFlowData.filter(item => String(item.timeSlot || '').trim() !== '')
                                                                : [];

                                                        const flowLabels = flowRows.map(item => String(item.timeSlot || '').trim());
                                                        const flowValues = flowRows.map(item => Number(item.visitCount || 0));

                                                        const revenueMap = {
                                                            Examination: 0,
                                                            Lab_Test: 0
                                                        };

                                                        if (Array.isArray(todayRevenueByServiceData)) {
                                                            todayRevenueByServiceData.forEach(item => {
                                                                const type = String(item.serviceType || '');
                                                                revenueMap[type] = Number(item.totalRevenue || 0);
                                                            });
                                                        }

                                                        const revenueValues = [
                                                            revenueMap.Examination,
                                                            revenueMap.Lab_Test
                                                        ];

                                                        const statusMap = {
                                                            Waiting: 0,
                                                            Checked_In: 0,
                                                            In_Progress: 0,
                                                            Completed: 0,
                                                            Absent: 0,
                                                            Cancelled: 0
                                                        };

                                                        if (Array.isArray(todayStatusDistributionData)) {
                                                            todayStatusDistributionData.forEach(item => {
                                                                const status = String(item.status || '');

                                                                if (Object.prototype.hasOwnProperty.call(statusMap, status)) {
                                                                    statusMap[status] = Number(item.totalCount || 0);
                                                                }
                                                            });
                                                        }

                                                        const statusValues = [
                                                            statusMap.Waiting,
                                                            statusMap.Checked_In,
                                                            statusMap.In_Progress,
                                                            statusMap.Completed,
                                                            statusMap.Absent,
                                                            statusMap.Cancelled
                                                        ];

                                                        const flowCanvas = document.getElementById('todayHourlyFlowChart');
                                                        const hasFlowData = flowValues.some(value => Number(value || 0) > 0);

                                                        if (!hasFlowData) {
                                                            showChartEmptyState('todayHourlyFlowChart', 'Không có lượt khám hôm nay');
                                                        } else if (flowCanvas) {
                                                            hideChartEmptyState('todayHourlyFlowChart');

                                                            new Chart(flowCanvas, {
                                                                type: 'bar',
                                                                data: {
                                                                    labels: flowLabels,
                                                                    datasets: [{
                                                                            label: 'Số lượt khám',
                                                                            data: flowValues,
                                                                            borderWidth: 1,
                                                                            borderRadius: 8,
                                                                            maxBarThickness: 28,
                                                                            backgroundColor: 'rgba(31, 119, 180, 0.35)',
                                                                            borderColor: '#1f77b4'
                                                                        }]
                                                                },
                                                                options: {
                                                                    responsive: true,
                                                                    maintainAspectRatio: false,
                                                                    plugins: {
                                                                        legend: {
                                                                            display: true
                                                                        }
                                                                    },
                                                                    scales: {
                                                                        x: {
                                                                            ticks: {
                                                                                autoSkip: false,
                                                                                maxRotation: 45,
                                                                                minRotation: 45
                                                                            }
                                                                        },
                                                                        y: {
                                                                            beginAtZero: true,
                                                                            ticks: {
                                                                                precision: 0,
                                                                                stepSize: 1
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            });
                                                        }

                                                        const revenueCanvas = document.getElementById('todayRevenueServiceChart');
                                                        const hasRevenueData = revenueValues.some(value => Number(value || 0) > 0);

                                                        if (!hasRevenueData) {
                                                            showChartEmptyState('todayRevenueServiceChart', 'Hôm nay chưa có doanh thu');
                                                        } else if (revenueCanvas) {
                                                            hideChartEmptyState('todayRevenueServiceChart');

                                                            new Chart(revenueCanvas, {
                                                                type: 'bar',
                                                                data: {
                                                                    labels: ['Khám bệnh', 'Xét nghiệm'],
                                                                    datasets: [{
                                                                            label: 'Doanh thu',
                                                                            data: revenueValues,
                                                                            borderRadius: 12,
                                                                            maxBarThickness: 56,
                                                                            backgroundColor: ['rgba(20, 184, 166, 0.78)', 'rgba(124, 58, 237, 0.72)'],
                                                                            borderColor: ['#0f766e', '#6d28d9'],
                                                                            borderWidth: 1
                                                                        }]
                                                                },
                                                                options: {
                                                                    responsive: true,
                                                                    maintainAspectRatio: false,
                                                                    plugins: {
                                                                        legend: {
                                                                            display: true,
                                                                            labels: {
                                                                                boxWidth: 24
                                                                            }
                                                                        },
                                                                        tooltip: {
                                                                            callbacks: {
                                                                                label: function (context) {
                                                                                    return context.label + ': ' + formatCurrency(context.raw);
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            });
                                                        }

                                                        const statusCanvas = document.getElementById('todayStatusPieChart');
                                                        const hasStatusData = statusValues.some(value => Number(value || 0) > 0);

                                                        if (!hasStatusData) {
                                                            showChartEmptyState('todayStatusPieChart', 'Hôm nay chưa có ca khám');
                                                        } else if (statusCanvas) {
                                                            hideChartEmptyState('todayStatusPieChart');

                                                            new Chart(statusCanvas, {
                                                                type: 'doughnut',
                                                                data: {
                                                                    labels: ['Đang chờ', 'Đã check-in', 'Đang khám', 'Đã hoàn tất', 'Không đến', 'Đã hủy'],
                                                                    datasets: [{
                                                                            data: statusValues,
                                                                            backgroundColor: ['#f4a261', '#4361ee', '#4cc9f0', '#2a9d8f', '#6c757d', '#dc3545']
                                                                        }]
                                                                },
                                                                options: {
                                                                    responsive: true,
                                                                    maintainAspectRatio: false,
                                                                    cutout: '68%'
                                                                }
                                                            });
                                                        }
                                                    }
                                                    document.addEventListener('DOMContentLoaded', function () {
                                                        revealKpiCards();
                                                        applyQueueBadgeStyles();
                                                        renderTodayCharts();
                                                        document.addEventListener('click', async function (event) {
                                                            const accountToggle = event.target.closest('.quick-toggle-account');
                                                            if (accountToggle) {
                                                                accountToggle.disabled = true;
                                                                try {
                                                                    const data = await postQuickAction('ajaxToggleAccountStatus', {
                                                                        accountId: accountToggle.dataset.accountId,
                                                                        status: accountToggle.dataset.nextStatus
                                                                    });
                                                                    if (data.success) {
                                                                        document.getElementById('kpiActiveAccounts').textContent = data.activeAccounts;
                                                                        document.getElementById('kpiLockedAccounts').textContent = data.lockedAccounts;
                                                                        openAccountQuickModal(currentAccountFilter);
                                                                    }
                                                                } catch (error) {
                                                                    accountToggle.disabled = false;
                                                                }
                                                                return;
                                                            }

                                                            const serviceToggle = event.target.closest('.quick-toggle-service');
                                                            if (serviceToggle) {
                                                                serviceToggle.disabled = true;
                                                                try {
                                                                    const data = await postQuickAction('ajaxToggleServiceStatus', {
                                                                        serviceId: serviceToggle.dataset.serviceId,
                                                                        status: serviceToggle.dataset.nextStatus
                                                                    });
                                                                    if (data.success) {
                                                                        document.getElementById('kpiTotalServices').textContent = data.activeServices;
                                                                        openServiceQuickModal();
                                                                    }
                                                                } catch (error) {
                                                                    serviceToggle.disabled = false;
                                                                }
                                                                return;
                                                            }

                                                            const invoiceButton = event.target.closest('.quick-view-invoice');
                                                            if (invoiceButton) {
                                                                openInvoiceQuickDetail(invoiceButton.dataset.invoiceId);
                                                            }
                                                        });
                                                    }
                                                    );
                                                    window.openAccountQuickModal = openAccountQuickModal;
                                                    window.openRevenueQuickModal = openRevenueQuickModal;
                                                    window.openServiceQuickModal = openServiceQuickModal;
                                                    window.openAppointmentQuickModal = openAppointmentQuickModal;
                                                    window.openLockedAccountsModal = openLockedAccountsModal;
                                                    window.openCompletedAppointmentsModal = openCompletedAppointmentsModal;
                                                    window.openDoctorQueueModal = openDoctorQueueModal;
                                                    window.openTodayAppointmentsModal = openTodayAppointmentsModal;
                                                    window.openTodayWaitingModal = openTodayWaitingModal;
                                                    window.openDoctorShiftModal = openDoctorShiftModal;
