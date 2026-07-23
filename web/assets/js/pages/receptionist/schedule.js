document.addEventListener('DOMContentLoaded', () => {
    let currentDate = new Date();
    const scheduleGrid = document.getElementById('scheduleGrid');
    const currentWeekRange = document.getElementById('currentWeekRange');

    function getStartOfWeek(date) {
        const start = new Date(date);
        const day = start.getDay();
        const diff = start.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
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

    function formatDisplayDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        const year = d.getFullYear();

        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;

        return [day, month, year].join('/');
    }
    
    function isToday(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
            d1.getMonth() === d2.getMonth() &&
            d1.getDate() === d2.getDate();
    }

    async function loadSchedule() {
        const startOfWeek = getStartOfWeek(currentDate);
        const endOfWeek = new Date(startOfWeek);
        endOfWeek.setDate(startOfWeek.getDate() + 6);

        currentWeekRange.textContent = `${formatDisplayDate(startOfWeek)} - ${formatDisplayDate(endOfWeek)}`;

        const startStr = formatDate(startOfWeek);
        const endStr = formatDate(endOfWeek);

        try {
            const response = await fetch(`${window.ReceptionistConfig.apiBase}/my-schedule?fromDate=${startStr}&toDate=${endStr}`);
            const data = await response.json();
            
            if (data.success) {
                renderSchedule(startOfWeek, data.items || []);
            } else {
                alert('Kh\u00f4ng th\u1ec3 t\u1ea3i l\u1ecbch tr\u1ef1c: ' + (data.error || 'L\u1ed7i kh\u00f4ng x\u00e1c \u0111\u1ecbnh'));
            }
        } catch (error) {
            console.error('Error fetching schedule:', error);
            alert('L\u1ed7i k\u1ebft n\u1ed1i m\u00e1y ch\u1ee7.');
        }
    }

    function renderSchedule(startOfWeek, items) {
        scheduleGrid.innerHTML = '';
        
        // Render headers
        scheduleGrid.innerHTML += '<div class="schedule-header">Ca / Gi\u1edd</div>';
        const days = ['Th\u1ee9 2', 'Th\u1ee9 3', 'Th\u1ee9 4', 'Th\u1ee9 5', 'Th\u1ee9 6', 'Th\u1ee9 7', 'Ch\u1ee7 Nh\u1eadt'];
        const today = new Date();
        
        const weekDates = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(startOfWeek);
            d.setDate(startOfWeek.getDate() + i);
            weekDates.push(d);
            
            const isTodayClass = isToday(d, today) ? 'today' : '';
            
            scheduleGrid.innerHTML += `
                <div class="schedule-header ${isTodayClass}">
                    <div class="day-name">${days[i]}</div>
                    <div class="date-number">${d.getDate()}</div>
                    <div class="text-muted small">Th\u00e1ng ${d.getMonth() + 1}</div>
                </div>
            `;
        }

        const shifts = [
            { name: 'Ca 1', time: '08:00 - 12:00' },
            { name: 'Ca 2', time: '13:00 - 17:00' }
        ];

        shifts.forEach(shift => {
            scheduleGrid.innerHTML += `
                <div class="schedule-time">
                    <div>
                        <div class="fw-bold">${shift.name}</div>
                        <div class="text-muted small">${shift.time}</div>
                    </div>
                </div>
            `;
            
            for (let i = 0; i < 7; i++) {
                const dateStr = formatDate(weekDates[i]);
                const shiftItems = items.filter(item => {
                    const itemDate = item.workDate;
                    const itemTimeSlot = item.timeSlot;
                    return itemDate === dateStr && itemTimeSlot.includes(shift.time.split(' - ')[0]);
                });
                
                let cellContent = '';
                shiftItems.forEach(item => {
                    let statusClass = 'status-scheduled';
                    let statusText = '\u0110\u00e3 l\u00ean l\u1ecbch';
                    
                    if (item.status === 'Completed' || item.status === 'Checked_In') {
                        statusClass = 'status-completed';
                        statusText = 'Ho\u00e0n th\u00e0nh';
                    } else if (item.status === 'Cancelled' || item.status === 'Absent' || item.status === 'Expired') {
                        statusClass = 'status-cancelled';
                        statusText = '\u0110\u00e3 h\u1ee7y/Qu\u00e1 h\u1ea1n';
                    } else if (item.status === 'Waiting' || item.status === 'In_Progress') {
                        statusClass = 'status-completed';
                        statusText = '\u0110ang tr\u1ef1c';
                    }

                    cellContent += `
                        <div class="schedule-item ${statusClass}">
                            <div class="fw-bold mb-1"><i class="bi bi-clock-history"></i> ${item.timeSlot}</div>
                            <div class="text-secondary small mb-1"><i class="bi bi-person"></i> L\u1ec5 t\u00e2n: ${item.fullName || ''}</div>
                            <div>Tr\u1ea1ng th\u00e1i: <span class="badge ${statusClass === 'status-completed' ? 'bg-success' : (statusClass === 'status-cancelled' ? 'bg-danger' : 'bg-primary')}">${statusText}</span></div>
                        </div>
                    `;
                });
                
                scheduleGrid.innerHTML += `<div class="schedule-cell">${cellContent}</div>`;
            }
        });
    }

    document.getElementById('btnPrevWeek').addEventListener('click', () => {
        currentDate.setDate(currentDate.getDate() - 7);
        loadSchedule();
    });

    document.getElementById('btnNextWeek').addEventListener('click', () => {
        currentDate.setDate(currentDate.getDate() + 7);
        loadSchedule();
    });

    document.getElementById('btnToday').addEventListener('click', () => {
        currentDate = new Date();
        loadSchedule();
    });

    // Xử lý sự kiện đăng ký lịch trực mới
    const registerForm = document.getElementById('registerScheduleForm');
    const modalAlert = document.getElementById('modalAlert');
    const registerModalElement = document.getElementById('registerScheduleModal');
    let registerModal = null;

    if (registerForm) {
        // Cài đặt ngày tối thiểu là ngày hôm nay
        const regWorkDate = document.getElementById('regWorkDate');
        if (regWorkDate) {
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth() + 1).padStart(2, '0');
            const dd = String(today.getDate()).padStart(2, '0');
            regWorkDate.min = `${yyyy}-${mm}-${dd}`;
            regWorkDate.value = `${yyyy}-${mm}-${dd}`;
        }

        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            if (modalAlert) modalAlert.innerHTML = '';
            
            const workDate = document.getElementById('regWorkDate').value;
            const timeSlot = document.getElementById('regTimeSlot').value;
            
            const body = new URLSearchParams();
            body.set('workDate', workDate);
            body.set('timeSlot', timeSlot);
            
            try {
                const response = await fetch(`${window.ReceptionistConfig.apiBase}/my-schedule/register`, {
                    method: 'POST',
                    headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: body.toString()
                });
                
                const data = await response.json();
                if (data.success) {
                    alert(data.message || 'Đăng ký lịch trực thành công.');
                    registerForm.reset();
                    if (regWorkDate) {
                        const today = new Date();
                        const yyyy = today.getFullYear();
                        const mm = String(today.getMonth() + 1).padStart(2, '0');
                        const dd = String(today.getDate()).padStart(2, '0');
                        regWorkDate.value = `${yyyy}-${mm}-${dd}`;
                    }
                    
                    // Đóng modal
                    if (!registerModal && window.bootstrap && window.bootstrap.Modal) {
                        registerModal = window.bootstrap.Modal.getInstance(registerModalElement) || new window.bootstrap.Modal(registerModalElement);
                    }
                    if (registerModal) {
                        registerModal.hide();
                    } else {
                        const closeBtn = registerModalElement.querySelector('.btn-close');
                        if (closeBtn) closeBtn.click();
                    }
                    
                    // Tải lại lịch để hiển thị ca trực mới đăng ký
                    loadSchedule();
                } else {
                    if (modalAlert) {
                        modalAlert.innerHTML = `<div class="alert alert-danger">${data.error || data.message || 'Lỗi không xác định'}</div>`;
                    }
                }
            } catch (error) {
                console.error('Error registering schedule:', error);
                if (modalAlert) {
                    modalAlert.innerHTML = '<div class="alert alert-danger">Lỗi kết nối máy chủ.</div>';
                }
            }
        });
    }

    // Initial load
    loadSchedule();
});
