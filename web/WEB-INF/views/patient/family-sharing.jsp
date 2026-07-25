<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chia sẻ hồ sơ gia đình - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
    <style>
        .fs-container { max-width: 1100px; margin: 0 auto; padding-bottom: 2rem; }
        .fs-card { background: var(--bg-card, #ffffff) !important; border-radius: var(--radius-card, 16px); box-shadow: var(--card-shadow, 0 2px 16px rgba(0,0,0,0.06)); padding: 1.5rem; margin-bottom: 1.5rem; border: 1px solid var(--border-color, #e8ecf0) !important; color: var(--text-primary, #1a202c) !important; }
        .fs-nav-tabs { display: flex; gap: 1rem; border-bottom: 2px solid var(--border-color, #e8ecf0); margin-bottom: 1.5rem; }
        .fs-tab-btn { background: none; border: none; padding: 0.75rem 1.25rem; font-weight: 600; color: var(--text-secondary, #64748b); font-size: 1.05rem; cursor: pointer; position: relative; transition: all 0.2s; }
        .fs-tab-btn:hover { color: var(--primary, #00C8A5); }
        .fs-tab-btn.active { color: var(--primary, #00C8A5); }
        .fs-tab-btn.active::after { content: ''; position: absolute; bottom: -2px; left: 0; right: 0; height: 3px; background-color: var(--primary, #00C8A5); border-radius: 3px 3px 0 0; }
        .fs-tab-content { display: none; }
        .fs-tab-content.active { display: block; }
        
        .fs-form-row { display: flex; gap: 1rem; flex-wrap: wrap; align-items: flex-end; }
        .fs-form-group { flex: 1; min-width: 250px; }
        .fs-form-group label { display: block; font-weight: 600; margin-bottom: 0.4rem; color: var(--text-secondary, #64748b) !important; }
        .fs-form-control { width: 100%; padding: 0.6rem 0.9rem; border: 1px solid var(--border-color, #e8ecf0) !important; border-radius: 8px; font-size: 0.95rem; background: var(--bg-page, #f8fafc) !important; color: var(--text-primary, #1a202c) !important; }
        .fs-form-control:focus { outline: none; border-color: var(--primary, #00C8A5) !important; box-shadow: 0 0 0 3px rgba(0, 200, 165, 0.15); }
        
        .fs-checkbox-group { display: flex; gap: 1.25rem; align-items: center; padding: 0.6rem 0; flex-wrap: wrap; }
        .fs-checkbox-label { display: flex; align-items: center; gap: 0.4rem; font-weight: 500; font-size: 0.92rem; cursor: pointer; color: var(--text-primary, #1a202c) !important; }
        
        .fs-btn { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.6rem 1.2rem; border-radius: 20px; font-weight: 600; border: none; cursor: pointer; transition: all 0.2s; font-size: 0.92rem; }
        .fs-btn-primary { background: linear-gradient(135deg, #00C8A5, #009688) !important; color: #fff !important; box-shadow: 0 3px 10px rgba(0, 200, 165, 0.25) !important; }
        .fs-btn-primary:hover { transform: translateY(-1px); }
        .fs-btn-success { background: #198754; color: #fff; }
        .fs-btn-success:hover { background: #157347; }
        .fs-btn-danger { background: #dc3545; color: #fff; }
        .fs-btn-danger:hover { background: #bb2d3b; }
        .fs-btn-secondary { background: #f1f5f9 !important; color: #475569 !important; border: 1px solid #e2e8f0 !important; }
        .fs-btn-secondary:hover { background: #e2e8f0 !important; }
        .fs-btn-outline-danger { background: transparent; border: 1px solid #dc3545; color: #dc3545; }
        .fs-btn-outline-danger:hover { background: #dc3545; color: #fff; }
        .fs-btn-outline-primary { background: transparent; border: 1px solid #2AB5A3; color: #2AB5A3; }
        .fs-btn-outline-primary:hover { background: #2AB5A3; color: #fff; }
        
        .fs-list-table { width: 100%; border-collapse: separate; border-spacing: 0; margin-top: 1rem; }
        .fs-list-table th, .fs-list-table td { padding: 0.9rem 1rem; text-align: left; border-bottom: 1px solid #eef2f5; font-size: 0.95rem; }
        .fs-list-table th { background-color: #f8f9fa; font-weight: 600; color: #495057; }
        
        .fs-badge { display: inline-block; padding: 0.35rem 0.65rem; border-radius: 20px; font-size: 0.82rem; font-weight: 600; }
        .fs-badge-pending { background-color: #fff3cd; color: #664d03; }
        .fs-badge-accepted { background-color: #d1e7dd; color: #0f5132; }
        .fs-badge-rejected { background-color: #f8d7da; color: #842029; }
        
        .fs-modal-backdrop { fixed: inset 0; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 9999; }
        .fs-modal-backdrop[hidden] { display: none; }
        .fs-modal-box { background: #fff; border-radius: 12px; max-width: 450px; width: 90%; padding: 1.5rem; box-shadow: 0 10px 25px rgba(0,0,0,0.2); }
        .fs-modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; border-bottom: 1px solid #eee; padding-bottom: 0.75rem; }
        .fs-modal-title { font-weight: 700; font-size: 1.1rem; color: #333; margin: 0; }
        .fs-modal-body { margin-bottom: 1.25rem; }
        .fs-modal-footer { display: flex; justify-content: flex-end; gap: 0.75rem; }
        
        .fs-toast { position: fixed; top: 20px; right: 20px; z-index: 10000; padding: 1rem 1.25rem; border-radius: 8px; color: #fff; font-weight: 600; box-shadow: 0 4px 12px rgba(0,0,0,0.15); display: flex; align-items: center; gap: 0.5rem; transition: opacity 0.3s; }
        .fs-toast-success { background: #198754; }
        .fs-toast-error { background: #dc3545; }
    </style>
</head>
<body>
    <c:set var="activePatientPage" value="family-sharing" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <div class="fs-container">
            <header class="page-header mb-4">
                <div>
                    <p class="page-eyebrow">QUẢN LÝ GIA ĐÌNH</p>
                    <h1>Chia sẻ hồ sơ y tế gia đình</h1>
                    <p>Kết nối và theo dõi chỉ số sức khỏe, lịch khám và hóa đơn của người thân trong gia đình.</p>
                </div>
            </header>

            <div class="fs-card">
                <!-- Navigation Tabs -->
                <div class="fs-nav-tabs">
                    <button type="button" class="fs-tab-btn active" onclick="switchTab('tab1')">
                        <i class="bi bi-person-check-fill"></i> Người tôi theo dõi
                    </button>
                    <button type="button" class="fs-tab-btn" onclick="switchTab('tab2')">
                        <i class="bi bi-people-fill"></i> Người theo dõi tôi
                    </button>
                </div>

                <!-- TAB 1: Người tôi theo dõi (Viewer_AccountID = CurrentUser) -->
                <div id="tab1" class="fs-tab-content active">
                    <div class="fs-card" style="background: #f8f9fa; border-color: #e2e8f0;">
                        <h3 class="h6 font-weight-bold mb-3"><i class="bi bi-person-plus"></i> Xin phép theo dõi người khác</h3>
                        <form id="formRequestFollow" onsubmit="handleRequestFollow(event)">
                            <div class="fs-form-row">
                                <div class="fs-form-group">
                                    <label for="reqEmail">Nhập Email người thân:</label>
                                    <input type="email" id="reqEmail" class="fs-form-control" placeholder="vi-du: nguoi-than@gmail.com" required>
                                </div>
                                <div>
                                    <button type="submit" class="fs-btn fs-btn-primary">
                                        <i class="bi bi-send"></i> Gửi yêu cầu xin phép
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>

                    <h3 class="h6 font-weight-bold mt-4 mb-2">Danh sách người tôi theo dõi</h3>
                    <div class="table-responsive">
                        <table class="fs-list-table">
                            <thead>
                                <tr>
                                    <th>Họ và tên người thân</th>
                                    <th>Email</th>
                                    <th>Trạng thái</th>
                                    <th>Hành động</th>
                                </tr>
                            </thead>
                            <tbody id="followingTableBody">
                                <tr><td colspan="4" class="text-center py-4">Đang tải dữ liệu...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 2: Người theo dõi tôi (Owner_AccountID = CurrentUser) -->
                <div id="tab2" class="fs-tab-content">
                    <div class="fs-card" style="background: #f8f9fa; border-color: #e2e8f0;">
                        <h3 class="h6 font-weight-bold mb-3"><i class="bi bi-share"></i> Mời người khác theo dõi hồ sơ của tôi</h3>
                        <form id="formInviteFollow" onsubmit="handleInviteFollow(event)">
                            <div class="fs-form-row mb-3">
                                <div class="fs-form-group">
                                    <label for="invEmail">Nhập Email người nhận lời mời:</label>
                                    <input type="email" id="invEmail" class="fs-form-control" placeholder="vi-du: con-cai@gmail.com" required>
                                </div>
                                <div>
                                    <button type="submit" class="fs-btn fs-btn-primary">
                                        <i class="bi bi-person-plus-fill"></i> Gửi lời mời chia sẻ
                                    </button>
                                </div>
                            </div>
                            <div class="fs-checkbox-group">
                                <span class="fw-semibold me-2" style="font-size: 0.95rem;">Cấp quyền xem:</span>
                                <label class="fs-checkbox-label">
                                    <input type="checkbox" id="invAppts" checked> Lịch hẹn khám
                                </label>
                                <label class="fs-checkbox-label">
                                    <input type="checkbox" id="invInvoices" checked> Hóa đơn thanh toán
                                </label>
                                <label class="fs-checkbox-label">
                                    <input type="checkbox" id="invRecords" checked> Hồ sơ bệnh án
                                </label>
                            </div>
                        </form>
                    </div>

                    <h3 class="h6 font-weight-bold mt-4 mb-2">Danh sách người đang theo dõi tôi</h3>
                    <div class="table-responsive">
                        <table class="fs-list-table">
                            <thead>
                                <tr>
                                    <th>Họ và tên người nhận</th>
                                    <th>Email</th>
                                    <th>Trạng thái & Quyền hạn</th>
                                    <th>Hành động</th>
                                </tr>
                            </thead>
                            <tbody id="followersTableBody">
                                <tr><td colspan="4" class="text-center py-4">Đang tải dữ liệu...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <!-- MODAL ĐỒNG Ý DÀNH CHO TAB 2 (CẤU HÌNH QUYỀN TRƯỚC KHI ĐỒNG Ý) -->
    <div id="permissionModal" class="fs-modal-backdrop" hidden>
        <div class="fs-modal-box">
            <div class="fs-modal-header">
                <h3 class="fs-modal-title"><i class="bi bi-shield-lock"></i> Cấu hình quyền chia sẻ</h3>
                <button type="button" style="background:none;border:none;font-size:1.2rem;cursor:pointer;" onclick="closePermissionModal()">&times;</button>
            </div>
            <div class="fs-modal-body">
                <p class="mb-3 text-secondary" style="font-size:0.92rem;">Vui lòng chọn các quyền bạn cho phép người này xem trong hồ sơ y tế của bạn:</p>
                <input type="hidden" id="modalSharingId">
                <div class="d-flex flex-column gap-2">
                    <label class="fs-checkbox-label">
                        <input type="checkbox" id="modalCheckAppts" checked> Quyền xem Lịch hẹn khám
                    </label>
                    <label class="fs-checkbox-label">
                        <input type="checkbox" id="modalCheckInvoices" checked> Quyền xem Hóa đơn thanh toán
                    </label>
                    <label class="fs-checkbox-label">
                        <input type="checkbox" id="modalCheckRecords" checked> Quyền xem Hồ sơ bệnh án
                    </label>
                </div>
            </div>
            <div class="fs-modal-footer">
                <button type="button" class="fs-btn fs-btn-secondary" onclick="closePermissionModal()">Hủy</button>
                <button type="button" class="fs-btn fs-btn-success" onclick="submitPermissionAccept()">
                    <i class="bi bi-check-circle"></i> Xác nhận đồng ý
                </button>
            </div>
        </div>
    </div>

    <!-- Toast message container -->
    <div id="fsToast" class="fs-toast" style="display: none;"></div>

    <script>
        const API_URL = '${pageContext.request.contextPath}/patient/api/family-sharing';
        let currentUserId = 0;

        document.addEventListener('DOMContentLoaded', () => {
            loadSharingData();
        });

        function switchTab(tabId) {
            document.querySelectorAll('.fs-tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.fs-tab-content').forEach(content => content.classList.remove('active'));

            if (tabId === 'tab1') {
                document.querySelectorAll('.fs-tab-btn')[0].classList.add('active');
                document.getElementById('tab1').classList.add('active');
            } else {
                document.querySelectorAll('.fs-tab-btn')[1].classList.add('active');
                document.getElementById('tab2').classList.add('active');
            }
        }

        function showToast(message, isSuccess = true) {
            const toast = document.getElementById('fsToast');
            toast.className = 'fs-toast ' + (isSuccess ? 'fs-toast-success' : 'fs-toast-error');
            toast.innerHTML = (isSuccess ? '<i class="bi bi-check-circle-fill"></i> ' : '<i class="bi bi-exclamation-triangle-fill"></i> ') + message;
            toast.style.display = 'flex';
            setTimeout(() => { toast.style.display = 'none'; }, 3500);
        }

        async function loadSharingData() {
            try {
                const res = await fetch(API_URL);
                const data = await res.json();
                if (data.success) {
                    currentUserId = data.currentUserId;
                    renderTab1(data.following || []);
                    renderTab2(data.followers || []);
                } else {
                    showToast(data.message || 'Không thể tải dữ liệu.', false);
                }
            } catch (e) {
                console.error(e);
                showToast('Lỗi hệ thống khi tải dữ liệu.', false);
            }
        }

        // Render TAB 1: Người tôi theo dõi (Viewer = CurrentUser)
        function renderTab1(list) {
            const tbody = document.getElementById('followingTableBody');
            if (!list || list.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-4">Bạn chưa theo dõi hồ sơ của người thân nào.</td></tr>';
                return;
            }

            let html = '';
            list.forEach(item => {
                const isInitiatorMe = (item.initiatorAccountId === currentUserId);
                let statusBadge = '';
                let actionBtn = '';

                if (item.status === 'PENDING') {
                    if (isInitiatorMe) {
                        // Mình xin phép họ -> Đang chờ họ duyệt
                        statusBadge = '<span class="fs-badge fs-badge-pending"><i class="bi bi-clock"></i> Đang chờ duyệt...</span>';
                    } else {
                        // Họ mời mình -> Hiện nút Đồng ý / Từ chối
                        statusBadge = '<span class="fs-badge fs-badge-pending">Lời mời xem hồ sơ</span>';
                        actionBtn = `
                            <button class="fs-btn fs-btn-success" onclick="acceptInviteDirect(\${item.sharingId})"><i class="bi bi-check-lg"></i> Đồng ý</button>
                            <button class="fs-btn fs-btn-danger" onclick="rejectSharing(\${item.sharingId})"><i class="bi bi-x-lg"></i> Từ chối</button>
                        `;
                    }
                } else if (item.status === 'ACCEPTED') {
                    statusBadge = '<span class="fs-badge fs-badge-accepted"><i class="bi bi-check-circle"></i> Đã chấp nhận</span>';
                    actionBtn = `
                        <a href="${pageContext.request.contextPath}/patient/family-dashboard?ownerId=\${item.ownerAccountId}" class="fs-btn fs-btn-outline-primary">
                            <i class="bi bi-eye"></i> Xem hồ sơ
                        </a>
                    `;
                } else if (item.status === 'REJECTED') {
                    statusBadge = '<span class="fs-badge fs-badge-rejected"><i class="bi bi-x-circle"></i> Đã bị từ chối</span>';
                    actionBtn = `
                        <button class="fs-btn fs-btn-outline-danger" onclick="deleteSharing(\${item.sharingId})">
                            <i class="bi bi-trash"></i> Xóa lịch sử
                        </button>
                    `;
                }

                html += `
                    <tr>
                        <td><strong>\${escapeHtml(item.ownerName || 'Chưa cập nhật')}</strong></td>
                        <td>\${escapeHtml(item.ownerEmail)}</td>
                        <td>\${statusBadge}</td>
                        <td><div class="d-flex gap-2">\${actionBtn}</div></td>
                    </tr>
                `;
            });
            tbody.innerHTML = html;
        }

        // Render TAB 2: Người theo dõi tôi (Owner = CurrentUser)
        function renderTab2(list) {
            const tbody = document.getElementById('followersTableBody');
            if (!list || list.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-4">Chưa có ai theo dõi hồ sơ của bạn.</td></tr>';
                return;
            }

            let html = '';
            list.forEach(item => {
                const isInitiatorMe = (item.initiatorAccountId === currentUserId);
                let statusBadge = '';
                let actionBtn = '';

                if (item.status === 'PENDING') {
                    if (isInitiatorMe) {
                        // Mình mời họ -> Đang chờ họ chấp nhận
                        statusBadge = '<span class="fs-badge fs-badge-pending"><i class="bi bi-clock"></i> Đang chờ duyệt...</span>';
                    } else {
                        // Họ xin phép mình -> Hiện nút Đồng ý (Mở Modal chọn quyền) / Từ chối
                        statusBadge = '<span class="fs-badge fs-badge-pending">Xin phép xem hồ sơ</span>';
                        actionBtn = `
                            <button class="fs-btn fs-btn-success" onclick="openPermissionModal(\${item.sharingId})"><i class="bi bi-shield-check"></i> Đồng ý</button>
                            <button class="fs-btn fs-btn-danger" onclick="rejectSharing(\${item.sharingId})"><i class="bi bi-x-lg"></i> Từ chối</button>
                        `;
                    }
                } else if (item.status === 'ACCEPTED') {
                    let perms = [];
                    if (item.canViewAppointments) perms.push('Lịch hẹn');
                    if (item.canViewInvoices) perms.push('Hóa đơn');
                    if (item.canViewRecords) perms.push('Bệnh án');
                    const permStr = perms.length > 0 ? perms.join(', ') : 'Chưa có quyền';

                    statusBadge = `<span class="fs-badge fs-badge-accepted"><i class="bi bi-check-circle"></i> Đang theo dõi</span><br><small class="text-muted">Quyền: \${permStr}</small>`;
                    actionBtn = `
                        <button class="fs-btn fs-btn-outline-danger" onclick="deleteSharing(\${item.sharingId})">
                            <i class="bi bi-slash-circle"></i> Thu hồi quyền
                        </button>
                    `;
                } else if (item.status === 'REJECTED') {
                    statusBadge = '<span class="fs-badge fs-badge-rejected"><i class="bi bi-x-circle"></i> Bị từ chối</span>';
                    actionBtn = `
                        <button class="fs-btn fs-btn-outline-danger" onclick="deleteSharing(\${item.sharingId})">
                            <i class="bi bi-trash"></i> Xóa lịch sử
                        </button>
                    `;
                }

                html += `
                    <tr>
                        <td><strong>\${escapeHtml(item.viewerName || 'Chưa cập nhật')}</strong></td>
                        <td>\${escapeHtml(item.viewerEmail)}</td>
                        <td>\${statusBadge}</td>
                        <td><div class="d-flex gap-2">\${actionBtn}</div></td>
                    </tr>
                `;
            });
            tbody.innerHTML = html;
        }

        // Submit Xin phép theo dõi
        async function handleRequestFollow(e) {
            e.preventDefault();
            const email = document.getElementById('reqEmail').value;
            const params = new URLSearchParams();
            params.append('action', 'request_follow');
            params.append('email', email);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                if (data.success) {
                    showToast(data.message, true);
                    document.getElementById('formRequestFollow').reset();
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        // Submit Mời theo dõi
        async function handleInviteFollow(e) {
            e.preventDefault();
            const email = document.getElementById('invEmail').value;
            const params = new URLSearchParams();
            params.append('action', 'invite_follow');
            params.append('email', email);
            params.append('canViewAppointments', document.getElementById('invAppts').checked);
            params.append('canViewInvoices', document.getElementById('invInvoices').checked);
            params.append('canViewRecords', document.getElementById('invRecords').checked);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                if (data.success) {
                    showToast(data.message, true);
                    document.getElementById('formInviteFollow').reset();
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        // Direct Accept for Tab 1 (Viewer accepting owner's invitation)
        async function acceptInviteDirect(sharingId) {
            const params = new URLSearchParams();
            params.append('action', 'accept');
            params.append('sharingId', sharingId);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                if (data.success) {
                    showToast(data.message, true);
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        // Modal for Tab 2 (Owner configuring permissions before accepting viewer's request)
        function openPermissionModal(sharingId) {
            document.getElementById('modalSharingId').value = sharingId;
            document.getElementById('permissionModal').removeAttribute('hidden');
        }

        function closePermissionModal() {
            document.getElementById('permissionModal').setAttribute('hidden', '');
        }

        async function submitPermissionAccept() {
            const sharingId = document.getElementById('modalSharingId').value;
            const params = new URLSearchParams();
            params.append('action', 'accept');
            params.append('sharingId', sharingId);
            params.append('canViewAppointments', document.getElementById('modalCheckAppts').checked);
            params.append('canViewInvoices', document.getElementById('modalCheckInvoices').checked);
            params.append('canViewRecords', document.getElementById('modalCheckRecords').checked);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                closePermissionModal();
                if (data.success) {
                    showToast(data.message, true);
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                closePermissionModal();
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        // Reject request
        async function rejectSharing(sharingId) {
            if (!confirm('Bạn có chắc chắn muốn từ chối yêu cầu này không?')) return;
            const params = new URLSearchParams();
            params.append('action', 'reject');
            params.append('sharingId', sharingId);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                if (data.success) {
                    showToast(data.message, true);
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        // Delete sharing (Hard delete)
        async function deleteSharing(sharingId) {
            if (!confirm('Bạn có chắc chắn muốn xóa/thu hồi quyền liên kết này khỏi hệ thống?')) return;
            const params = new URLSearchParams();
            params.append('action', 'delete');
            params.append('sharingId', sharingId);

            try {
                const res = await fetch(API_URL, { method: 'POST', body: params });
                const data = await res.json();
                if (data.success) {
                    showToast(data.message, true);
                    loadSharingData();
                } else {
                    showToast(data.message, false);
                }
            } catch (err) {
                showToast('Lỗi kết nối máy chủ.', false);
            }
        }

        function escapeHtml(str) {
            if (!str) return '';
            return str.replace(/&/g, "&amp;")
                      .replace(/</g, "&lt;")
                      .replace(/>/g, "&gt;")
                      .replace(/"/g, "&quot;")
                      .replace(/'/g, "&#039;");
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
