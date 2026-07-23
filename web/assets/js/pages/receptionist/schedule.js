document.addEventListener('DOMContentLoaded', () => {
    const scheduleGrid = document.getElementById('scheduleGrid');
    const selectYear = document.getElementById('selectYear');
    const selectWeek = document.getElementById('selectWeek');
    
    let currentDate = new Date();
    let weeksList = [];

    function formatDate(date) {
        const d = new Date(date);
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        const year = d.getFullYear();

        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;

        return [year, month, day].join('-');
    }

    function isToday(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
            d1.getMonth() === d2.getMonth() &&
            d1.getDate() === d2.getDate();
    }

    function getWeeksOfYear(year) {
        const weeks = [];
        let date = new Date(year, 0, 1);
        
        // Find the first Monday of the year (standard ISO week starting on Monday)
        const day = date.getDay();
        const diff = (day === 0 ? -6 : 1) - day;
        date.setDate(date.getDate() + diff);
        
        while (date.getFullYear() <= year || (date.getFullYear() === year + 1 && date.getMonth() === 0 && date.getDate() <= 7)) {
            const startOfWeek = new Date(date);
            const endOfWeek = new Date(startOfWeek);
            endOfWeek.setDate(startOfWeek.getDate() + 6);
            
            const formatWeekPart = (d) => {
                const dayStr = String(d.getDate()).padStart(2, '0');
                const monthStr = String(d.getMonth() + 1).padStart(2, '0');
                return `${dayStr}/${monthStr}`;
            };
            
            weeks.push({
                start: startOfWeek,
                end: endOfWeek,
                label: `${formatWeekPart(startOfWeek)} To ${formatWeekPart(endOfWeek)}`
            });
            
            date.setDate(date.getDate() + 7);
        }
        return weeks;
    }

    function populateWeeks(year) {
        selectWeek.innerHTML = '';
        weeksList = getWeeksOfYear(year);
        
        weeksList.forEach((wk, idx) => {
            const opt = document.createElement('option');
            opt.value = idx;
            opt.textContent = wk.label;
            selectWeek.appendChild(opt);
        });
    }

    function selectCurrentWeek() {
        const now = new Date();
        now.setHours(0, 0, 0, 0);
        
        let selectedIdx = 0;
        for (let i = 0; i < weeksList.length; i++) {
            const wk = weeksList[i];
            const start = new Date(wk.start);
            start.setHours(0, 0, 0, 0);
            const end = new Date(wk.end);
            end.setHours(23, 59, 59, 999);
            
            if (now >= start && now <= end) {
                selectedIdx = i;
                break;
            }
        }
        selectWeek.value = selectedIdx;
        currentDate = weeksList[selectedIdx].start;
    }

    async function loadSchedule() {
        const selectedIdx = parseInt(selectWeek.value, 10);
        if (isNaN(selectedIdx) || !weeksList[selectedIdx]) return;
        
        const startOfWeek = weeksList[selectedIdx].start;
        const endOfWeek = weeksList[selectedIdx].end;

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

    // Initialize Year select
    const currentYearVal = currentDate.getFullYear();
    for (let y = currentYearVal - 2; y <= currentYearVal + 2; y++) {
        const opt = document.createElement('option');
        opt.value = y;
        opt.textContent = y;
        selectYear.appendChild(opt);
    }
    selectYear.value = currentYearVal;

    populateWeeks(currentYearVal);
    selectCurrentWeek();

    selectYear.addEventListener('change', () => {
        const year = parseInt(selectYear.value, 10);
        populateWeeks(year);
        selectWeek.value = 0;
        currentDate = weeksList[0].start;
        loadSchedule();
    });

    selectWeek.addEventListener('change', () => {
        const selectedIdx = parseInt(selectWeek.value, 10);
        currentDate = weeksList[selectedIdx].start;
        loadSchedule();
    });



    loadSchedule();
});
