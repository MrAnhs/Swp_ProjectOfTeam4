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

    const initialPeriod = revenueLabels.length > 0
        ? revenueLabels[revenueLabels.length - 1]
        : (visitLabels.length > 0 ? visitLabels[visitLabels.length - 1] : '');

    function createChartConfig(labels, values, chartLabel, activeColor, inactiveColor, onPick) {
        return {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: chartLabel,
                    data: values,
                    borderColor: activeColor,
                    backgroundColor: buildChartColors(labels, selectedChartPeriod, activeColor, inactiveColor),
                    borderRadius: 8
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
                },
                plugins: {
                    legend: {
                        labels: {
                            color: '#F8FAFC',
                            font: { family: 'Inter', size: 13, weight: '600' }
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: { color: '#94A3B8', font: { family: 'Inter', size: 12 } },
                        grid: { color: 'rgba(255, 255, 255, 0.06)' }
                    },
                    y: {
                        ticks: { color: '#94A3B8', font: { family: 'Inter', size: 12 } },
                        grid: { color: 'rgba(255, 255, 255, 0.06)' }
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
                'Doanh thu (VNĐ)',
                'rgba(42, 181, 163, 0.9)',
                'rgba(42, 181, 163, 0.3)',
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
                'Lượt khám đã hoàn tất',
                'rgba(56, 189, 248, 0.9)',
                'rgba(56, 189, 248, 0.3)',
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
        }) + ' VNĐ';
    }

    function getAppointmentStatusMeta(status) {
        const normalized = String(status || '').trim();
        switch (normalized) {
            case 'Completed':
                return { label: 'Hoàn tất', className: 'badge bg-success' };
            case 'Checked_In':
                return { label: 'Đã check-in', className: 'badge bg-primary' };
            case 'Cancelled':
                return { label: 'Đã hủy', className: 'badge bg-danger' };
            case 'Absent':
                return { label: 'Không đến', className: 'badge bg-secondary' };
            case 'In_Progress':
                return { label: 'Đang khám', className: 'badge bg-info text-dark' };
            case 'Waiting':
                return { label: 'Chờ đợi', className: 'badge bg-warning text-dark' };
            default:
                return { label: normalized || 'Không xác định', className: 'badge bg-secondary' };
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
            badge.textContent = selectedChartPeriod ? ('Đang xem kỳ: ' + selectedChartPeriod) : 'Chưa chọn kỳ';
            badge.className = 'badge ' + (selectedChartPeriod ? 'bg-primary' : 'bg-secondary');
        }

        if (revenueChart) {
            revenueChart.data.datasets[0].backgroundColor = buildChartColors(
                revenueChart.data.labels,
                selectedChartPeriod,
                'rgba(42, 181, 163, 0.9)',
                'rgba(42, 181, 163, 0.3)'
            );
            revenueChart.update();
        }

        if (visitChart) {
            visitChart.data.datasets[0].backgroundColor = buildChartColors(
                visitChart.data.labels,
                selectedChartPeriod,
                'rgba(56, 189, 248, 0.9)',
                'rgba(56, 189, 248, 0.3)'
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
            alert('Không thể tải dữ liệu chi tiết kỳ ' + normalizedPeriod + '.');
        }
    }

    function renderInvoiceTable(invoices) {
        const tbody = document.getElementById('invoiceTableBody');
        if (!tbody) {
            return;
        }
        tbody.innerHTML = '';

        if (!invoices || invoices.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-3">Không có dữ liệu</td></tr>';
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
            html += '<td><button class="btn btn-sm btn-outline-primary" onclick="viewInvoiceDetail(\'' + safeInvoiceId + '\')">Xem chi tiết</button></td>';
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
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">Không có dữ liệu</td></tr>';
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
            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-3">Không có chi tiết dịch vụ</td></tr>';
            return;
        }

        let html = '';
        items.forEach(item => {
            html += '<tr>';
            html += '<td>' + escapeHtml(item.serviceName || ('Dịch vụ #' + item.serviceId)) + '</td>';
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

    document.getElementById('invoiceTab').addEventListener('shown.bs.tab', function () {
        renderInvoiceTable(currentDetailData.invoices);
    });

    document.getElementById('appointmentTab').addEventListener('shown.bs.tab', function () {
        renderAppointmentTable(currentDetailData.appointments);
    });

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
            fetchReportDetail(initialPeriod);
        }
    });
