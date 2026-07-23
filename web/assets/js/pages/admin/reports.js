let revenueChart = null;
    let visitChart = null;
    let currentChartData = { revenueLabels: [], revenueValues: [], visitLabels: [], visitValues: [] };
    let currentSelectedPeriod = null;
    let currentDetailData = { invoices: [], appointments: [] };
    let invoiceDetailModalInstance = null;
    let selectedChartPeriod = '';

    const revenueSeries = window.AdminConfig && Array.isArray(window.AdminConfig.revenueSeries) ? window.AdminConfig.revenueSeries : [];
    const visitSeries = window.AdminConfig && Array.isArray(window.AdminConfig.visitSeries) ? window.AdminConfig.visitSeries : [];
    const granularityInputName = 'granularity';

    const revenueLabels = revenueSeries.map(x => x.period);
    const revenueValues = revenueSeries.map(x => Number(x.value || 0));
    const visitLabels = visitSeries.map(x => x.period);
    const visitValues = visitSeries.map(x => Number(x.value || 0));

    currentChartData = {
        revenueLabels: revenueLabels,
        revenueValues: revenueValues,
        visitLabels: visitLabels,
        visitValues: visitValues
    };

    const initialInvoices = window.AdminConfig && Array.isArray(window.AdminConfig.initialInvoices) ? window.AdminConfig.initialInvoices : [];
    const initialAppointments = window.AdminConfig && Array.isArray(window.AdminConfig.initialAppointments) ? window.AdminConfig.initialAppointments : [];
    const initialPeriod = (window.AdminConfig && window.AdminConfig.initialPeriod)
        ? window.AdminConfig.initialPeriod
        : (revenueLabels.length > 0 ? revenueLabels[revenueLabels.length - 1] : (visitLabels.length > 0 ? visitLabels[visitLabels.length - 1] : ''));

    if (initialPeriod) {
        currentSelectedPeriod = initialPeriod;
        currentDetailData.invoices = initialInvoices;
        currentDetailData.appointments = initialAppointments;
    }

    function createChartConfig(labels, values, chartLabel, activeColor, inactiveColor, onPick) {
        return {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: chartLabel,
                    data: values,
                    borderColor: activeColor,
                    backgroundColor: buildChartColors(labels, selectedChartPeriod, activeColor, inactiveColor)
                }]
            },
            options: {
                maintainAspectRatio: false,
                onClick: (event, activeElements) => {
                    if (activeElements && activeElements.length > 0) {
                        const firstPoint = activeElements[0];
                        const clickedLabel = labels[firstPoint.index];
                        if (clickedLabel) {
                            onPick(clickedLabel);
                        }
                    }
                }
            }
        };
    }

    if (revenueLabels.length > 0) {
        revenueChart = new Chart(
            document.getElementById('revenueChart'),
            createChartConfig(
                revenueLabels,
                revenueValues,
                'Doanh thu (VN\u0110)',
                'rgba(25,135,84,.95)',
                'rgba(25,135,84,.25)',
                fetchReportDetail
            )
        );
    }

    if (visitLabels.length > 0) {
        visitChart = new Chart(
            document.getElementById('visitChart'),
            createChartConfig(
                visitLabels,
                visitValues,
                'L\u01B0\u1EE3t kh\u00E1m \u0111\u00E3 ho\u00E0n t\u1EA5t',
                'rgba(13,110,253,.95)',
                'rgba(13,110,253,.25)',
                fetchReportDetail
            )
        );
        visitChart.options.datasets = {
            bar: {
                categoryPercentage: 0.4,
                barPercentage: 0.8
            }
        };
        visitChart.update();
    }

    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text).replace(/[&<>"']/g, char => map[char]);
    }

    function formatCurrency(num) {
        if (num === null || num === undefined) return '0';
        const value = typeof num === 'string' ? parseFloat(num) : num;
        if (Number.isNaN(value)) return '0';
        return value.toLocaleString('vi-VN', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 2
        }) + ' VN\u0110';
    }

    function getAppointmentStatusMeta(status) {
        const normalized = String(status || '').trim();
        switch (normalized) {
            case 'Completed':
                return { label: 'Ho\u00E0n t\u1EA5t', className: 'badge bg-success' };
            case 'Checked_In':
                return { label: '\u0110\u00E3 check-in', className: 'badge bg-primary' };
            case 'Cancelled':
                return { label: '\u0110\u00E3 h\u1EE7y', className: 'badge bg-danger' };
            case 'Absent':
                return { label: 'Kh\u00F4ng \u0111\u1EBFn', className: 'badge bg-secondary' };
            case 'In_Progress':
                return { label: '\u0110ang kh\u00E1m', className: 'badge bg-info text-dark' };
            case 'Waiting':
                return { label: 'Ch\u1EDD \u0111\u1EE3i', className: 'badge bg-warning text-dark' };
            default:
                return { label: normalized || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh', className: 'badge bg-secondary' };
        }
    }

    function parseDetailResponse(data) {
        const invoices = Array.isArray(data && data.invoices) ? data.invoices : [];
        const appointments = Array.isArray(data && data.appointments) ? data.appointments : [];
        return { invoices, appointments };
    }

    function buildChartColors(labels, selectedLabel, activeColor, inactiveColor) {
        return labels.map(label => label === selectedLabel ? activeColor : inactiveColor);
    }

    function getSelectedGranularity() {
        const checked = document.querySelector('input[name="' + granularityInputName + '"]:checked');
        return checked ? checked.value : 'month';
    }

    function syncReportFilterUI() {
        const dayMode = getSelectedGranularity() === 'day';
        const reportRangeWrap = document.getElementById('reportRangeFilterWrap');
        const reportStartDateInput = document.getElementById('reportStartDate');
        const reportEndDateInput = document.getElementById('reportEndDate');
        const yearInput = document.querySelector('input[name="year"]');
        const monthInput = document.querySelector('input[name="month"]');
        if (reportRangeWrap) {
            reportRangeWrap.classList.toggle('d-none', !dayMode);
        }
        if (yearInput) {
            yearInput.closest('.col-md-2')?.classList.toggle('d-none', dayMode);
        }
        if (monthInput) {
            monthInput.closest('.col-md-2')?.classList.toggle('d-none', dayMode);
        }
        if (dayMode) {
            const today = new Date();
            const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
            const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0);
            const pad = value => String(value).padStart(2, '0');

            if (reportStartDateInput && !reportStartDateInput.value) {
                reportStartDateInput.value = firstDay.getFullYear() + '-' + pad(firstDay.getMonth() + 1) + '-' + pad(firstDay.getDate());
            }
            if (reportEndDateInput && !reportEndDateInput.value) {
                reportEndDateInput.value = lastDay.getFullYear() + '-' + pad(lastDay.getMonth() + 1) + '-' + pad(lastDay.getDate());
            }
        }
        if (reportStartDateInput) {
            reportStartDateInput.required = dayMode;
        }
        if (reportEndDateInput) {
            reportEndDateInput.required = dayMode;
        }
    }

    function syncSelectedPeriodUI(period) {
        selectedChartPeriod = period || '';

        const badge = document.getElementById('selectedPeriodBadge');
        if (badge) {
            badge.textContent = selectedChartPeriod ? ('\u0110ang xem k\u1EF3: ' + selectedChartPeriod) : 'Ch\u01B0a ch\u1ECDn k\u1EF3';
            badge.className = 'badge ' + (selectedChartPeriod ? 'bg-primary' : 'bg-secondary');
        }

        if (revenueChart) {
            revenueChart.data.datasets[0].backgroundColor = buildChartColors(
                revenueChart.data.labels,
                selectedChartPeriod,
                'rgba(25,135,84,.95)',
                'rgba(25,135,84,.25)'
            );
            revenueChart.update();
        }

        if (visitChart) {
            visitChart.data.datasets[0].backgroundColor = buildChartColors(
                visitChart.data.labels,
                selectedChartPeriod,
                'rgba(13,110,253,.95)',
                'rgba(13,110,253,.25)'
            );
            visitChart.update();
        }
    }

    async function fetchReportDetail(period) {
        if (!period || (period.trim && period.trim() === '')) {
            return;
        }

        const normalizedPeriod = period.trim();
        const basePath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
        const url = basePath + '/admin?action=getReportDetail&period=' + encodeURIComponent(normalizedPeriod);

        try {
            const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
            if (!response.ok) {
                throw new Error('HTTP ' + response.status);
            }

            const data = await response.json();
            const parsed = parseDetailResponse(data);
            currentDetailData.invoices = parsed.invoices;
            currentDetailData.appointments = parsed.appointments;
            currentSelectedPeriod = normalizedPeriod;
            syncSelectedPeriodUI(normalizedPeriod);

            renderInvoiceTable(currentDetailData.invoices);
            renderAppointmentTable(currentDetailData.appointments);
        } catch (err) {
            console.error('[fetchReportDetail] Error:', err);
            alert('Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u chi ti\u1EBFt k\u1EF3 ' + normalizedPeriod + '.');
        }
    }

    function renderInvoiceTable(invoices) {
        const tbody = document.getElementById('invoiceTableBody');
        if (!tbody) {
            return;
        }
        tbody.innerHTML = '';

        if (!invoices || invoices.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-3">Kh\u00F4ng c\u00F3 d\u1EEF li\u1EC7u</td></tr>';
            return;
        }

        let html = '';
        invoices.forEach(item => {
            const safeInvoiceId = String(item.invoiceId || '').replace(/'/g, "\\'");
            html += '<tr>';
            html += '<td>' + escapeHtml(item.invoiceId) + '</td>';
            html += '<td>' + escapeHtml(item.patientName) + '</td>';
            html += '<td class="text-end">' + formatCurrency(item.totalAmount) + '</td>';
            html += '<td class="text-end">' + formatCurrency(item.bhytDeduction) + '</td>';
            html += '<td class="text-end fw-semibold">' + formatCurrency(item.finalAmount) + '</td>';
            html += '<td>' + escapeHtml(item.paymentDate) + '</td>';
            html += '<td><button class="btn btn-sm btn-outline-primary" onclick="viewInvoiceDetail(\'' + safeInvoiceId + '\')">Xem chi ti\u1EBFt</button></td>';
            html += '</tr>';
        });
        tbody.innerHTML = html;
    }

    function renderAppointmentTable(appointments) {
        const tbody = document.getElementById('appointmentTableBody');
        if (!tbody) {
            return;
        }
        tbody.innerHTML = '';

        if (!appointments || appointments.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">Kh\u00F4ng c\u00F3 d\u1EEF li\u1EC7u</td></tr>';
            return;
        }

        let html = '';
        appointments.forEach(item => {
            const statusMeta = getAppointmentStatusMeta(item.status);
            html += '<tr>';
            html += '<td>' + escapeHtml(item.appointmentId) + '</td>';
            html += '<td>' + escapeHtml(item.patientName) + '</td>';
            html += '<td>' + escapeHtml(item.doctorName) + '</td>';
            html += '<td>' + escapeHtml(item.timeSlot) + '</td>';
            html += '<td><span class="' + statusMeta.className + '">' + escapeHtml(statusMeta.label) + '</span></td>';
            html += '<td>' + escapeHtml(item.appointmentDate) + '</td>';
            html += '</tr>';
        });
        tbody.innerHTML = html;
    }

    function renderInvoiceItemTable(items) {
        const tbody = document.getElementById('invoiceItemTableBody');
        if (!tbody) {
            return;
        }
        tbody.innerHTML = '';

        if (!items || items.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3">Kh\u00F4ng c\u00F3 chi ti\u1EBFt d\u1ECBch v\u1EE5</td></tr>';
            return;
        }

        let html = '';
        items.forEach(item => {
            html += '<tr>';
            html += '<td>' + escapeHtml(item.serviceName || ('D\u1ECBch v\u1EE5 #' + item.serviceId)) + '</td>';
            html += '<td class="text-end">' + escapeHtml(item.quantity) + '</td>';
            html += '<td class="text-end">' + formatCurrency(item.unitPrice) + '</td>';
            html += '<td class="text-end fw-semibold">' + formatCurrency(item.lineTotal) + '</td>';
            html += '</tr>';
        });
        tbody.innerHTML = html;
    }

    async function viewInvoiceDetail(invoiceId) {
        if (!invoiceId) {
            return;
        }

        const basePath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
        const url = basePath + '/admin?action=getInvoiceItems&invoiceId=' + encodeURIComponent(invoiceId);
        const invoiceIdHolder = document.getElementById('invoiceDetailModalInvoiceId');
        if (invoiceIdHolder) {
            invoiceIdHolder.textContent = invoiceId;
        }

        renderInvoiceItemTable([]);

        try {
            const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
            if (!response.ok) {
                throw new Error('HTTP ' + response.status);
            }
            const data = await response.json();
            renderInvoiceItemTable(Array.isArray(data.items) ? data.items : []);
        } catch (err) {
            console.error('[viewInvoiceDetail] Error:', err);
            renderInvoiceItemTable([]);
        }

        if (!invoiceDetailModalInstance) {
            invoiceDetailModalInstance = new bootstrap.Modal(document.getElementById('invoiceDetailModal'));
        }
        invoiceDetailModalInstance.show();
    }

    const invoiceTabEl = document.getElementById('invoiceTab');
    if (invoiceTabEl) {
        invoiceTabEl.addEventListener('shown.bs.tab', function () {
            renderInvoiceTable(currentDetailData.invoices);
        });
    }

    const appointmentTabEl = document.getElementById('appointmentTab');
    if (appointmentTabEl) {
        appointmentTabEl.addEventListener('shown.bs.tab', function () {
            renderAppointmentTable(currentDetailData.appointments);
        });
    }

    window.viewInvoiceDetail = viewInvoiceDetail;

    document.addEventListener('DOMContentLoaded', function () {
        syncReportFilterUI();
        document.querySelectorAll('input[name="granularity"]').forEach(function (radio) {
            radio.addEventListener('change', syncReportFilterUI);
        });

        const reportForm = document.querySelector('form[action="' + (window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '') + '/admin"]');
        if (reportForm) {
            reportForm.addEventListener('submit', function () {
                if (getSelectedGranularity() !== 'day') {
                    return;
                }
                const reportStartDateInput = document.getElementById('reportStartDate');
                const reportEndDateInput = document.getElementById('reportEndDate');
                if (!reportStartDateInput || !reportEndDateInput) {
                    return;
                }
                const startParts = reportStartDateInput.value ? reportStartDateInput.value.split('-') : [];
                const endParts = reportEndDateInput.value ? reportEndDateInput.value.split('-') : [];
                if (startParts.length === 3 && endParts.length === 3) {
                    const yearInput = document.querySelector('input[name="year"]');
                    const monthInput = document.querySelector('input[name="month"]');
                    if (yearInput) yearInput.value = startParts[0];
                    if (monthInput) monthInput.value = startParts[1];
                }
            });
        }

        if (initialPeriod) {
            syncSelectedPeriodUI(initialPeriod);
            if (currentDetailData.invoices.length > 0 || currentDetailData.appointments.length > 0) {
                renderInvoiceTable(currentDetailData.invoices);
                renderAppointmentTable(currentDetailData.appointments);
            } else {
                fetchReportDetail(initialPeriod);
            }
        }
    });
