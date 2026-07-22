/**
 * =========================================================================
 * MODULE: CẤU HÌNH VÀ TIỆN ÍCH DÙNG CHUNG (COMMON CONFIG & HELPER UTILITIES)
 * =========================================================================
 * File này chứa các biến toàn cục liên quan đến cấu hình hệ thống và 
 * các hàm xử lý chuỗi, định dạng ngày tháng, hiển thị badge trạng thái.
 */

// ==========================================
// 1. CẤU HÌNH TOÀN CỤC (GLOBAL SYSTEM CONFIG)
// ==========================================
const adminContextPath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
const adminCsrfToken = window.AdminConfig && window.AdminConfig.csrfToken ? window.AdminConfig.csrfToken : '';
const adminLoginUrl = window.AdminConfig && window.AdminConfig.loginUrl ? window.AdminConfig.loginUrl : adminContextPath + '/login.jsp';
const adminScheduleEndpoint = window.AdminConfig && window.AdminConfig.adminEndpoint ? window.AdminConfig.adminEndpoint : adminContextPath + '/admin';

// ==========================================
// 2. CÁC HÀM TIỆN ÍCH AN TOÀN & ĐỊNH DẠNG (SECURITY & FORMAT HELPERS)
// ==========================================

/**
 * Mã hóa chuỗi HTML để phòng tránh tấn công XSS
 * @param {string} s - Chuỗi thô cần mã hóa
 * @returns {string} Chuỗi an toàn
 */
function escapeHtml(s) {
    if (!s) return '';
    return String(s).replace(/[&<>"']/g, function (c) { 
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": "&#39;" }[c]; 
    });
}

/**
 * Mã hóa chuỗi HTML dùng riêng cho in-place rendering ca trực
 * @param {string} text 
 * @returns {string}
 */
function escapeHtmlForSchedule(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Hiển thị hộp thông báo tạm thời góc màn hình rồi tự tắt sau 3 giây
 * @param {string} message - Nội dung thông báo
 * @param {string} type - Loại thông báo (success / danger / warning / info)
 */
function showTempAlert(message, type) {
    const div = document.createElement('div');
    div.className = 'alert alert-' + (type || 'info');
    div.textContent = message;
    const container = document.querySelector('.admin-content-col');
    if (container) {
        container.insertAdjacentElement('afterbegin', div);
        setTimeout(() => div.remove(), 3000);
    }
}

/**
 * Lấy chuỗi định dạng ISO YYYY-MM-DD với một khoảng lệch ngày so với hôm nay
 * @param {number} dayOffset - Số ngày lệch (dương là tương lai, âm là quá khứ)
 * @returns {string} YYYY-MM-DD
 */
function getIsoDateOffset(dayOffset) {
    const date = new Date();
    date.setDate(date.getDate() + dayOffset);
    return date.toISOString().slice(0, 10);
}

/**
 * Chuyển đổi định dạng ngày ISO (YYYY-MM-DD) sang định dạng hiển thị Việt Nam (DD/MM/YYYY)
 * @param {string} isoDate - YYYY-MM-DD
 * @returns {string} DD/MM/YYYY
 */
function formatVietnameseDate(isoDate) {
    const parts = String(isoDate || '').split('-');
    if (parts.length !== 3) {
        return isoDate || '';
    }
    return parts[2] + '/' + parts[1] + '/' + parts[0];
}


// ==========================================
// 3. LOGIC TÍNH TOÁN & HIỂN THỊ BADGE ĐẶT HÈN
// ==========================================

/**
 * Tính toán quota đặt hẹn online mặc định (khoảng 60% tổng công suất ca khám)
 * @param {number} maxPatients - Số bệnh nhân tối đa của ca trực
 * @returns {number} Slot online tối đa
 */
function calculateDefaultOnlineQuota(maxPatients) {
    if (maxPatients <= 1) {
        return Math.max(0, maxPatients);
    }
    let quota = Math.ceil(maxPatients * 0.6);
    if (quota >= maxPatients) {
        quota = maxPatients - 1;
    }
    return Math.max(1, quota);
}

/**
 * Trả về Badge HTML thể hiện tình trạng slot đặt hẹn online còn hay hết
 * @param {number} onlineBooked - Số slot online đã đặt
 * @param {number} onlineQuota - Quota online tối đa
 * @returns {string} Badge HTML
 */
function getOnlineQuotaBadge(onlineBooked, onlineQuota) {
    if (onlineBooked > onlineQuota) {
        return '<span class="badge text-bg-danger mt-1">Vượt quota online</span>';
    }
    if (onlineBooked >= onlineQuota) {
        return '<span class="badge text-bg-warning mt-1">Hết slot online</span>';
    }
    return '<span class="badge text-bg-success mt-1">Còn slot online</span>';
}

/**
 * Trả về Badge HTML thể hiện nguồn gốc của lượt đặt khám
 * @param {string} source - Nguồn đặt lịch (Online, Receptionist, Walk_In...)
 * @returns {string} Badge HTML
 */
function getBookingSourceBadge(source) {
    const normalized = (source || '').toString().trim();
    const sourceMap = {
        'Online': '<span class="badge text-bg-success"><i class="bi bi-globe2 me-1"></i>Online</span>',
        'Receptionist': '<span class="badge text-bg-primary"><i class="bi bi-person-badge me-1"></i>Lễ tân</span>',
        'Admin': '<span class="badge text-bg-dark"><i class="bi bi-shield-lock me-1"></i>Admin</span>',
        'Walk_In': '<span class="badge text-bg-warning text-dark"><i class="bi bi-door-open me-1"></i>Walk-in</span>',
        'Emergency_Routing': '<span class="badge text-bg-danger"><i class="bi bi-lightning-charge me-1"></i>Điều phối</span>'
    };
    if (!normalized) {
        return '<span class="badge text-bg-secondary">Không rõ</span>';
    }
    return sourceMap[normalized] || '<span class="badge text-bg-secondary">' + escapeHtmlForSchedule(normalized) + '</span>';
}

/**
 * Bản đồ ánh xạ tên chuyên khoa hiển thị sang mã chuyên khoa DB
 */
const departmentMapping = {
    'Nội tiết - Tiểu đường': 'Endocrinology',
    'Endocrinology': 'Endocrinology',
    'Tim mạch': 'Cardiology',
    'Cardiology': 'Cardiology',
    'Thận học': 'Nephrology',
    'Nephrology': 'Nephrology',
    'Tổng quát': 'General',
    'General': 'General'
};
