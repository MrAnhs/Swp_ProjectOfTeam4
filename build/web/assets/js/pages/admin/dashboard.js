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
                                                        }) + ' VN\u0110';
                                                    }

                                                    function escapeHtml(text) {
                                                        const div = document.createElement('div');
                                                        div.textContent = text == null ? '' : String(text);
                                                        return div.innerHTML;
                                                    }

                                                    function translateRole(role) {
                                                        const roleMap = {
                                                            'Patient': 'B\u1EC7nh nh\u00E2n',
                                                            'Doctor': 'B\u00E1c s\u0129',
                                                            'Receptionist': 'L\u1EC5 t\u00E2n',
                                                            'Admin': 'Qu\u1EA3n tr\u1ECB vi\u00EAn'
                                                        };
                                                        return roleMap[role] || role;
                                                    }

                                                    function translateAccountStatus(status) {
                                                        const statusMap = {
                                                            'Active': 'Ho\u1EA1t \u0111\u1ED9ng',
                                                            'Locked': '\u0110\u00E3 kh\u00F3a'
                                                        };
                                                        return statusMap[status] || status;
                                                    }

                                                    function translateServiceStatus(status) {
                                                        const statusMap = {
                                                            'Active': 'Ho\u1EA1t \u0111\u1ED9ng',
                                                            'Inactive': 'Ng\u1EEBng ho\u1EA1t \u0111\u1ED9ng'
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
                                                                    label: 'Ch\u1EDD \u0111\u1EE3i',
                                                                    className: 'badge bg-warning text-dark status-badge-soft'
                                                                };
                                                            case 'Checked_In':
                                                                return {
                                                                    label: '\u0110\u00E3 check-in',
                                                                    className: 'badge bg-primary text-white status-badge-soft'
                                                                };
                                                            case 'In_Progress':
                                                                return {
                                                                    label: '\u0110ang kh\u00E1m',
                                                                    className: 'badge bg-info text-white status-badge-soft'
                                                                };
                                                            case 'Completed':
                                                                return {
                                                                    label: 'Ho\u00E0n t\u1EA5t',
                                                                    className: 'badge bg-success text-white status-badge-soft'
                                                                };
                                                            case 'Absent':
                                                                return {
                                                                    label: 'Kh\u00F4ng \u0111\u1EBFn',
                                                                    className: 'badge bg-secondary text-white status-badge-soft'
                                                                };
                                                            default:
                                                                return {
                                                                    label: rawStatus || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh',
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
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 l\u1ECBch h\u1EB9n h\u00F4m nay.</td></tr>';
                                                            return;
                                                        }

                                                        let html = '';
                                                        items.forEach((item, index) => {
                                                            const statusMeta = getStatusMeta(item.status);
                                                            html += '<tr>'
                                                                    + '<td>' + (index + 1) + '</td>'
                                                                    + '<td>' + escapeHtml(item.patientName || 'N/A') + '</td>'
                                                                    + '<td>' + escapeHtml(item.doctorName || 'Ch\u01B0a ph\u00E2n c\u00F4ng') + '</td>'
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
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 b\u1EC7nh nh\u00E2n \u0111\u00E3 check-in trong ng\u00E0y.</td></tr>';
                                                            return;
                                                        }

                                                        let html = '';
                                                        items.forEach((item, index) => {
                                                            const waitMinutes = Number(item.waitingMinutes || 0);
                                                            const statusMeta = getStatusMeta(item.status || 'Waiting');
                                                            html += '<tr>'
                                                                    + '<td>' + (index + 1) + '</td>'
                                                                    + '<td>' + escapeHtml(item.patientName || 'N/A') + '</td>'
                                                                    + '<td>' + escapeHtml(item.department || 'Ch\u01B0a x\u00E1c \u0111\u1ECBnh') + '</td>'
                                                                    + '<td>' + escapeHtml(item.appointmentTime || '--:--') + '</td>'
                                                                    + '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>'
                                                                    + '<td>' + waitMinutes + ' ph\u00FAt</td>'
                                                                    + '</tr>';
                                                        });
                                                        tbody.innerHTML = html;
                                                    }

                                                    async function openTodayAppointmentsModal() {
                                                        ensureQuickModals();
                                                        const tbody = document.getElementById('todayAppointmentsTableBody');
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</td></tr>';
                                                        }
                                                        todayAppointmentsModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getTodayAppointments');
                                                            renderTodayAppointmentsRows(data.items || []);
                                                        } catch (error) {
                                                            if (tbody) {
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Kh\u00F4ng th\u1EC3 t\u1EA3i danh s\u00E1ch ca kh\u00E1m h\u00F4m nay.</td></tr>';
                                                            }
                                                        }
                                                    }

                                                    async function openTodayWaitingModal() {
                                                        ensureQuickModals();
                                                        const tbody = document.getElementById('todayWaitingTableBody');
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</td></tr>';
                                                        }
                                                        todayWaitingModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getTodayWaiting');
                                                            renderTodayWaitingRows(data.items || []);
                                                        } catch (error) {
                                                            if (tbody) {
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Kh\u00F4ng th\u1EC3 t\u1EA3i danh s\u00E1ch b\u1EC7nh nh\u00E2n \u0111\u00E3 check-in.</td></tr>';
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
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 b\u1EC7nh nh\u00E2n \u0111\u00E3 check-in cho b\u00E1c s\u0129 n\u00E0y h\u00F4m nay.</td></tr>';
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
                                                            html += '<td class="text-end"><a class="btn btn-sm btn-warning text-dark" href="' + dashboardBasePath + '/admin?action=exception&appointmentId=' + appointmentId + '">\u0110i\u1EC1u ph\u1ED1i ca n\u00E0y</a></td>';
                                                            html += '</tr>';
                                                        });
                                                        tbody.innerHTML = html;
                                                    }

                                                    async function openDoctorQueueModal(doctorId, doctorName, department) {
                                                        ensureQuickModals();
                                                        const title = document.getElementById('doctorQueueModalLabel');
                                                        const tbody = document.getElementById('doctorQueueTableBody');
                                                        if (title) {
                                                            title.textContent = 'Chi ti\u1EBFt h\u00E0ng \u0111\u1EE3i - B\u00E1c s\u0129: ' + (doctorName || '') + ' (' + (department || '') + ')';
                                                        }
                                                        if (tbody) {
                                                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</td></tr>';
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
                                                                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4">Kh\u00F4ng th\u1EC3 t\u1EA3i danh s\u00E1ch b\u1EC7nh nh\u00E2n \u0111\u00E3 check-in.</td></tr>';
                                                            }
                                                        }
                                                    }

                                                    function setQuickModalContent(title, bodyHtml, footerHtml) {
                                                        document.getElementById('dashboardQuickModalLabel').textContent = title;
                                                        document.getElementById('dashboardQuickModalBody').innerHTML = bodyHtml;
                                                        document.getElementById('dashboardQuickModalFooter').innerHTML = footerHtml || '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button>';
                                                    }

                                                    function renderAccountQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 t\u00E0i kho\u1EA3n ph\u00F9 h\u1EE3p</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                const isLocked = String(item.status).toLowerCase() === 'locked';
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.fullName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.email) + '</td>';
                                                                rows += '<td>' + escapeHtml(translateRole(item.role)) + '</td>';
                                                                rows += '<td><span class="badge ' + (isLocked ? 'bg-danger' : 'bg-success') + '">' + escapeHtml(translateAccountStatus(item.status)) + '</span></td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm ' + (isLocked ? 'btn-success' : 'btn-outline-danger') + ' quick-toggle-account quick-action-btn" data-account-id="' + item.accountId + '" data-next-status="' + (isLocked ? 'active' : 'locked') + '">' + (isLocked ? 'M\u1EDF kh\u00F3a' : 'Kh\u00F3a') + '</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Qu\u1EA3n l\u00FD nhanh t\u00E0i kho\u1EA3n nh\u00E2n s\u1EF1',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>H\u1ECD t\u00EAn</th><th>Email</th><th>Vai tr\u00F2</th><th>Tr\u1EA1ng th\u00E1i</th><th class="text-end">Thao t\u00E1c</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=listUsers">M\u1EDF qu\u1EA3n l\u00FD t\u00E0i kho\u1EA3n</a>'
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
                                                            rows = '<tr><td colspan="4" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 t\u00E0i kho\u1EA3n ph\u00F9 h\u1EE3p</td></tr>';
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
                                                                'Danh s\u00E1ch t\u00E0i kho\u1EA3n \u0111\u00E3 kh\u00F3a',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>H\u1ECD t\u00EAn</th><th>Email</th><th>Vai tr\u00F2</th><th>Tr\u1EA1ng th\u00E1i</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=listUsers">M\u1EDF qu\u1EA3n l\u00FD t\u00E0i kho\u1EA3n</a>'
                                                                );
                                                    }

                                                    function renderRevenueQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">H\u00F4m nay ch\u01B0a c\u00F3 h\u00F3a \u0111\u01A1n thu ti\u1EC1n</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.invoiceId) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.payment_time || '--/--/---- --:--') + '</td>';
                                                                rows += '<td class="text-end fw-semibold">' + formatCurrency(item.finalAmount) + '</td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm btn-outline-primary quick-view-invoice" data-invoice-id="' + escapeHtml(item.invoiceId) + '">Xem chi ti\u1EBFt</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'H\u00F3a \u0111\u01A1n thu ti\u1EC1n g\u1EA7n nh\u1EA5t trong ng\u00E0y',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>M\u00E3 HD</th><th>T\u00EAn BN</th><th>Th\u1EDDi gian</th><th class="text-end">Th\u1EF1c thu</th><th class="text-end">Thao t\u00E1c</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">M\u1EDF B\u00E1o c\u00E1o chuy\u00EAn s\u00E2u</a>'
                                                                );
                                                    }

                                                    function renderServiceQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="5" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 d\u1ECBch v\u1EE5 \u0111\u1EC3 hi\u1EC3n th\u1ECB</td></tr>';
                                                        } else {
                                                            items.forEach(item => {
                                                                const isActive = String(item.status).toLowerCase() === 'active';
                                                                rows += '<tr>';
                                                                rows += '<td>' + escapeHtml(item.serviceName) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.serviceType) + '</td>';
                                                                rows += '<td class="text-end">' + formatCurrency(item.price) + '</td>';
                                                                rows += '<td><span class="badge ' + (isActive ? 'bg-success' : 'bg-secondary') + '">' + escapeHtml(translateServiceStatus(item.status)) + '</span></td>';
                                                                rows += '<td class="text-end"><button type="button" class="btn btn-sm ' + (isActive ? 'btn-outline-secondary' : 'btn-success') + ' quick-toggle-service quick-action-btn" data-service-id="' + item.serviceId + '" data-next-status="' + (isActive ? 'Inactive' : 'Active') + '">' + (isActive ? 'Ng\u01B0ng d\u00F9ng' : 'K\u00EDch ho\u1EA1t') + '</button></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh s\u00E1ch d\u1ECBch v\u1EE5 y t\u1EBF hi\u1EC7n t\u1EA1i',
                                                                '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>D\u1ECBch v\u1EE5</th><th>Lo\u1EA1i</th><th class="text-end">\u0110\u01A1n gi\u00E1</th><th>Tr\u1EA1ng th\u00E1i</th><th class="text-end">Thao t\u00E1c</th></tr></thead><tbody>' + rows + '</tbody></table></div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button><a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=manageServices">M\u1EDF qu\u1EA3n l\u00FD d\u1ECBch v\u1EE5</a>'
                                                                );
                                                        if (data.summary) {
                                                            document.getElementById('kpiTotalServices').textContent = data.summary.activeServices;
                                                        }
                                                    }

                                                    function renderAppointmentQuickModal(data) {
                                                        const items = Array.isArray(data.items) ? data.items : [];
                                                        let rows = '';
                                                        if (items.length === 0) {
                                                            rows = '<tr><td colspan="6" class="text-center text-muted py-4">Ch\u01B0a c\u00F3 l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t</td></tr>';
                                                        } else {
                                                            items.forEach((item, index) => {
                                                                rows += '<tr>';
                                                                rows += '<td>' + (index + 1) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.doctorName || 'Ch\u01B0a ph\u00E2n c\u00F4ng') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentDate || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentTime || '') + '</td>';
                                                                rows += '<td><span class="badge bg-success">\u0110\u00E3 ho\u00E0n t\u1EA5t</span></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh s\u00E1ch l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t',
                                                                '<div class="table-responsive">'
                                                                + '<table class="table table-sm table-hover quick-modal-table align-middle">'
                                                                + '<thead class="table-light">'
                                                                + '<tr>'
                                                                + '<th>STT</th>'
                                                                + '<th>B\u1EC6NH NH\u00C2N</th>'
                                                                + '<th>B\u00C1C S\u0128</th>'
                                                                + '<th>NG\u00C0Y KH\u00C1M</th>'
                                                                + '<th>GI\u1EDC H\u1EB8N</th>'
                                                                + '<th>TR\u1EA0NG TH\u00C1I</th>'
                                                                + '</tr>'
                                                                + '</thead>'
                                                                + '<tbody>' + rows + '</tbody>'
                                                                + '</table>'
                                                                + '</div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button>'
                                                                + '<a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">M\u1EDF B\u00E1o c\u00E1o chuy\u00EAn s\u00E2u</a>'
                                                                );
                                                    }

                                                    function renderCompletedAppointmentsModalRows(items) {
                                                        let rows = '';
                                                        if (!Array.isArray(items) || items.length === 0) {
                                                            rows = '<tr><td colspan="6" class="text-center text-muted py-4">Kh\u00F4ng c\u00F3 l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t</td></tr>';
                                                        } else {
                                                            items.forEach((item, index) => {
                                                                const statusMeta = getStatusMeta(item.status || 'Completed');
                                                                rows += '<tr>';
                                                                rows += '<td>' + (index + 1) + '</td>';
                                                                rows += '<td>' + escapeHtml(item.patientName || item.patient_name || 'N/A') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.doctorName || item.doctor_name || 'Ch\u01B0a ph\u00E2n c\u00F4ng') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentDate || item.appointment_date || '') + '</td>';
                                                                rows += '<td>' + escapeHtml(item.appointmentTime || item.appointment_time || '--:--') + '</td>';
                                                                rows += '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>';
                                                                rows += '</tr>';
                                                            });
                                                        }

                                                        setQuickModalContent(
                                                                'Danh s\u00E1ch l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t',
                                                                '<div class="table-responsive">'
                                                                + '<table class="table table-sm table-hover quick-modal-table">'
                                                                + '<thead class="table-light">'
                                                                + '<tr>'
                                                                + '<th>STT</th>'
                                                                + '<th>B\u1EC7nh nh\u00E2n</th>'
                                                                + '<th>B\u00E1c s\u0129</th>'
                                                                + '<th>Ng\u00E0y kh\u00E1m</th>'
                                                                + '<th>Gi\u1EDD h\u1EB9n</th>'
                                                                + '<th>Tr\u1EA1ng th\u00E1i</th>'
                                                                + '</tr>'
                                                                + '</thead>'
                                                                + '<tbody>' + rows + '</tbody>'
                                                                + '</table>'
                                                                + '</div>',
                                                                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\u0110\u00F3ng</button>'
                                                                + '<a class="btn btn-primary" href="' + dashboardBasePath + '/admin?action=reports">M\u1EDF B\u00E1o c\u00E1o chuy\u00EAn s\u00E2u</a>'
                                                                );
                                                    }

                                                    async function openAccountQuickModal(filter) {
                                                        ensureQuickModals();
                                                        currentAccountFilter = filter || 'all';
                                                        setQuickModalContent('Qu\u1EA3n l\u00FD nhanh t\u00E0i kho\u1EA3n nh\u00E2n s\u1EF1', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAccountsData', {filter: currentAccountFilter});
                                                            renderAccountQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Qu\u1EA3n l\u00FD nhanh t\u00E0i kho\u1EA3n nh\u00E2n s\u1EF1', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u t\u00E0i kho\u1EA3n.</div>');
                                                        }
                                                    }

                                                    async function openRevenueQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('H\u00F3a \u0111\u01A1n thu ti\u1EC1n g\u1EA7n nh\u1EA5t trong ng\u00E0y', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickRevenueData');
                                                            renderRevenueQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('H\u00F3a \u0111\u01A1n thu ti\u1EC1n g\u1EA7n nh\u1EA5t trong ng\u00E0y', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u h\u00F3a \u0111\u01A1n.</div>');
                                                        }
                                                    }

                                                    async function openServiceQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh s\u00E1ch d\u1ECBch v\u1EE5 y t\u1EBF hi\u1EC7n t\u1EA1i', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickServicesData');
                                                            renderServiceQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh s\u00E1ch d\u1ECBch v\u1EE5 y t\u1EBF hi\u1EC7n t\u1EA1i', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u d\u1ECBch v\u1EE5.</div>');
                                                        }
                                                    }

                                                    async function openAppointmentQuickModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Ca b\u1EC7nh v\u1EEBa ho\u00E0n t\u1EA5t trong ng\u00E0y', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAppointmentsData');
                                                            renderAppointmentQuickModal(data);
                                                        } catch (error) {
                                                            setQuickModalContent('Ca b\u1EC7nh v\u1EEBa ho\u00E0n t\u1EA5t trong ng\u00E0y', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u l\u01B0\u1EE3t kh\u00E1m.</div>');
                                                        }
                                                    }

                                                    async function openLockedAccountsModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh s\u00E1ch t\u00E0i kho\u1EA3n \u0111\u00E3 kh\u00F3a', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAccountsData', {
                                                                filter: 'locked'
                                                            });
                                                            const items = Array.isArray(data) ? data : (Array.isArray(data.items) ? data.items : []);
                                                            renderLockedAccountModalRows(items);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh s\u00E1ch t\u00E0i kho\u1EA3n \u0111\u00E3 kh\u00F3a', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u t\u00E0i kho\u1EA3n \u0111\u00E3 kh\u00F3a.</div>');
                                                        }
                                                    }

                                                    async function openCompletedAppointmentsModal() {
                                                        ensureQuickModals();
                                                        setQuickModalContent('Danh s\u00E1ch l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t', '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>');
                                                        dashboardQuickModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('quickAppointmentsData');
                                                            const items = Array.isArray(data) ? data : (Array.isArray(data.items) ? data.items : []);
                                                            renderCompletedAppointmentsModalRows(items);
                                                        } catch (error) {
                                                            setQuickModalContent('Danh s\u00E1ch l\u01B0\u1EE3t kh\u00E1m ho\u00E0n t\u1EA5t', '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i danh s\u00E1ch ca kh\u00E1m \u0111\u00E3 ho\u00E0n t\u1EA5t.</div>');
                                                        }
                                                    }

                                                    async function openInvoiceQuickDetail(invoiceId) {
                                                        ensureQuickModals();
                                                        document.getElementById('dashboardInvoiceDetailModalLabel').textContent = 'Chi ti\u1EBFt h\u00F3a \u0111\u01A1n #' + invoiceId;
                                                        document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="text-muted py-4 text-center">\u0110ang t\u1EA3i d\u1EEF li\u1EC7u...</div>';
                                                        dashboardInvoiceDetailModalInstance.show();
                                                        try {
                                                            const data = await fetchQuickData('getInvoiceItems', {invoiceId: invoiceId});
                                                            const items = Array.isArray(data.items) ? data.items : [];
                                                            let rows = '';
                                                            if (items.length === 0) {
                                                                rows = '<tr><td colspan="4" class="text-center text-muted py-4">H\u00F3a \u0111\u01A1n ch\u01B0a c\u00F3 d\u00F2ng d\u1ECBch v\u1EE5</td></tr>';
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
                                                            document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="table-responsive"><table class="table table-sm table-hover quick-modal-table"><thead class="table-light"><tr><th>D\u1ECBch v\u1EE5</th><th class="text-end">SL</th><th class="text-end">\u0110\u01A1n gi\u00E1</th><th class="text-end">Th\u00E0nh ti\u1EC1n</th></tr></thead><tbody>' + rows + '</tbody></table></div>';
                                                        } catch (error) {
                                                            document.getElementById('dashboardInvoiceDetailModalBody').innerHTML = '<div class="alert alert-danger mb-0">Kh\u00F4ng th\u1EC3 t\u1EA3i chi ti\u1EBFt h\u00F3a \u0111\u01A1n.</div>';
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
                                                            showChartEmptyState('todayHourlyFlowChart', 'Kh\u00F4ng c\u00F3 l\u01B0\u1EE3t kh\u00E1m h\u00F4m nay');
                                                        } else if (flowCanvas) {
                                                            hideChartEmptyState('todayHourlyFlowChart');

                                                            new Chart(flowCanvas, {
                                                                type: 'bar',
                                                                data: {
                                                                    labels: flowLabels,
                                                                    datasets: [{
                                                                            label: 'S\u1ED1 l\u01B0\u1EE3t kh\u00E1m',
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
                                                            showChartEmptyState('todayRevenueServiceChart', 'H\u00F4m nay ch\u01B0a c\u00F3 doanh thu');
                                                        } else if (revenueCanvas) {
                                                            hideChartEmptyState('todayRevenueServiceChart');

                                                            new Chart(revenueCanvas, {
                                                                type: 'bar',
                                                                data: {
                                                                    labels: ['Kh\u00E1m b\u1EC7nh', 'X\u00E9t nghi\u1EC7m'],
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
                                                            showChartEmptyState('todayStatusPieChart', 'H\u00F4m nay ch\u01B0a c\u00F3 ca kh\u00E1m');
                                                        } else if (statusCanvas) {
                                                            hideChartEmptyState('todayStatusPieChart');

                                                            new Chart(statusCanvas, {
                                                                type: 'doughnut',
                                                                data: {
                                                                    labels: ['\u0110ang ch\u1EDD', '\u0110\u00E3 check-in', '\u0110ang kh\u00E1m', '\u0110\u00E3 ho\u00E0n t\u1EA5t', 'Kh\u00F4ng \u0111\u1EBFn', '\u0110\u00E3 h\u1EE7y'],
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
