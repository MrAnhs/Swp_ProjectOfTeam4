(function () {
    const utils = window.ReceptionistUtils;
    const list = document.getElementById('invoiceList');
    const message = document.getElementById('billingMessage');
    let currentStatus = 'Pending';

    function setMessage(text, type) {
        message.innerHTML = text ? '<div class="alert alert-' + (type || 'info') + '">' + utils.escapeHtml(text) + '</div>' : '';
    }

    async function loadStats() {
        const data = await utils.requestJson(utils.apiBase() + '/invoices/stats');
        document.getElementById('pendingInvoiceCount').textContent = data.pendingCount || 0;
        document.getElementById('paidInvoiceCount').textContent = data.paidCount || 0;
    }

    function renderInvoices(invoices) {
        if (!invoices || invoices.length === 0) {
            list.innerHTML = '<div class="empty-state">Kh\u00F4ng c\u00F3 h\u00F3a \u0111\u01A1n ph\u00F9 h\u1EE3p.</div>';
            return;
        }
        list.innerHTML = invoices.map(function (invoice) {
            return '<div class="invoice-card" id="card-' + utils.escapeHtml(invoice.invoiceId) + '">'
                + '<div class="invoice-row" style="cursor: pointer;" data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '">'
                + '<div><div class="fw-bold"><i class="bi bi-chevron-right me-2 text-primary toggle-icon" style="display: inline-block;"></i>H\u00F3a \u0111\u01A1n #' + utils.escapeHtml(invoice.invoiceId) + ' - ' + utils.escapeHtml(invoice.patientName) + '</div>'
                + '<div class="muted-text">' + utils.escapeHtml(invoice.phone) + ' | Ng\u00E0y t\u1EA1o: ' + utils.escapeHtml(invoice.createdAt) + '</div></div>'
                + '<div class="text-end"><div class="fw-bold">' + utils.formatCurrency(invoice.finalAmount) + '</div>'
                + '<span class="badge ' + (invoice.status === 'Paid' ? 'text-bg-success' : 'text-bg-warning') + '">' + utils.escapeHtml(invoice.status === 'Paid' ? '\u0110\u00E3 thanh to\u00E1n' : 'Ch\u1EDD thanh to\u00E1n') + '</span>'
                + (invoice.status === 'Paid'
                    ? '<div><button class="btn btn-sm btn-outline-primary mt-2 invoice-print"'
                        + ' data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '"'
                        + ' data-patient-name="' + utils.escapeHtml(invoice.patientName) + '"'
                        + ' data-phone="' + utils.escapeHtml(invoice.phone) + '"'
                        + ' data-created-at="' + utils.escapeHtml(invoice.createdAt) + '"'
                        + ' data-final-amount="' + utils.escapeHtml(invoice.finalAmount) + '"'
                        + ' data-status="' + utils.escapeHtml(invoice.status) + '">In h\u00F3a \u0111\u01A1n</button></div>'
                    : '<div class="d-flex justify-content-end align-items-center gap-2 mt-2">'
                        + '<select class="form-select form-select-sm payment-method-select" style="width: 140px;" id="pm-' + utils.escapeHtml(invoice.invoiceId) + '">'
                        + '<option value="Cash">Ti\u1EC1n m\u1EB7t</option>'
                        + '<option value="Momo">Momo</option>'
                        + '<option value="VNPay">VNPay</option>'
                        + '<option value="Bank_Transfer">Chuy\u1EC3n kho\u1EA3n</option>'
                        + '</select>'
                        + '<button class="btn btn-sm btn-success invoice-pay-btn"'
                        + ' data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '"'
                        + ' data-patient-name="' + utils.escapeHtml(invoice.patientName) + '"'
                        + ' data-final-amount="' + utils.escapeHtml(invoice.finalAmount) + '">X\u00E1c nh\u1EADn thanh to\u00E1n</button></div>')
                + '</div></div>'
                + '<div class="invoice-details" id="details-' + utils.escapeHtml(invoice.invoiceId) + '" style="display: none;">'
                + '<div class="text-center py-2"><div class="spinner-border spinner-border-sm text-primary" role="status"></div> \u0110ang t\u1EA3i chi ti\u1EBFt...</div>'
                + '</div>'
                + '</div>';
        }).join('');
    }

    async function loadInvoices(status, keyword) {
        currentStatus = status || currentStatus;
        document.getElementById('invoiceListTitle').textContent = currentStatus === 'Paid'
            ? 'H\u00F3a \u0111\u01A1n \u0111\u00E3 thanh to\u00E1n'
            : 'H\u00F3a \u0111\u01A1n ch\u1EDD thanh to\u00E1n';
        list.innerHTML = '<div class="empty-state">\u0110ang t\u1EA3i h\u00F3a \u0111\u01A1n...</div>';
        try {
            let url = utils.apiBase() + '/invoices?status=' + encodeURIComponent(currentStatus);
            if (keyword) {
                url += '&keyword=' + encodeURIComponent(keyword);
            }
            const data = await utils.requestJson(url);
            renderInvoices(data.invoices || []);
        } catch (error) {
            list.innerHTML = '<div class="empty-state text-danger">' + utils.escapeHtml(error.message) + '</div>';
        }
    }

    function searchInvoices() {
        setMessage('');
        const keyword = document.getElementById('billingPatientKeyword').value.trim();
        loadInvoices(currentStatus, keyword);
    }

    async function payInvoiceById(invoiceId, patientName, amount) {
        const select = document.getElementById('pm-' + invoiceId);
        const paymentMethod = select ? select.value : 'Cash';
        const methodOption = select ? select.options[select.selectedIndex] : null;
        const methodText = methodOption ? methodOption.textContent : paymentMethod;
        const confirmMsg = 'X\u00E1c nh\u1EADn thanh to\u00E1n h\u00F3a \u0111\u01A1n #' + invoiceId 
            + ' cho b\u1EC7nh nh\u00E2n ' + patientName 
            + ' v\u1EDBi s\u1ED1 ti\u1EC1n ' + utils.formatCurrency(amount) 
            + ' b\u1EB1ng ph\u01B0\u01A1ng th\u1EE9c ' + methodText + '?';
        if (!confirm(confirmMsg)) {
            return;
        }
        const body = new URLSearchParams();
        body.set('invoiceId', invoiceId);
        body.set('paymentMethod', paymentMethod);
        try {
            const data = await utils.requestJson(utils.apiBase() + '/invoices/pay', {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: body.toString()
            });
            setMessage(data.message || 'Thanh to\u00E1n th\u00E0nh c\u00F4ng.', 'success');
            await loadStats();
            await loadInvoices(currentStatus);
        } catch (error) {
            setMessage(error.message, 'danger');
        }
    }

    function printInvoice(button) {
        const statusText = button.dataset.status === 'Paid' ? '\u0110\u00E3 thanh to\u00E1n' : 'Ch\u1EDD thanh to\u00E1n';
        const html = '<!doctype html><html lang="vi"><head><meta charset="UTF-8"><title>H\u00F3a \u0111\u01A1n #'
            + utils.escapeHtml(button.dataset.invoiceId)
            + '</title><style>body{font-family:Arial,sans-serif;padding:32px;color:#10233f} .box{border:1px solid #ddd;border-radius:12px;padding:24px;max-width:680px} h1{margin-top:0} .row{display:flex;justify-content:space-between;border-bottom:1px solid #eee;padding:10px 0}.total{font-size:24px;font-weight:700}</style></head><body>'
            + '<div class="box"><h1>H\u00F3a \u0111\u01A1n #' + utils.escapeHtml(button.dataset.invoiceId) + '</h1>'
            + '<div class="row"><span>B\u1EC7nh nh\u00E2n</span><strong>' + utils.escapeHtml(button.dataset.patientName) + '</strong></div>'
            + '<div class="row"><span>S\u1ED1 \u0111i\u1EC7n tho\u1EA1i</span><strong>' + utils.escapeHtml(button.dataset.phone) + '</strong></div>'
            + '<div class="row"><span>Ng\u00E0y t\u1EA1o</span><strong>' + utils.escapeHtml(button.dataset.createdAt) + '</strong></div>'
            + '<div class="row"><span>Tr\u1EA1ng th\u00E1i</span><strong>' + utils.escapeHtml(statusText) + '</strong></div>'
            + '<div class="row total"><span>T\u1ED5ng thanh to\u00E1n</span><strong>' + utils.formatCurrency(button.dataset.finalAmount) + '</strong></div>'
            + '</div><script>window.print();<\/script></body></html>';
        const printWindow = window.open('', '_blank', 'width=800,height=720');
        if (!printWindow) {
            setMessage('Tr\u00ECnh duy\u1EC7t \u0111ang ch\u1EB7n c\u1EEDa s\u1ED5 in h\u00F3a \u0111\u01A1n.', 'warning');
            return;
        }
        printWindow.document.open();
        printWindow.document.write(html);
        printWindow.document.close();
    }

    document.querySelectorAll('[data-invoice-status]').forEach(function (button) {
        button.addEventListener('click', function () {
            loadInvoices(button.dataset.invoiceStatus);
        });
    });
    function renderInvoiceDetails(container, details) {
        if (!details || details.length === 0) {
            container.innerHTML = '<div class="text-muted p-2">Kh\u00F4ng c\u00F3 chi ti\u1EBFt d\u1ECBch v\u1EE5.</div>';
            return;
        }
        let html = '<div class="invoice-details-title">Chi ti\u1EBFt d\u1ECBch v\u1EE5 thanh to\u00E1n:</div>'
            + '<table class="invoice-details-table">'
            + '<thead><tr>'
            + '<th>T\u00EAn d\u1ECBch v\u1EE5</th>'
            + '<th class="text-center" style="width: 80px;">SL</th>'
            + '<th class="text-end" style="width: 120px;">\u0110\u01A1n gi\u00E1</th>'
            + '<th class="text-end" style="width: 150px;">Th\u00E0nh ti\u1EC1n</th>'
            + '</tr></thead>'
            + '<tbody>';

        details.forEach(function (item) {
            const itemTotal = item.quantity * item.price;
            html += '<tr>'
                + '<td>' + utils.escapeHtml(item.serviceName) + ' <span class="badge text-bg-light text-capitalize">' + utils.escapeHtml(item.serviceType === 'Examination' ? 'Kh\u00E1m b\u1EC7nh' : 'X\u00E9t nghi\u1EC7m') + '</span></td>'
                + '<td class="text-center">' + item.quantity + '</td>'
                + '<td class="text-end">' + utils.formatCurrency(item.price) + '</td>'
                + '<td class="text-end fw-semibold">' + utils.formatCurrency(itemTotal) + '</td>'
                + '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    }

    list.addEventListener('click', async function (event) {
        if (event.target.closest('.payment-method-select')) {
            return;
        }
        const payBtn = event.target.closest('.invoice-pay-btn');
        if (payBtn) {
            const invoiceId = payBtn.dataset.invoiceId;
            const patientName = payBtn.dataset.patientName;
            const amount = parseFloat(payBtn.dataset.finalAmount);
            await payInvoiceById(invoiceId, patientName, amount);
            return;
        }

        const printBtn = event.target.closest('.invoice-print');
        if (printBtn) {
            printInvoice(printBtn);
            return;
        }

        const row = event.target.closest('.invoice-row');
        if (row) {
            const invoiceId = row.dataset.invoiceId;
            const detailsDiv = document.getElementById('details-' + invoiceId);
            const toggleIcon = row.querySelector('.toggle-icon');

            if (!detailsDiv) return;

            if (detailsDiv.style.display === 'none') {
                detailsDiv.style.display = 'block';
                if (toggleIcon) {
                    toggleIcon.style.transform = 'rotate(90deg)';
                }

                if (detailsDiv.querySelector('.spinner-border')) {
                    try {
                        const data = await utils.requestJson(utils.apiBase() + '/invoices/details?invoiceId=' + encodeURIComponent(invoiceId));
                        renderInvoiceDetails(detailsDiv, data.details || []);
                    } catch (error) {
                        detailsDiv.innerHTML = '<div class="text-danger p-2">L\u1ED7i: ' + utils.escapeHtml(error.message) + '</div>';
                    }
                }
            } else {
                detailsDiv.style.display = 'none';
                if (toggleIcon) {
                    toggleIcon.style.transform = 'rotate(0deg)';
                }
            }
        }
    });
    document.getElementById('reloadInvoicesBtn').addEventListener('click', function () { loadInvoices(currentStatus); });
    document.getElementById('searchInvoiceBtn').addEventListener('click', searchInvoices);
    document.getElementById('billingPatientKeyword').addEventListener('keypress', function (e) {
        if (e.key === 'Enter') {
            searchInvoices();
        }
    });
    document.addEventListener('DOMContentLoaded', async function () {
        await loadStats().catch(console.error);
        await loadInvoices('Pending');
    });
})();
