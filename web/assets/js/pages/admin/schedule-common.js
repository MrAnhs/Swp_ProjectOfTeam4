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

// ==========================================
// 4. SAAS UI/UX INTERACTION & FILTER LOGIC
// ==========================================
document.addEventListener('DOMContentLoaded', function () {
    const viewCalendarBtn = document.getElementById('viewModeCalendarBtn');
    const viewListBtn = document.getElementById('viewModeListBtn');
    const detailedListPane = document.getElementById('detailedListPane');
    const weeklyCalendarPane = document.getElementById('weeklyCalendarPane');
    const filterTimeLabel = document.getElementById('filterTimeLabel');
    const filterWeekPickerGroup = document.getElementById('filterWeekPickerGroup');
    const unifiedDatePicker = document.getElementById('unifiedDatePicker');
    const unifiedWeekPicker = document.getElementById('unifiedWeekPicker');

    const unifiedRoleFilter = document.getElementById('unifiedRoleFilter');
    const unifiedRoleFilterContainer = document.getElementById('unifiedRoleFilterContainer');
    const detailedListRoleSwitch = document.getElementById('detailedListRoleSwitch');
    const unifiedRoomFilter = document.getElementById('unifiedRoomFilter');
    const unifiedSearch = document.getElementById('unifiedSearch');
    const unifiedFilterForm = document.getElementById('unifiedFilterForm');
    const selectedViewTabInput = document.getElementById('selectedViewTab');

    // 4.1 Khởi tạo trạng thái View ban đầu
    let currentViewMode = sessionStorage.getItem('adminScheduleViewMode') || 'calendar';

    // Nếu URL có tham số roleFilter hoặc workDate hoặc doctorName -> Tự động chuyển sang chế độ xem Danh sách chi tiết
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('roleFilter') || urlParams.has('workDate') || urlParams.has('doctorName') || urlParams.has('staffName') || urlParams.has('staffType')) {
        currentViewMode = 'list';
    }

    const unifiedTimeFilterContainer = document.getElementById('unifiedTimeFilterContainer');
    const unifiedRoomFilterContainer = document.getElementById('unifiedRoomFilterContainer');
    const unifiedSearchContainer = document.getElementById('unifiedSearchContainer');
    const unifiedFilterActionContainer = document.getElementById('unifiedFilterActionContainer');

    function switchViewMode(mode) {
        currentViewMode = mode;
        sessionStorage.setItem('adminScheduleViewMode', mode);

        if (mode === 'calendar') {
            // Cập nhật nút
            viewCalendarBtn.className = "btn btn-sm px-3 rounded-2 fw-bold text-white bg-purple";
            viewCalendarBtn.style.backgroundColor = "#7c3aed";
            viewListBtn.className = "btn btn-sm px-3 rounded-2 fw-semibold text-secondary bg-transparent";
            viewListBtn.style.backgroundColor = "transparent";

            // Lịch theo tuần: HIỆN Dropdown "Vai trò nhân sự" ở Form bộ lọc, ẨN Nút Tab 1-Click ở dưới
            if (unifiedRoleFilterContainer) unifiedRoleFilterContainer.style.display = 'block';
            if (detailedListRoleSwitch) detailedListRoleSwitch.style.display = 'none';

            // Cân bằng lại cột bộ lọc
            if (unifiedTimeFilterContainer) unifiedTimeFilterContainer.className = 'col-md-3 col-lg-3';
            if (unifiedRoomFilterContainer) unifiedRoomFilterContainer.className = 'col-md-3 col-lg-3';
            if (unifiedSearchContainer) unifiedSearchContainer.className = 'col-md-3 col-lg-2';
            if (unifiedFilterActionContainer) unifiedFilterActionContainer.className = 'col-md-12 col-lg-1 d-flex gap-1';

            // Ẩn hiện Pane
            if (detailedListPane) detailedListPane.style.display = 'none';
            if (weeklyCalendarPane) {
                weeklyCalendarPane.style.display = 'block';
                weeklyCalendarPane.removeAttribute('hidden');
            }

            // Đổi picker thời gian sang Tuần
            if (filterTimeLabel) filterTimeLabel.textContent = "Chọn tuần trực";
            if (filterWeekPickerGroup) {
                filterWeekPickerGroup.classList.remove('d-none');
                filterWeekPickerGroup.style.setProperty('display', 'flex', 'important');
            }
            if (unifiedDatePicker) {
                unifiedDatePicker.classList.add('d-none');
                unifiedDatePicker.style.setProperty('display', 'none', 'important');
            }

            if (selectedViewTabInput) selectedViewTabInput.value = 'calendar';
            if (typeof window.loadWeeklyCalendar === 'function') {
                window.loadWeeklyCalendar();
            }
        } else {
            // Cập nhật nút
            viewListBtn.className = "btn btn-sm px-3 rounded-2 fw-bold text-white bg-primary";
            viewListBtn.style.backgroundColor = "#0d6efd";
            viewCalendarBtn.className = "btn btn-sm px-3 rounded-2 fw-semibold text-secondary bg-transparent";
            viewCalendarBtn.style.backgroundColor = "transparent";

            // Danh sách chi tiết: ẨN Dropdown "Vai trò nhân sự" ở Form bộ lọc, HIỆN Bộ 3 Nút Tab Role 1-Click
            if (unifiedRoleFilterContainer) unifiedRoleFilterContainer.style.setProperty('display', 'none', 'important');
            if (detailedListRoleSwitch) detailedListRoleSwitch.style.setProperty('display', 'block', 'important');

            // Cân bằng lại cột bộ lọc khi ẩn cột Vai trò
            if (unifiedTimeFilterContainer) unifiedTimeFilterContainer.className = 'col-md-3 col-lg-3';
            if (unifiedRoomFilterContainer) unifiedRoomFilterContainer.className = 'col-md-3 col-lg-3';
            if (unifiedSearchContainer) unifiedSearchContainer.className = 'col-md-3 col-lg-4';
            if (unifiedFilterActionContainer) unifiedFilterActionContainer.className = 'col-md-12 col-lg-2 d-flex gap-1';

            // Ẩn hiện Pane
            if (detailedListPane) {
                detailedListPane.style.setProperty('display', 'block', 'important');
                detailedListPane.classList.add('show', 'active');
            }
            if (weeklyCalendarPane) weeklyCalendarPane.style.setProperty('display', 'none', 'important');

            // Đổi picker thời gian sang Ngày
            if (filterTimeLabel) filterTimeLabel.textContent = "Chọn ngày trực";
            if (filterWeekPickerGroup) {
                filterWeekPickerGroup.classList.add('d-none');
                filterWeekPickerGroup.style.setProperty('display', 'none', 'important');
            }
            if (unifiedDatePicker) {
                unifiedDatePicker.classList.remove('d-none');
                unifiedDatePicker.style.setProperty('display', 'block', 'important');
            }

            if (selectedViewTabInput) selectedViewTabInput.value = 'list';

            // Đồng bộ trạng thái active của Bộ 3 Nút Tab Role và Pane chi tiết
            const activeRole = unifiedRoleFilter ? unifiedRoleFilter.value : 'Doctor';
            syncDetailedRoleTabButtons(activeRole);
            updateDetailedListPanes();
        }
    }

    if (viewCalendarBtn && viewListBtn) {
        viewCalendarBtn.addEventListener('click', () => switchViewMode('calendar'));
        viewListBtn.addEventListener('click', () => switchViewMode('list'));

        // Khởi tạo chạy view mặc định
        switchViewMode(currentViewMode);
    }

    // 4.2 Lọc các tùy chọn phòng / khoa dựa theo Vai trò được chọn
    function filterRoomOptions() {
        if (!unifiedRoleFilter || !unifiedRoomFilter) return;
        const role = unifiedRoleFilter.value;
        const options = unifiedRoomFilter.querySelectorAll('option');

        options.forEach(opt => {
            if (opt.value === 'all') {
                opt.style.display = 'block';
                return;
            }

            if (role === 'all') {
                opt.style.display = 'block';
            } else if (role === 'Doctor') {
                // Doctor thì hiện phòng khám (.role-opt-Doctor)
                if (opt.classList.contains('role-opt-Doctor')) {
                    opt.style.display = 'block';
                } else {
                    opt.style.display = 'none';
                }
            } else if (role === 'doctor_lab' || role === 'Lab') {
                // Lab thi hiện phòng Lab (.role-opt-Lab)
                if (opt.classList.contains('role-opt-Lab')) {
                    opt.style.display = 'block';
                } else {
                    opt.style.display = 'none';
                }
            } else {
                // Các vai trò khác (Receptionist) ẩn phòng hoặc hiển thị tuỳ ý
                opt.style.display = 'none';
            }
        });

        // Nếu option đang được chọn bị ẩn, chọn lại 'all'
        const selectedOpt = unifiedRoomFilter.options[unifiedRoomFilter.selectedIndex];
        if (selectedOpt && selectedOpt.style.display === 'none') {
            unifiedRoomFilter.value = 'all';
        }
    }

    // 4.3 Ẩn / hiện các Pane chi tiết (Bác sĩ, Lễ tân, Lab) trong Tab Danh sách chi tiết
    function updateDetailedListPanes(forcedRole) {
        const role = forcedRole || (unifiedRoleFilter ? unifiedRoleFilter.value : 'Doctor');
        const doctorPane = document.getElementById('doctorRolePane') || document.querySelector('.schedule-table-doctor')?.closest('.schedule-role-pane');
        const receptionistPane = document.getElementById('receptionistRolePane') || document.querySelector('.schedule-table-receptionist')?.closest('.schedule-role-pane');
        const labPane = document.getElementById('labRolePane') || document.querySelector('.schedule-table-lab')?.closest('.schedule-role-pane');

        if (role === 'Doctor') {
            if (doctorPane) { doctorPane.style.display = 'block'; doctorPane.removeAttribute('hidden'); }
            if (receptionistPane) receptionistPane.style.display = 'none';
            if (labPane) labPane.style.display = 'none';
        } else if (role === 'Receptionist' || role === 'Reception') {
            if (doctorPane) doctorPane.style.display = 'none';
            if (receptionistPane) { receptionistPane.style.display = 'block'; receptionistPane.removeAttribute('hidden'); }
            if (labPane) labPane.style.display = 'none';
        } else if (role === 'doctor_lab' || role === 'Lab') {
            if (doctorPane) doctorPane.style.display = 'none';
            if (receptionistPane) receptionistPane.style.display = 'none';
            if (labPane) { labPane.style.display = 'block'; labPane.removeAttribute('hidden'); }
        } else {
            // Mặc định 'all' - hiện cả 3 pane xếp chồng lên nhau
            if (doctorPane) { doctorPane.style.display = 'block'; doctorPane.removeAttribute('hidden'); }
            if (receptionistPane) { receptionistPane.style.display = 'block'; receptionistPane.removeAttribute('hidden'); }
            if (labPane) { labPane.style.display = 'block'; labPane.removeAttribute('hidden'); }
        }
    }

    // Thao tác 1-Click Bộ 3 Nút Tab Role ở Danh sách chi tiết
    const detailedRoleTabs = document.querySelectorAll('.detailed-role-tab');
    detailedRoleTabs.forEach(tab => {
        tab.addEventListener('click', function (e) {
            e.preventDefault();
            const targetRole = this.getAttribute('data-role');
            if (unifiedRoleFilter) {
                unifiedRoleFilter.value = targetRole;
                filterRoomOptions();
            }
            syncDetailedRoleTabButtons(targetRole);
            updateDetailedListPanes(targetRole);
            if (typeof window.loadWeeklyCalendar === 'function') {
                window.loadWeeklyCalendar();
            }
        });
    });

    function syncDetailedRoleTabButtons(activeRole) {
        detailedRoleTabs.forEach(tab => {
            const r = tab.getAttribute('data-role');
            if (r === activeRole || (activeRole === 'all' && r === 'Doctor')) {
                tab.className = "btn btn-sm rounded-pill px-3 py-1 fw-bold detailed-role-tab active text-white bg-primary";
                tab.style.backgroundColor = "#0d6efd";
            } else {
                tab.className = "btn btn-sm rounded-pill px-3 py-1 fw-semibold text-secondary bg-transparent detailed-role-tab";
                tab.style.backgroundColor = "transparent";
            }
        });
    }

    if (unifiedRoleFilter) {
        unifiedRoleFilter.addEventListener('change', function () {
            filterRoomOptions();
            syncDetailedRoleTabButtons(this.value);
            if (currentViewMode === 'list') {
                updateDetailedListPanes();
            } else {
                if (typeof window.loadWeeklyCalendar === 'function') {
                    window.loadWeeklyCalendar();
                }
            }
        });
        // Chạy lần đầu
        filterRoomOptions();
    }

    // 4.4 Đồng bộ lịch tuần bằng cách click các nút tuần ở Unified Picker
    const unifiedPrevWeekBtn = document.getElementById('unifiedPrevWeekBtn');
    const unifiedTodayBtn = document.getElementById('unifiedTodayBtn');
    const unifiedNextWeekBtn = document.getElementById('unifiedNextWeekBtn');

    if (unifiedPrevWeekBtn && unifiedWeekPicker) {
        unifiedPrevWeekBtn.addEventListener('click', function () {
            const cur = new Date(unifiedWeekPicker.value || new Date());
            cur.setDate(cur.getDate() - 7);
            const dateStr = cur.toISOString().slice(0, 10);
            unifiedWeekPicker.value = dateStr;

            // Đồng bộ sang calendar cũ và trigger
            const oldPicker = document.getElementById('calendarWeekPicker');
            if (oldPicker) {
                oldPicker.value = dateStr;
                oldPicker.dispatchEvent(new Event('change'));
            }
        });
    }

    if (unifiedTodayBtn && unifiedWeekPicker) {
        unifiedTodayBtn.addEventListener('click', function () {
            const dateStr = new Date().toISOString().slice(0, 10);
            unifiedWeekPicker.value = dateStr;

            // Đồng bộ sang calendar cũ và trigger
            const oldPicker = document.getElementById('calendarWeekPicker');
            if (oldPicker) {
                oldPicker.value = dateStr;
                oldPicker.dispatchEvent(new Event('change'));
            }
        });
    }

    if (unifiedNextWeekBtn && unifiedWeekPicker) {
        unifiedNextWeekBtn.addEventListener('click', function () {
            const cur = new Date(unifiedWeekPicker.value || new Date());
            cur.setDate(cur.getDate() + 7);
            const dateStr = cur.toISOString().slice(0, 10);
            unifiedWeekPicker.value = dateStr;

            // Đồng bộ sang calendar cũ và trigger
            const oldPicker = document.getElementById('calendarWeekPicker');
            if (oldPicker) {
                oldPicker.value = dateStr;
                oldPicker.dispatchEvent(new Event('change'));
            }
        });
    }

    if (unifiedWeekPicker) {
        // Set ngày hiện tại nếu chưa có
        if (!unifiedWeekPicker.value) {
            unifiedWeekPicker.value = new Date().toISOString().slice(0, 10);
        }

        unifiedWeekPicker.addEventListener('change', function () {
            const oldPicker = document.getElementById('calendarWeekPicker');
            if (oldPicker) {
                oldPicker.value = unifiedWeekPicker.value;
                oldPicker.dispatchEvent(new Event('change'));
            }
        });
    }

    // 4.5 Xử lý khi Submit Form Lọc Hợp Nhất
    if (unifiedFilterForm) {
        unifiedFilterForm.addEventListener('submit', function (e) {
            const role = unifiedRoleFilter.value;
            const searchVal = unifiedSearch.value;
            const roomVal = unifiedRoomFilter.value; // room_id hoặc dept_id

            // Gán dữ liệu sang các hidden inputs tương ứng
            document.getElementById('hiddenDoctorName').value = searchVal;
            document.getElementById('hiddenStaffName').value = searchVal;

            // Trạng thái
            document.getElementById('hiddenDoctorStatus').value = '';
            document.getElementById('hiddenReceptionistStatus').value = '';
            document.getElementById('hiddenLabStatus').value = '';

            // Xử lý khoa và phòng
            if (roomVal.startsWith('dept_')) {
                const dept = roomVal.substring(5);
                document.getElementById('hiddenDepartment').value = dept;
                document.getElementById('hiddenStaffDepartment').value = dept;
            } else {
                document.getElementById('hiddenDepartment').value = '';
                document.getElementById('hiddenStaffDepartment').value = '';
            }

            // Xử lý thời gian
            if (currentViewMode === 'calendar') {
                e.preventDefault(); // Không reload trang nếu đang xem Calendar (vì Calendar load qua AJAX)

                // Đồng bộ sang bộ lọc Calendar cũ
                const calRole = document.getElementById('calendarRoleFilter');
                const calRoom = document.getElementById('calendarRoomFilter');
                const calPicker = document.getElementById('calendarWeekPicker');

                if (calRole) calRole.value = role === 'Reception' ? 'Reception' : (role === 'Lab' ? 'Lab' : (role === 'Doctor' ? 'Doctor' : 'all'));
                if (calRoom) calRoom.value = roomVal.startsWith('room_') ? roomVal.substring(5) : 'all';
                if (calPicker) calPicker.value = unifiedWeekPicker.value;

                // Trigger gọi AJAX tải dữ liệu lịch tuần
                document.getElementById('calFilterSubmitBtn')?.click();
            } else {
                // View là List: Submit để Servlet reload dữ liệu phân trang
                const dateVal = unifiedDatePicker.value;
                document.getElementById('hiddenWorkDate').value = dateVal;
                document.getElementById('hiddenStaffWorkDate').value = dateVal;

                // Nếu vai trò được chọn, truyền kèm tham số staffType để backend tối ưu
                if (role === 'Reception') {
                    // Thêm hidden input staffType
                    let inputType = unifiedFilterForm.querySelector('input[name="staffType"]');
                    if (!inputType) {
                        inputType = document.createElement('input');
                        inputType.type = 'hidden';
                        inputType.name = 'staffType';
                        unifiedFilterForm.appendChild(inputType);
                    }
                    inputType.value = 'Receptionist';
                } else if (role === 'Lab') {
                    let inputType = unifiedFilterForm.querySelector('input[name="staffType"]');
                    if (!inputType) {
                        inputType = document.createElement('input');
                        inputType.type = 'hidden';
                        inputType.name = 'staffType';
                        unifiedFilterForm.appendChild(inputType);
                    }
                    inputType.value = 'doctor_lab';
                }
            }
        });

        // Nút reset bộ lọc
        const unifiedFilterResetBtn = document.getElementById('unifiedFilterResetBtn');
        if (unifiedFilterResetBtn) {
            unifiedFilterResetBtn.addEventListener('click', function () {
                window.location.href = adminScheduleEndpoint + '?action=schedule';
            });
        }
    }

    // 4.6 Bộ lọc phòng client-side dành cho chế độ Danh sách chi tiết
    function applyRoomFilterClientSide() {
        if (!unifiedRoomFilter) return;
        const val = unifiedRoomFilter.value;
        const tables = document.querySelectorAll('.schedule-list-table');

        tables.forEach(table => {
            const rows = table.querySelectorAll('tbody tr');
            rows.forEach(row => {
                // Bỏ qua dòng rỗng hoặc dòng tiêu đề phụ
                if (row.querySelector('.schedule-empty-state') || row.cells.length <= 1) {
                    return;
                }

                if (val === 'all') {
                    row.style.display = '';
                } else if (val.startsWith('room_')) {
                    const targetRoomId = val.substring(5);
                    const rowRoomId = row.getAttribute('data-room-id');
                    if (rowRoomId && rowRoomId === targetRoomId) {
                        row.style.display = '';
                    } else {
                        row.style.display = 'none';
                    }
                } else if (val.startsWith('dept_')) {
                    const targetDept = val.substring(5);
                    const rowDept = row.getAttribute('data-department');
                    if (rowDept && rowDept === targetDept) {
                        row.style.display = '';
                    } else {
                        row.style.display = 'none';
                    }
                }
            });
        });
    }

    if (unifiedRoomFilter) {
        unifiedRoomFilter.addEventListener('change', applyRoomFilterClientSide);
        // Chạy lần đầu sau khi load trang
        applyRoomFilterClientSide();
    }

    // 4.7 Lắng nghe sự kiện click nút Xem chi tiết ca trực
    document.addEventListener('click', function (e) {
        const btn = e.target.closest('.schedule-detail-action, .staff-schedule-detail-action');
        if (!btn) return;

        e.preventDefault();
        const row = btn.closest('tr');
        if (!row) return;

        const doctorName = row.getAttribute('data-doctor-name') || row.getAttribute('data-staff-name') || (row.cells[0] ? row.cells[0].textContent.trim() : '-');
        const department = row.getAttribute('data-department') || row.getAttribute('data-work-area') || (row.cells[1] ? row.cells[1].textContent.trim() : '-');
        const workDate = row.getAttribute('data-work-date') || (row.cells[2] ? row.cells[2].textContent.trim() : '-');
        const timeSlot = row.getAttribute('data-time-slot') || (row.cells[3] ? row.cells[3].textContent.trim() : '-');
        const roomName = row.getAttribute('data-room-name') || (row.cells[4] ? row.cells[4].textContent.trim() : 'Chưa xếp');

        const shiftObj = {
            staff: doctorName,
            role: department,
            room: roomName,
            date: workDate,
            timeSlot: timeSlot
        };

        const modalEl = document.getElementById('shiftDetailModal');
        if (modalEl) {
            const staffEl = document.getElementById('shiftDetailStaff');
            const roleEl = document.getElementById('shiftDetailRole');
            const roomEl = document.getElementById('shiftDetailRoom');
            const dateEl = document.getElementById('shiftDetailDate');
            const timeEl = document.getElementById('shiftDetailTime');

            if (staffEl) staffEl.textContent = shiftObj.staff;
            if (roleEl) roleEl.textContent = shiftObj.role;
            if (roomEl) roomEl.textContent = shiftObj.room;
            if (dateEl) dateEl.textContent = shiftObj.date;
            if (timeEl) timeEl.textContent = shiftObj.timeSlot;

            const modal = new bootstrap.Modal(modalEl);
            modal.show();
        }
    });
});
