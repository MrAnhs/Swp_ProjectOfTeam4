(function () {
    function apiBase() {
        return window.ReceptionistConfig && window.ReceptionistConfig.apiBase
            ? window.ReceptionistConfig.apiBase
            : '';
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function formatCurrency(value) {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND',
            maximumFractionDigits: 0
        }).format(Number(value || 0));
    }

    async function requestJson(url, options) {
        const response = await fetch(url, Object.assign({
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
        }, options || {}));
        const data = await response.json().catch(() => ({}));
        if (!response.ok || data.success === false || data.error) {
            throw new Error(data.error || data.message || ('HTTP ' + response.status));
        }
        return data;
    }

    window.ReceptionistUtils = {
        apiBase,
        escapeHtml,
        formatCurrency,
        requestJson
    };
})();
