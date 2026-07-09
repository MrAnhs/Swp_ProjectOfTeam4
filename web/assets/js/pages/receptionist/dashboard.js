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

    document.addEventListener('DOMContentLoaded', loadStats);
})();
