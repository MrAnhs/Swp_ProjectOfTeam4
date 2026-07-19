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
            return '<div class="invoice-row">'
                + '<div><div class="fw-bold">H\u00F3a \u0111\u01A1n #' + utils.escapeHtml(invoice.invoiceId) + ' - ' + utils.escapeHtml(invoice.patientName) + '</div>'
                + '<div class="muted-text">' + utils.escapeHtml(invoice.phone) + ' | Ng\u00E0y t\u1EA1o: ' + utils.escapeHtml(invoice.createdAt) + '</div></div>'
                + '<div class="text-end"><div class="fw-bold">' + utils.formatCurrency(invoice.finalAmount) + '</div>'
                + '<span class="badge ' + (invoice.status === 'Paid' ? 'text-bg-success' : 'text-bg-warning') + '">' + utils.escapeHtml(invoice.status === 'Paid' ? '\u0110\u00E3 thanh to\u00E1n' : 'Ch\u1EDD thanh to\u00E1n') + '</span>'
                + '<div><button class="btn btn-sm btn-outline-primary mt-2 invoice-print"'
                + ' data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '"'
                + ' data-patient-name="' + utils.escapeHtml(invoice.patientName) + '"'
                + ' data-phone="' + utils.escapeHtml(invoice.phone) + '"'
                + ' data-created-at="' + utils.escapeHtml(invoice.createdAt) + '"'
                + ' data-final-amount="' + utils.escapeHtml(invoice.finalAmount) + '"'
                + ' data-status="' + utils.escapeHtml(invoice.status) + '">In h\u00F3a \u0111\u01A1n</button></div></div>'
                + '</div>';
        }).join('');
    }

    async function loadInvoices(status) {
        currentStatus = status || currentStatus;
        document.getElementById('invoiceListTitle').textContent = currentStatus === 'Paid'
            ? 'H\u00F3a \u0111\u01A1n \u0111\u00E3 thanh to\u00E1n'
            : 'H\u00F3a \u0111\u01A1n ch\u1EDD thanh to\u00E1n';
        list.innerHTML = '<div class="empty-state">\u0110ang t\u1EA3i h\u00F3a \u0111\u01A1n...</div>';
        try {
            const data = await utils.requestJson(utils.apiBase() + '/invoices?status=' + encodeURIComponent(currentStatus));
            renderInvoices(data.invoices || []);
        } catch (error) {
            list.innerHTML = '<div class="empty-state text-danger">' + utils.escapeHtml(error.message) + '</div>';
        }
    }

    async function payInvoice() {
        const patientKeyword = document.getElementById('billingPatientKeyword').value.trim();
        const paymentMethod = document.getElementById('paymentMethod').value;
        const body = new URLSearchParams();
        body.set('patientKeyword', patientKeyword);
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
    list.addEventListener('click', function (event) {
        const button = event.target.closest('.invoice-print');
        if (button) printInvoice(button);
    });
    document.getElementById('reloadInvoicesBtn').addEventListener('click', function () { loadInvoices(currentStatus); });
    document.getElementById('payInvoiceBtn').addEventListener('click', payInvoice);
    document.addEventListener('DOMContentLoaded', async function () {
        await loadStats().catch(console.error);
        await loadInvoices('Pending');
    });
})();
