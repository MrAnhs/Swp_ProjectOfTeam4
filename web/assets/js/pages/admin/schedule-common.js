const adminContextPath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
const adminCsrfToken = window.AdminConfig && window.AdminConfig.csrfToken ? window.AdminConfig.csrfToken : '';
const adminLoginUrl = window.AdminConfig && window.AdminConfig.loginUrl ? window.AdminConfig.loginUrl : adminContextPath + '/login.jsp';
const adminScheduleEndpoint = window.AdminConfig && window.AdminConfig.adminEndpoint ? window.AdminConfig.adminEndpoint : adminContextPath + '/admin';

function escapeHtml(s) {
    if (!s) return '';
    return String(s).replace(/[&<>"']/g, function (c) { 
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": "&#39;" }[c]; 
    });
}

function escapeHtmlForSchedule(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

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

function getIsoDateOffset(dayOffset) {
    const date = new Date();
    date.setDate(date.getDate() + dayOffset);
    return date.toISOString().slice(0, 10);
}

function formatVietnameseDate(isoDate) {
    const parts = String(isoDate || '').split('-');
    if (parts.length !== 3) {
        return isoDate || '';
    }
    return parts[2] + '/' + parts[1] + '/' + parts[0];
}

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

function getOnlineQuotaBadge(onlineBooked, onlineQuota) {
    if (onlineBooked > onlineQuota) {
        return '<span class="badge text-bg-danger mt-1">Vượt quota online</span>';
    }
    if (onlineBooked >= onlineQuota) {
        return '<span class="badge text-bg-warning mt-1">Hết slot online</span>';
    }
    return '<span class="badge text-bg-success mt-1">Còn slot online</span>';
}

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
