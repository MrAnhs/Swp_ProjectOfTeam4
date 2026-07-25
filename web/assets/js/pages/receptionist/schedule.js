document.addEventListener('DOMContentLoaded', function () {
    let currentDate = new Date();
    const scheduleGrid = document.getElementById('scheduleGrid');
    const selectYear = document.getElementById('selectYear');
    const selectWeek = document.getElementById('selectWeek');

    function getStartOfWeek(date) {
        const start = new Date(date);
        const day = start.getDay();
        const diff = start.getDate() - day + (day === 0 ? -6 : 1);
        start.setDate(diff);
        start.setHours(0, 0, 0, 0);
        return start;
    }

    function formatDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        const year = d.getFullYear();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        return [year, month, day].join('-');
    }

    function formatShortDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        return day + '/' + month;
    }

    function isToday(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
            d1.getMonth() === d2.getMonth() &&
            d1.getDate() === d2.getDate();
    }

    function populateYearOptions() {
        if (!selectYear) return;
        const currentY = new Date().getFullYear();
        selectYear.innerHTML = '';
        for (let y = currentY - 1; y <= currentY + 1; y++) {
            const opt = document.createElement('option');
            opt.value = y;
            opt.textContent = y;
            if (y === currentDate.getFullYear()) opt.selected = true;
            selectYear.appendChild(opt);
        }
    }

    function populateWeekOptions(year) {
        if (!selectWeek) return;
        selectWeek.innerHTML = '';

        let jan1 = new Date(year, 0, 1);
        let day = jan1.getDay();
        let diff = jan1.getDate() - day + (day === 0 ? -6 : 1);
        let monday = new Date(jan1.setDate(diff));

        const currentStartOfWeekStr = formatDate(getStartOfWeek(currentDate));

        for (let w = 0; w < 53; w++) {
            const sunday = new Date(monday);
            sunday.setDate(monday.getDate() + 6);

            if (monday.getFullYear() > year && sunday.getFullYear() > year) break;

            const valStr = formatDate(monday);
            const textStr = formatShortDate(monday) + ' To ' + formatShortDate(sunday);

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

    function syncDropdowns() {
        if (selectYear) selectYear.value = String(currentDate.getFullYear());
        populateWeekOptions(currentDate.getFullYear());
        if (selectWeek) {
            const startOfWeekStr = formatDate(getStartOfWeek(currentDate));
            selectWeek.value = startOfWeekStr;
        }
    }

    async function loadSchedule() {
        const startOfWeek = getStartOfWeek(currentDate);
        const endOfWeek = new Date(startOfWeek);
        endOfWeek.setDate(startOfWeek.getDate() + 6);

        syncDropdowns();

        const startStr = formatDate(startOfWeek);
        const endStr = formatDate(endOfWeek);

        try {
            const response = await fetch(`${window.ReceptionistConfig.apiBase}/my-schedule?fromDate=${startStr}&toDate=${endStr}`);
            const data = await response.json();

            if (data.success) {
                renderSchedule(startOfWeek, data.items || []);
            } else {
                scheduleGrid.innerHTML = '<div class="col-12 text-center text-danger py-4">Không thể tải lịch trực: ' + (data.error || 'Lỗi không xác định') + '</div>';
            }
        } catch (error) {
            console.error('Error fetching schedule:', error);
            scheduleGrid.innerHTML = '<div class="col-12 text-center text-danger py-4">Lỗi kết nối máy chủ.</div>';
        }
    }

    function renderSchedule(startOfWeek, items) {
        scheduleGrid.innerHTML = '';

        // Render headers matching Image 2
        scheduleGrid.innerHTML += '<div class="sched-hdr-cell"><span class="sched-hdr-title">Ca / Giờ</span></div>';
        const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ Nhật'];
        const today = new Date();

        const weekDates = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(startOfWeek);
            d.setDate(startOfWeek.getDate() + i);
            weekDates.push(d);

            const isTodayClass = isToday(d, today) ? 'is-today' : '';

            scheduleGrid.innerHTML += `
                <div class="sched-hdr-cell ${isTodayClass}">
                    <div class="sched-day-name">${days[i]}</div>
                    <div class="sched-date-num">${d.getDate()}</div>
                    <div class="sched-month-name">Tháng ${d.getMonth() + 1}</div>
                </div>
            `;
        }

        const shifts = [
            { name: 'Ca 1', time: '08:00 - 12:00' },
            { name: 'Ca 2', time: '13:00 - 17:00' }
        ];

        shifts.forEach(shift => {
            scheduleGrid.innerHTML += `
                <div class="sched-time-col">
                    <div class="sched-shift-title">${shift.name}</div>
                    <div class="sched-shift-time">${shift.time}</div>
                </div>
            `;

            for (let i = 0; i < 7; i++) {
                const dateStr = formatDate(weekDates[i]);
                function getShiftCategory(timeSlotStr) {
                    if (!timeSlotStr) return 'Ca 1';
                    const str = timeSlotStr.toLowerCase().trim();
                    if (str.includes('ca 2') || str.includes('chiều') || str.includes('tối') || str.includes('chieu') || str.includes('toi') || str.includes('night') || str.includes('afternoon')) {
                        return 'Ca 2';
                    }
                    if (str.includes('ca 1') || str.includes('sáng') || str.includes('sang') || str.includes('morning')) {
                        return 'Ca 1';
                    }
                    const match = str.match(/^(\d{1,2})/);
                    if (match) {
                        const hour = parseInt(match[1], 10);
                        return hour >= 12 ? 'Ca 2' : 'Ca 1';
                    }
                    return 'Ca 1';
                }

                const shiftItems = items.filter(item => {
                    const itemDate = item.workDate;
                    if (itemDate !== dateStr) return false;
                    return getShiftCategory(item.timeSlot) === shift.name;
                });

                let cellContent = '';
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
                        <div class="shift-card ${statusClass}">
                            <div class="shift-time-head"><i class="bi bi-clock me-1"></i>${item.timeSlot}</div>
                            <div class="shift-room-name text-muted small my-1" style="font-size: 0.76rem;"><i class="bi bi-door-open me-1"></i>${roomName}</div>
                            <div class="shift-staff-name small text-secondary mb-1" style="font-size: 0.76rem;"><i class="bi bi-person me-1"></i>Lễ tân: ${item.fullName || 'Nhân viên Lễ tân'}</div>
                            <div>Trạng thái: <span class="badge ${badgeClass}">${statusText}</span></div>
                        </div>
                    `;
                });

                scheduleGrid.innerHTML += `<div class="sched-grid-cell">${cellContent}</div>`;
            }
        });
    }

    if (selectYear) {
        selectYear.addEventListener('change', () => {
            currentDate.setFullYear(parseInt(selectYear.value, 10));
            populateWeekOptions(currentDate.getFullYear());
            loadSchedule();
        });
    }

    if (selectWeek) {
        selectWeek.addEventListener('change', () => {
            if (selectWeek.value) {
                const parts = selectWeek.value.split('-');
                currentDate = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
                loadSchedule();
            }
        });
    }

    populateYearOptions();
    syncDropdowns();
    loadSchedule();
});
