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
            list.innerHTML = '<div class="empty-state">Không có hóa đơn phù hợp.</div>';
            return;
        }
        list.innerHTML = invoices.map(function (invoice) {
            return '<div class="invoice-card" id="card-' + utils.escapeHtml(invoice.invoiceId) + '">'
                + '<div class="invoice-row" style="cursor: pointer;" data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '">'
                + '<div><div class="fw-bold"><i class="bi bi-chevron-right me-2 text-primary toggle-icon" style="display: inline-block;"></i>Hóa đơn #' + utils.escapeHtml(invoice.invoiceId) + ' - ' + utils.escapeHtml(invoice.patientName) + '</div>'
                + '<div class="muted-text">' + utils.escapeHtml(invoice.phone) + ' | Ngày tạo: ' + utils.escapeHtml(invoice.createdAt) + '</div></div>'
                + '<div class="text-end"><div class="fw-bold">' + utils.formatCurrency(invoice.finalAmount) + '</div>'
                + '<span class="badge ' + (invoice.status === 'Paid' ? 'text-bg-success' : 'text-bg-warning') + '">' + utils.escapeHtml(invoice.status === 'Paid' ? 'Đã thanh toán' : 'Chờ thanh toán') + '</span>'
                + (invoice.status === 'Paid'
                    ? '<div><button class="btn btn-sm btn-outline-primary mt-2 invoice-print"'
                    + ' data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '"'
                    + ' data-patient-name="' + utils.escapeHtml(invoice.patientName) + '"'
                    + ' data-phone="' + utils.escapeHtml(invoice.phone) + '"'
                    + ' data-created-at="' + utils.escapeHtml(invoice.createdAt) + '"'
                    + ' data-final-amount="' + utils.escapeHtml(invoice.finalAmount) + '"'
                    + ' data-status="' + utils.escapeHtml(invoice.status) + '">In hóa đơn</button></div>'
                    : '<div class="d-flex align-items-center justify-content-end gap-2 mt-2">'
                    + '<select class="form-select form-select-sm invoice-pay-method" style="width:130px;" id="pay-method-' + utils.escapeHtml(invoice.invoiceId) + '">'
                    + '<option value="Cash">Tiền mặt</option>'
                    + '<option value="VNPay">VNPay</option>'
                    + '</select>'
                    + '<button class="btn btn-sm btn-success invoice-pay-btn"'
                    + ' data-invoice-id="' + utils.escapeHtml(invoice.invoiceId) + '"'
                    + ' data-patient-name="' + utils.escapeHtml(invoice.patientName) + '"'
                    + ' data-final-amount="' + utils.escapeHtml(invoice.finalAmount) + '">Xác nhận thanh toán</button>'
                    + '</div>')
                + '</div></div>'
                + '<div class="invoice-details" id="details-' + utils.escapeHtml(invoice.invoiceId) + '" style="display: none;">'
                + '<div class="text-center py-2"><div class="spinner-border spinner-border-sm text-primary" role="status"></div> Đang tải chi tiết...</div>'
                + '</div>'
                + '</div>';
        }).join('');
    }

    async function loadInvoices(status, keyword) {
        currentStatus = status || currentStatus;
        const searchKeyword = typeof keyword === 'string'
            ? keyword
            : (document.getElementById('billingPatientKeyword') ? document.getElementById('billingPatientKeyword').value.trim() : '');
        document.getElementById('invoiceListTitle').textContent = currentStatus === 'Paid'
            ? 'Hóa đơn đã thanh toán'
            : 'Hóa đơn chờ thanh toán';
        list.innerHTML = '<div class="empty-state">Đang tải hóa đơn...</div>';
        try {
            let url = utils.apiBase() + '/invoices?status=' + encodeURIComponent(currentStatus);
            if (searchKeyword) {
                url += '&keyword=' + encodeURIComponent(searchKeyword);
            }
            const data = await utils.requestJson(url);
            renderInvoices(data.invoices || []);
        } catch (error) {
            list.innerHTML = '<div class="empty-state text-danger">' + utils.escapeHtml(error.message) + '</div>';
        }
    }

    async function payInvoiceById(invoiceId, patientName, amount, paymentMethod) {
        const methodText = paymentMethod === 'VNPay' ? 'VNPay' : 'Tiền mẶt';
        const confirmMsg = 'Xác nhận thanh toán hóa đơn #' + invoiceId
            + ' cho bệnh nhân ' + patientName
            + ' với số tiền ' + utils.formatCurrency(amount)
            + ' bằng phương thức ' + methodText + '?';
        if (!confirm(confirmMsg)) {
            return;
        }
        const body = new URLSearchParams();
        body.set('invoiceId', invoiceId);
        body.set('paymentMethod', paymentMethod || 'Cash');
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
            setMessage(data.message || 'Thanh toán thành công.', 'success');
            await loadStats();
            await loadInvoices(currentStatus);
        } catch (error) {
            setMessage(error.message, 'danger');
        }
    }

    function printInvoice(button) {
        const statusText = button.dataset.status === 'Paid' ? 'Đã thanh toán' : 'Chờ thanh toán';
        const html = '<!doctype html><html lang="vi"><head><meta charset="UTF-8"><title>Hóa đơn #'
            + utils.escapeHtml(button.dataset.invoiceId)
            + '</title><style>body{font-family:Arial,sans-serif;padding:32px;color:#10233f} .box{border:1px solid #ddd;border-radius:12px;padding:24px;max-width:680px} h1{margin-top:0} .row{display:flex;justify-content:space-between;border-bottom:1px solid #eee;padding:10px 0}.total{font-size:24px;font-weight:700}</style></head><body>'
            + '<div class="box"><h1>Hóa đơn #' + utils.escapeHtml(button.dataset.invoiceId) + '</h1>'
            + '<div class="row"><span>Bệnh nhân</span><strong>' + utils.escapeHtml(button.dataset.patientName) + '</strong></div>'
            + '<div class="row"><span>Số điện thoại</span><strong>' + utils.escapeHtml(button.dataset.phone) + '</strong></div>'
            + '<div class="row"><span>Ngày tạo</span><strong>' + utils.escapeHtml(button.dataset.createdAt) + '</strong></div>'
            + '<div class="row"><span>Trạng thái</span><strong>' + utils.escapeHtml(statusText) + '</strong></div>'
            + '<div class="row total"><span>Tổng thanh toán</span><strong>' + utils.formatCurrency(button.dataset.finalAmount) + '</strong></div>'
            + '</div><script>window.print();<\/script></body></html>';
        const printWindow = window.open('', '_blank', 'width=800,height=720');
        if (!printWindow) {
            setMessage('Trình duyệt đang chặn cửa sổ in hóa đơn.', 'warning');
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
            container.innerHTML = '<div class="text-muted p-2">Không có chi tiết dịch vụ.</div>';
            return;
        }
        let html = '<div class="invoice-details-title">Chi tiết dịch vụ thanh toán:</div>'
            + '<table class="invoice-details-table">'
            + '<thead><tr>'
            + '<th>Tên dịch vụ</th>'
            + '<th class="text-center" style="width: 80px;">SL</th>'
            + '<th class="text-end" style="width: 120px;">Đơn giá</th>'
            + '<th class="text-end" style="width: 150px;">Thành tiền</th>'
            + '</tr></thead>'
            + '<tbody>';

        details.forEach(function (item) {
            const itemTotal = item.quantity * item.price;
            html += '<tr>'
                + '<td>' + utils.escapeHtml(item.serviceName) + ' <span class="badge text-bg-light text-capitalize">' + utils.escapeHtml(item.serviceType === 'Examination' ? 'Khám bệnh' : 'Xét nghiệm') + '</span></td>'
                + '<td class="text-center">' + item.quantity + '</td>'
                + '<td class="text-end">' + utils.formatCurrency(item.price) + '</td>'
                + '<td class="text-end fw-semibold">' + utils.formatCurrency(itemTotal) + '</td>'
                + '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    }

    list.addEventListener('click', async function (event) {
        const payMethodSelect = event.target.closest('.invoice-pay-method');
        if (payMethodSelect) {
            return;
        }

        const payBtn = event.target.closest('.invoice-pay-btn');
        if (payBtn) {
            const invoiceId = payBtn.dataset.invoiceId;
            const patientName = payBtn.dataset.patientName;
            const amount = parseFloat(payBtn.dataset.finalAmount);
            const selectElem = document.getElementById('pay-method-' + invoiceId);
            const paymentMethod = selectElem ? selectElem.value : 'Cash';
            await payInvoiceById(invoiceId, patientName, amount, paymentMethod);
            return;
        }

        const printBtn = event.target.closest('.invoice-print');
        if (printBtn) {
            event.stopPropagation();
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
                        detailsDiv.innerHTML = '<div class="text-danger p-2">Lỗi: ' + utils.escapeHtml(error.message) + '</div>';
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

    const searchBtn = document.getElementById('searchInvoiceBtn');
    if (searchBtn) {
        searchBtn.addEventListener('click', function () {
            const kw = document.getElementById('billingPatientKeyword').value.trim();
            loadInvoices(currentStatus, kw);
        });
    }

    const keywordInput = document.getElementById('billingPatientKeyword');
    if (keywordInput) {
        keywordInput.addEventListener('keyup', function (e) {
            if (e.key === 'Enter') {
                loadInvoices(currentStatus, keywordInput.value.trim());
            }
        });
    }

    document.addEventListener('DOMContentLoaded', async function () {
        await loadStats().catch(console.error);
        await loadInvoices('Pending');
    });
})();
