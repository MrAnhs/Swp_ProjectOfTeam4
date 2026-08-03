(function () {
    // Các hàm tiện ích dùng chung cho phân hệ Lễ tân (gọi API, định dạng tiền, tránh XSS)
    
    // Lấy đường dẫn API gốc từ cấu hình của trang
    function apiBase() {
        return window.ReceptionistConfig && window.ReceptionistConfig.apiBase
            ? window.ReceptionistConfig.apiBase
            : '';
    }

    // Tránh lỗ hổng bảo mật XSS bằng cách chuyển đổi các ký tự HTML đặc biệt
    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    // Định dạng số thành tiền tệ VND (ví dụ: 150000 -> 150.000 ₫)
    function formatCurrency(value) {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND',
            maximumFractionDigits: 0
        }).format(Number(value || 0));
    }

    // Gửi yêu cầu HTTP Fetch dạng JSON lên Server và bắt lỗi tự động
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

    // Xuất các hàm tiện ích này ra đối tượng toàn cục window.ReceptionistUtils
    window.ReceptionistUtils = {
        apiBase,
        escapeHtml,
        formatCurrency,
        requestJson
    };
})();
