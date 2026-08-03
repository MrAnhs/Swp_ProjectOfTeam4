document.addEventListener('DOMContentLoaded', function () {
    // Quản lý hiển thị lịch trực tuần của Lễ tân
    let currentDate = new Date();
    const dutyGridBody = document.getElementById('dutyGridBody');
    const selectYear = document.getElementById('dutyYearSelect');
    const selectWeek = document.getElementById('dutyWeekSelect');

    // Xác định ngày Thứ Hai đầu tuần của một ngày bất kỳ
    function getStartOfWeek(date) {
        const start = new Date(date);
        const day = start.getDay();
        const diff = start.getDate() - day + (day === 0 ? -6 : 1);
        start.setDate(diff);
        start.setHours(0, 0, 0, 0);
        return start;
    }

    // Định dạng đối tượng Date thành chuỗi 'YYYY-MM-DD'
    function formatDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        const year = d.getFullYear();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        return [year, month, day].join('-');
    }

    // Định dạng đối tượng Date thành chuỗi ngắn gọn 'DD/MM' để hiển thị tiêu đề cột
    function formatShortDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        return day + '/' + month;
    }

    // Kiểm tra xem hai đối tượng ngày có phải là cùng một ngày hay không
    function isToday(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
            d1.getMonth() === d2.getMonth() &&
            d1.getDate() === d2.getDate();
    }

    // Tạo danh sách các tùy chọn Năm trong ô chọn (Năm trước, Năm nay, Năm sau)
    function populateYearOptions() {
        if (!selectYear) return;
        const currentY = new Date().getFullYear();
        selectYear.innerHTML = '';
        for (let y = currentY - 1; y <= currentY + 1; y++) {
            const opt = document.createElement('option');
            opt.value = y;
            opt.textContent = 'Năm ' + y;
            if (y === currentDate.getFullYear()) opt.selected = true;
            selectYear.appendChild(opt);
        }
    }

    // Tự động tính toán các Tuần (từ Tuần 1 đến Tuần 52/53) của năm được chọn
    function populateWeekOptions(year) {
        if (!selectWeek) return;
        selectWeek.innerHTML = '';

        let jan1 = new Date(year, 0, 1);
        let day = jan1.getDay();
        let diff = jan1.getDate() - day + (day === 0 ? -6 : 1);
        let monday = new Date(jan1.setDate(diff));

        const currentStartOfWeekStr = formatDate(getStartOfWeek(currentDate));

        for (let w = 1; w <= 53; w++) {
            const sunday = new Date(monday);
            sunday.setDate(monday.getDate() + 6);

            if (monday.getFullYear() > year && sunday.getFullYear() > year) break;

            const valStr = formatDate(monday);
            const textStr = 'Tuần ' + String(w).padStart(2, '0') + ' [' + formatShortDate(monday) + ' - ' + formatShortDate(sunday) + ']';

            const opt = document.createElement('option');
            opt.value = valStr;
            opt.textContent = textStr;

            if (valStr === currentStartOfWeekStr) {
                opt.selected = true;
            }

            selectWeek.appendChild(opt);
            monday.setDate(monday.getDate() + 7);
        }
    }

    // Đồng bộ hóa giá trị hiển thị của ô chọn Năm và ô chọn Tuần
    function syncDropdowns() {
        if (selectYear) selectYear.value = String(currentDate.getFullYear());
        populateWeekOptions(currentDate.getFullYear());
        if (selectWeek) {
            const startOfWeekStr = formatDate(getStartOfWeek(currentDate));
            selectWeek.value = startOfWeekStr;
        }
    }

    // Gọi API để tải danh sách lịch trực của Lễ tân theo khoảng thời gian tuần
    async function loadSchedule() {
        const startOfWeek = getStartOfWeek(currentDate);
        const endOfWeek = new Date(startOfWeek);
        endOfWeek.setDate(startOfWeek.getDate() + 6);

        syncDropdowns();

        const startStr = formatDate(startOfWeek);
        const endStr = formatDate(endOfWeek);

        // Hiển thị ngày cụ thể trên tiêu đề các cột Thứ 2 -> Chủ Nhật
        const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
        for (let i = 0; i < 7; i++) {
            const d = new Date(startOfWeek);
            d.setDate(startOfWeek.getDate() + i);
            const headerCell = document.getElementById('date' + days[i]);
            if (headerCell) {
                headerCell.textContent = formatShortDate(d);
            }
        }

        try {
            const response = await fetch(`${window.ReceptionistConfig.apiBase}/my-schedule?fromDate=${startStr}&toDate=${endStr}`);
            const data = await response.json();

            if (data.success) {
                renderSchedule(startOfWeek, data.items || []);
            } else {
                if (dutyGridBody) {
                    dutyGridBody.innerHTML = '<tr><td colspan="8" class="text-center text-danger py-4">Không thể tải lịch trực: ' + (data.error || 'Lỗi không xác định') + '</td></tr>';
                }
            }
        } catch (error) {
            console.error('Error fetching schedule:', error);
            if (dutyGridBody) {
                dutyGridBody.innerHTML = '<tr><td colspan="8" class="text-center text-danger py-4">Lỗi kết nối máy chủ.</td></tr>';
            }
        }
    }

    // Vẽ giao diện bảng lịch trực sau khi lấy dữ liệu thành công
    function renderSchedule(startOfWeek, items) {
        if (!dutyGridBody) return;
        dutyGridBody.innerHTML = '';
        const today = new Date();

        const weekDates = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(startOfWeek);
            d.setDate(startOfWeek.getDate() + i);
            weekDates.push(d);
        }

        const shifts = [
            { name: 'Ca sáng', time: '07:00 - 11:30' },
            { name: 'Ca chiều', time: '13:30 - 17:30' }
        ];

        shifts.forEach((shift, index) => {
            let rowHtml = '<tr>' +
                '<td class="fw-semibold text-nowrap text-center py-4" style="width: 140px; background: rgba(15, 23, 42, 0.6); color: #cbd5e1; border-color: rgba(255,255,255,0.06);">' +
                    '<div class="small text-secondary mb-1" style="color: #94a3b8 !important;">Ca ' + (index + 1) + '</div>' +
                    '<span class="badge slot-badge" style="background: rgba(42, 181, 163, 0.2); color: #2ab5a3; border: 1px solid rgba(42, 181, 163, 0.4);">' + shift.time + '</span>' +
                '</td>';

            for (let i = 0; i < 7; i++) {
                const dateStr = formatDate(weekDates[i]);
                function getShiftCategory(timeSlotStr) {
                    if (!timeSlotStr) return 'Ca sáng';
                    const str = timeSlotStr.toLowerCase().trim();
                    if (str.includes('chiều') || str.includes('chieu') || str.includes('afternoon') || str.includes('13:30') || str.includes('ca 2')) {
                        return 'Ca chiều';
                    }
                    return 'Ca sáng';
                }

                const shiftItems = items.filter(item => {
                    const itemDate = item.workDate;
                    if (itemDate !== dateStr) return false;
                    return getShiftCategory(item.timeSlot) === shift.name;
                });

                let cellContent = '';
                if (shiftItems.length > 0) {
                    cellContent = '<div class="d-flex flex-column gap-2">';
                    shiftItems.forEach(item => {
                        const isPastDate = new Date(dateStr + 'T23:59:59') < new Date(today.getFullYear(), today.getMonth(), today.getDate());
                        const st = (item.status || '').toLowerCase().trim();

                        let statusText = 'Sẵn sàng';
                        let statusClass = 'status-scheduled';
                        let badgeClass = 'shift-badge-scheduled';

                        if (st === 'cancelled' || st === 'absent') {
                            statusText = 'Đã hủy';
                            statusClass = 'status-expired';
                            badgeClass = 'shift-badge-expired';
                        } else if (st === 'completed') {
                            statusText = 'Hoàn thành';
                            statusClass = 'status-scheduled';
                            badgeClass = 'shift-badge-scheduled';
                        } else if (st === 'available' || st === 'active' || st === 'scheduled' || st === 'registered') {
                            statusText = 'Sẵn sàng';
                            statusClass = 'status-scheduled';
                            badgeClass = 'shift-badge-scheduled';
                        } else if (st === 'expired' || isPastDate) {
                            statusText = 'Hoàn thành';
                            statusClass = 'status-expired';
                            badgeClass = 'shift-badge-expired';
                        }

                        const roomName = item.roomName ? item.roomName : (item.roomId ? ('Phòng ' + item.roomId) : 'Quầy lễ tân');

                        cellContent += `
                            <div class="shift-card ${statusClass} text-start p-2 rounded" style="font-size: 0.72rem; background: rgba(30, 41, 59, 0.5); border: 1px solid rgba(255,255,255,0.08); margin: 2px;">
                                <div class="shift-time-head fw-bold" style="color: #2ab5a3; font-size: 0.75rem; margin-bottom: 2px;"><i class="bi bi-clock me-1"></i>${item.timeSlot}</div>
                                <div class="shift-room-name text-white-50" style="margin-bottom: 2px; font-size: 0.68rem;"><i class="bi bi-door-open me-1"></i>${roomName}</div>
                                <div class="shift-staff-name text-white-50" style="margin-bottom: 4px; font-size: 0.68rem;"><i class="bi bi-person me-1"></i>${item.fullName || 'Lễ tân'}</div>
                                <div class="shift-status-badge"><span class="badge ${badgeClass}" style="padding: 2.5px 6px; font-size: 0.6rem; font-weight: 600;">${statusText}</span></div>
                            </div>
                        `;
                    });
                    cellContent += '</div>';
                } else {
                    cellContent = '<span class="text-white-50 opacity-25">-</span>';
                }

                rowHtml += `<td class="p-2 align-top text-center" style="border-color: rgba(255, 255, 255, 0.06); background: transparent;">${cellContent}</td>`;
            }
            rowHtml += '</tr>';
            if (dutyGridBody) {
                dutyGridBody.innerHTML += rowHtml;
            }
        });
    }

    // Lắng nghe sự kiện đổi Năm để tải lại lịch tương ứng
    if (selectYear) {
        selectYear.addEventListener('change', () => {
            currentDate.setFullYear(parseInt(selectYear.value, 10));
            populateWeekOptions(currentDate.getFullYear());
            loadSchedule();
        });
    }

    // Lắng nghe sự kiện đổi Tuần để tải lại lịch tương ứng
    if (selectWeek) {
        selectWeek.addEventListener('change', () => {
            if (selectWeek.value) {
                const parts = selectWeek.value.split('-');
                currentDate = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
                loadSchedule();
            }
        });
    }

    // Kích hoạt các hàm khởi chạy trang ban đầu
    populateYearOptions();
    syncDropdowns();
    loadSchedule();
});
