<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>H&#7891; s&#417; ng&#432;&#7901;i th&#226;n - DiabetesCare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/base/variables.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/layouts/patient-shell.css?v=20260721-ui2">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/pages/patient/patient-pages.css?v=20260721-ui2">
    <style>
        .fd-container { max-width: 1100px; margin: 0 auto; padding-bottom: 2rem; }
        .fd-header-card { background: linear-gradient(135deg, #00C8A5 0%, #009688 100%); color: #fff; border-radius: 16px; padding: 1.75rem; margin-bottom: 1.5rem; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 4px 15px rgba(0,200,165,0.3); }
        .fd-header-info h2 { font-weight: 700; margin: 0 0 0.4rem 0; font-size: 1.5rem; }
        .fd-header-info p { margin: 0; opacity: 0.9; font-size: 0.95rem; }
        .fd-back-btn { background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); color: #fff; padding: 0.5rem 1rem; border-radius: 20px; font-weight: 600; text-decoration: none; display: inline-flex; align-items: center; gap: 0.4rem; transition: all 0.2s; }
        .fd-back-btn:hover { background: #fff; color: #007f61; }
        
        .fd-card { background: var(--bg-card, #ffffff) !important; border-radius: var(--radius-card, 16px); box-shadow: var(--card-shadow, 0 2px 16px rgba(0,0,0,0.06)); padding: 1.5rem; border: 1px solid var(--border-color, #e8ecf0) !important; color: var(--text-primary, #1a202c) !important; }
        
        .fd-tabs-nav { display: flex; gap: 1rem; border-bottom: 2px solid var(--border-color, #e8ecf0); margin-bottom: 1.5rem; flex-wrap: wrap; }
        .fd-tab-item { background: none; border: none; padding: 0.9rem 1.5rem; font-weight: 600; color: var(--text-secondary, #64748b); font-size: 1.05rem; cursor: pointer; position: relative; transition: all 0.2s; display: inline-flex; align-items: center; gap: 0.5rem; }
        .fd-tab-item:hover:not(.disabled) { color: var(--primary, #00C8A5); }
        .fd-tab-item.active { color: var(--primary, #00C8A5); }
        .fd-tab-item.active::after { content: ''; position: absolute; bottom: -2px; left: 0; right: 0; height: 3px; background-color: var(--primary, #00C8A5); border-radius: 3px 3px 0 0; }
        
        .fd-tab-item.disabled { opacity: 0.45; cursor: not-allowed; position: relative; }
        .fd-tab-item.disabled small { display: block; font-size: 0.72rem; color: #dc3545; font-weight: 500; margin-top: 0.1rem; }

        .fd-pane { display: none; }
        .fd-pane.active { display: block; }
        
        .fd-table { width: 100%; border-collapse: separate; border-spacing: 0; }
        .fd-table th, .fd-table td { padding: 0.9rem 1rem; text-align: left; border-bottom: 1px solid #eef2f5; font-size: 0.95rem; }
        .fd-table th { background-color: #f8f9fa; font-weight: 600; color: #495057; }
        
        .fd-badge { display: inline-block; padding: 0.35rem 0.65rem; border-radius: 20px; font-size: 0.82rem; font-weight: 600; }
        .fd-badge-green { background-color: #d1e7dd; color: #0f5132; }
        .fd-badge-yellow { background-color: #fff3cd; color: #664d03; }
        .fd-badge-red { background-color: #f8d7da; color: #842029; }
        
        .fd-loading { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 3rem 0; color: #6c757d; gap: 0.75rem; }
        .fd-spinner { width: 2.5rem; height: 2.5rem; border: 3px solid #eef2f5; border-top-color: #0d6efd; border-radius: 50%; animation: fd-spin 0.8s linear infinite; }
        @keyframes fd-spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <c:set var="activePatientPage" value="family-sharing" />
    <%@ include file="/WEB-INF/views/components/patient/sidebar.jspf" %>

    <main class="main-content-dash">
        <div class="fd-container">
            <!-- Header nổi bật hiển thị thông tin người thân -->
            <div class="fd-header-card">
                <div class="fd-header-info">
                    <p class="text-uppercase tracking-wider fw-bold small text-white-50" style="letter-spacing: 1px;">ĐANG THEO DÕI HỒ SƠ CỦA</p>
                    <h2><i class="bi bi-person-fill"></i> <c:out value="${sharing.ownerName}" /></h2>
                    <p><i class="bi bi-envelope"></i> <c:out value="${sharing.ownerEmail}" /></p>
                </div>
                <a href="${pageContext.request.contextPath}/patient/family-sharing" class="fd-back-btn">
                    <i class="bi bi-arrow-left"></i> Quay lại
                </a>
            </div>

            <div class="fd-card">
                <c:set var="hasApptPerm" value="${sharing.canViewAppointments}" />
                <c:set var="hasInvoicePerm" value="${sharing.canViewInvoices}" />
                <c:set var="hasRecordPerm" value="${sharing.canViewRecords}" />

                <!-- Navigation Tabs có logic kiểm tra quyền -->
                <div class="fd-tabs-nav">
                    <!-- Tab Lịch Hẹn -->
                    <c:choose>
                        <c:when test="${hasApptPerm}">
                            <button type="button" class="fd-tab-item active" id="btn-appointments" onclick="switchPane('appointments')">
                                <i class="bi bi-calendar-check"></i> Lịch hẹn khám
                            </button>
                        </c:when>
                        <c:otherwise>
                            <button type="button" class="fd-tab-item disabled" title="Không có quyền truy cập">
                                <i class="bi bi-calendar-x"></i> Lịch hẹn khám
                                <small><i class="bi bi-lock-fill"></i> Chưa cấp quyền</small>
                            </button>
                        </c:otherwise>
                    </c:choose>

                    <!-- Tab Hóa Đơn -->
                    <c:choose>
                        <c:when test="${hasInvoicePerm}">
                            <button type="button" class="fd-tab-item ${!hasApptPerm ? 'active' : ''}" id="btn-invoices" onclick="switchPane('invoices')">
                                <i class="bi bi-receipt"></i> Hóa đơn thanh toán
                            </button>
                        </c:when>
                        <c:otherwise>
                            <button type="button" class="fd-tab-item disabled" title="Không có quyền truy cập">
                                <i class="bi bi-receipt-cutoff"></i> Hóa đơn thanh toán
                                <small><i class="bi bi-lock-fill"></i> Chưa cấp quyền</small>
                            </button>
                        </c:otherwise>
                    </c:choose>

                    <!-- Tab Bệnh Án -->
                    <c:choose>
                        <c:when test="${hasRecordPerm}">
                            <button type="button" class="fd-tab-item ${!hasApptPerm && !hasInvoicePerm ? 'active' : ''}" id="btn-records" onclick="switchPane('records')">
                                <i class="bi bi-file-earmark-medical"></i> Hồ sơ bệnh án
                            </button>
                        </c:when>
                        <c:otherwise>
                            <button type="button" class="fd-tab-item disabled" title="Không có quyền truy cập">
                                <i class="bi bi-file-earmark-lock"></i> Hồ sơ bệnh án
                                <small><i class="bi bi-lock-fill"></i> Chưa cấp quyền</small>
                            </button>
                        </c:otherwise>
                    </c:choose>
                </div>

                <!-- CONTENT PANES -->
                <!-- Pane 1: Lịch Hẹn -->
                <c:if test="${sharing.canViewAppointments}">
                    <div id="pane-appointments" class="fd-pane active">
                        <div class="table-responsive">
                            <table class="fd-table">
                                <thead>
                                    <tr>
                                        <th>Mã lịch</th>
                                        <th>Ngày khám</th>
                                        <th>Khung giờ</th>
                                        <th>Bác sĩ khám</th>
                                        <th>Trạng thái</th>
                                    </tr>
                                </thead>
                                <tbody id="apptTableBody">
                                    <tr><td colspan="5" class="text-center py-4"><span class="fd-spinner d-inline-block"></span> Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </c:if>

                <!-- Pane 2: Hóa Đơn -->
                <c:if test="${sharing.canViewInvoices}">
                    <div id="pane-invoices" class="fd-pane ${!sharing.canViewAppointments ? 'active' : ''}">
                        <div class="table-responsive">
                            <table class="fd-table">
                                <thead>
                                    <tr>
                                        <th>Mã hóa đơn</th>
                                        <th>Ngày tạo</th>
                                        <th>Tổng tiền</th>
                                        <th>Số tiền phải trả</th>
                                        <th>Trạng thái</th>
                                    </tr>
                                </thead>
                                <tbody id="invoiceTableBody">
                                    <tr><td colspan="5" class="text-center py-4"><span class="fd-spinner d-inline-block"></span> Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </c:if>

                <!-- Pane 3: Bệnh Án -->
                <c:if test="${sharing.canViewRecords}">
                    <div id="pane-records" class="fd-pane ${!sharing.canViewAppointments && !sharing.canViewInvoices ? 'active' : ''}">
                        <div class="table-responsive">
                            <table class="fd-table">
                                <thead>
                                    <tr>
                                        <th>Ngày đo/khám</th>
                                        <th>Đường huyết (HbA1c)</th>
                                        <th>Chỉ số Thận (Urea / Cr)</th>
                                        <th>Chỉ số mỡ máu</th>
                                        <th>Cân nặng / BMI</th>
                                        <th>Trạng thái</th>
                                        <th>Người thực hiện</th>
                                    </tr>
                                </thead>
                                <tbody id="recordTableBody">
                                    <tr><td colspan="7" class="text-center py-4"><span class="fd-spinner d-inline-block"></span> Đang tải...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </c:if>
            </div>
        </div>
    </main>

    <script>
        const ownerId = ${sharing.ownerAccountId};
        const DATA_URL = '${pageContext.request.contextPath}/patient/family-dashboard';

        document.addEventListener('DOMContentLoaded', () => {
            // Tự động load dữ liệu của tab mặc định đang active
            const activeTab = document.querySelector('.fd-tab-item.active');
            if (activeTab) {
                const tabId = activeTab.id.replace('btn-', '');
                loadPaneData(tabId);
            }
        });

        function switchPane(paneId) {
            document.querySelectorAll('.fd-tab-item').forEach(item => item.classList.remove('active'));
            document.querySelectorAll('.fd-pane').forEach(pane => pane.classList.remove('active'));

            const btn = document.getElementById('btn-' + paneId);
            const pane = document.getElementById('pane-' + paneId);
            if (btn && pane) {
                btn.classList.add('active');
                pane.classList.add('active');
                loadPaneData(paneId);
            }
        }

        async function loadPaneData(type) {
            const tbodyId = type === 'appointments' ? 'apptTableBody' : (type === 'invoices' ? 'invoiceTableBody' : 'recordTableBody');
            const tbody = document.getElementById(tbodyId);
            if (!tbody) return;

            tbody.innerHTML = `<tr><td colspan="10" class="text-center py-4"><div class="fd-loading"><span class="fd-spinner"></span>Đang tải dữ liệu...</div></td></tr>`;

            try {
                const res = await fetch(`\${DATA_URL}?ownerId=\${ownerId}&type=\${type}`);
                const resJson = await res.json();
                if (resJson.success) {
                    renderData(type, resJson.data || []);
                } else {
                    tbody.innerHTML = `<tr><td colspan="10" class="text-center text-danger py-4"><i class="bi bi-exclamation-octagon"></i> \${resJson.message}</td></tr>`;
                }
            } catch (err) {
                console.error(err);
                tbody.innerHTML = `<tr><td colspan="10" class="text-center text-danger py-4"><i class="bi bi-exclamation-octagon"></i> Lỗi kết nối hệ thống.</td></tr>`;
            }
        }

        function renderData(type, list) {
            if (type === 'appointments') {
                renderAppointments(list);
            } else if (type === 'invoices') {
                renderInvoices(list);
            } else if (type === 'records') {
                renderRecords(list);
            }
        }

        function renderAppointments(list) {
            const tbody = document.getElementById('apptTableBody');
            if (list.length === 0) {
                tbody.innerHTML = `<tr><td colspan="5" class="text-center text-muted py-4">Không có lịch hẹn khám nào.</td></tr>`;
                return;
            }
            let html = '';
            list.forEach(item => {
                let statusBadge = '';
                if (item.status === 'Completed') statusBadge = '<span class="fd-badge fd-badge-green">Đã khám</span>';
                else if (item.status === 'Cancelled') statusBadge = '<span class="fd-badge fd-badge-red">Đã hủy</span>';
                else statusBadge = '<span class="fd-badge fd-badge-yellow">Chờ khám</span>';

                html += `
                    <tr>
                        <td>LH-\${item.id}</td>
                        <td>\${item.workDate}</td>
                        <td>\${item.timeSlot}</td>
                        <td>\${item.doctorName}</td>
                        <td>\${statusBadge}</td>
                    </tr>
                `;
            });
            tbody.innerHTML = html;
        }

        function renderInvoices(list) {
            const tbody = document.getElementById('invoiceTableBody');
            if (list.length === 0) {
                tbody.innerHTML = `<tr><td colspan="5" class="text-center text-muted py-4">Không có hóa đơn nào.</td></tr>`;
                return;
            }
            let html = '';
            list.forEach(item => {
                let statusBadge = '';
                if (item.status === 'Paid') statusBadge = '<span class="fd-badge fd-badge-green">Đã thanh toán</span>';
                else if (item.status === 'Cancelled') statusBadge = '<span class="fd-badge fd-badge-red">Đã hủy</span>';
                else statusBadge = '<span class="fd-badge fd-badge-yellow">Chờ thanh toán</span>';

                html += `
                    <tr>
                        <td>HD-\${item.id}</td>
                        <td>\${item.createdAt}</td>
                        <td>\${formatCurrency(item.totalAmount)} đ</td>
                        <td>\${formatCurrency(item.finalAmount)} đ</td>
                        <td>\${statusBadge}</td>
                    </tr>
                `;
            });
            tbody.innerHTML = html;
        }

        function renderRecords(list) {
            const tbody = document.getElementById('recordTableBody');
            if (list.length === 0) {
                tbody.innerHTML = `<tr><td colspan="7" class="text-center text-muted py-4">Không có hồ sơ bệnh án nào.</td></tr>`;
                return;
            }
            let html = '';
            list.forEach(item => {
                const urea = item.urea !== null ? `Urea: \${item.urea}` : '';
                const cr = item.cr !== null ? `Cr: \${item.cr}` : '';
                const kidneys = (urea || cr) ? `\${urea} <br> \${cr}` : '---';

                const hba1c = item.hba1c !== null ? `HbA1c: \${item.hba1c}%` : '---';

                const bmi = item.bmi !== null ? `BMI: \${item.bmi}` : '';
                const w = item.weight !== null ? `W: \${item.weight} kg` : '';
                const bmiWeight = (bmi || w) ? `\${w} <br> \${bmi}` : '---';

                const chol = item.chol !== null ? `Chol: \${item.chol}` : '';
                const tg = item.tg !== null ? `TG: \${item.tg}` : '';
                const hdl = item.hdl !== null ? `HDL: \${item.hdl}` : '';
                const ldl = item.ldl !== null ? `LDL: \${item.ldl}` : '';
                const vldl = item.vldl !== null ? `VLDL: \${item.vldl}` : '';
                let lipids = [];
                if (chol) lipids.push(chol);
                if (tg) lipids.push(tg);
                if (hdl) lipids.push(hdl);
                if (ldl) lipids.push(ldl);
                if (vldl) lipids.push(vldl);
                const lipidsStr = lipids.length > 0 ? lipids.join('<br>') : 'Lipids: Chờ trả kết quả';

                const isCompleted = item.status && item.status.toLowerCase() === 'completed' && item.finalDiagnosis && item.finalDiagnosis.trim() !== '';
                let statusHtml = '';
                if (isCompleted) {
                    statusHtml = `
                        <span class="fd-badge fd-badge-green">Hoàn thành</span>
                        <div class="small text-muted mt-1" style="max-width: 250px; word-break: break-word;">
                            <strong>Kết luận:</strong> \${item.finalDiagnosis}
                        </div>
                    `;
                } else {
                    statusHtml = `
                        <span class="fd-badge fd-badge-yellow">Đang xử lý</span>
                        <div class="small text-secondary mt-1">Đang chờ chẩn đoán/cập nhật thông tin</div>
                    `;
                }

                html += `
                    <tr>
                        <td>\${item.createdAt}</td>
                        <td><strong>\${hba1c}</strong></td>
                        <td>\${kidneys}</td>
                        <td>\${lipidsStr}</td>
                        <td>\${bmiWeight}</td>
                        <td>\${statusHtml}</td>
                        <td>\${item.doctorName || 'Kỹ thuật viên Lab'}</td>
                    </tr>
                `;
            });
            tbody.innerHTML = html;
        }

        function formatCurrency(amount) {
            return new Intl.NumberFormat('vi-VN').format(amount);
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
