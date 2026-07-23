(function () {
    const utils = window.ReceptionistUtils;
    const list = document.getElementById('queueList');
    const statusFilter = document.getElementById('queueStatusFilter');

    function statusLabel(status) {
        const map = {
            Waiting: 'Ch\u1EDD kh\u00E1m',
            Checked_In: '\u0110\u00E3 check-in',
            In_Progress: '\u0110ang kh\u00E1m',
            Completed: 'Ho\u00E0n t\u1EA5t',
            Absent: 'V\u1EAFng m\u1EB7t',
            Cancelled: '\u0110\u00E3 h\u1EE7y'
        };
        return map[status] || status || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh';
    }

    function render(items) {
        if (!items || items.length === 0) {
            list.innerHTML = '<div class="empty-state">Kh\u00F4ng c\u00F3 b\u1EC7nh nh\u00E2n trong h\u00E0ng \u0111\u1EE3i ph\u00F9 h\u1EE3p.</div>';
            return;
        }
        list.innerHTML = items.map(function (item) {
            const action = item.status === 'Waiting'
                ? '<button class="btn btn-sm btn-primary queue-check-in" data-appointment-id="' + utils.escapeHtml(item.appointmentId) + '">Check-in</button>'
                : '';
            const revisitBadge = item.revisitDate
                ? '<span class="badge text-bg-warning ms-2"><i class="bi bi-calendar-event"></i> Hẹn tái khám: ' + utils.escapeHtml(item.revisitDate) + '</span>'
                : '';
            return '<div class="queue-row">'
                + '<div><div class="fw-bold">S\u1ED1 ' + utils.escapeHtml(item.queueNumber) + ' - ' + utils.escapeHtml(item.patientName) + '</div>'
                + '<div class="muted-text">' + utils.escapeHtml(item.phone) + ' | ' + utils.escapeHtml(item.doctorName) + ' | ' + utils.escapeHtml(item.appointmentTime) + '</div></div>'
                + '<div class="d-flex align-items-center gap-2">'
                + revisitBadge
                + '<span class="badge text-bg-info">' + utils.escapeHtml(statusLabel(item.status)) + '</span>'
                + action
                + '</div>'
                + '</div>';
        }).join('');
    }

    async function loadQueue() {
        list.innerHTML = '<div class="empty-state">\u0110ang t\u1EA3i h\u00E0ng \u0111\u1EE3i...</div>';
        try {
            const status = statusFilter.value;
            const url = utils.apiBase() + '/queue' + (status ? '?status=' + encodeURIComponent(status) : '');
            const data = await utils.requestJson(url);
            render(data.items || []);
        } catch (error) {
            list.innerHTML = '<div class="empty-state text-danger">' + utils.escapeHtml(error.message) + '</div>';
        }
    }

    async function checkIn(appointmentId) {
        const body = new URLSearchParams();
        body.set('appointmentId', appointmentId);
        await utils.requestJson(utils.apiBase() + '/queue/check-in', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: body.toString()
        });
        await loadQueue();
    }

    list.addEventListener('click', async function (event) {
        const button = event.target.closest('.queue-check-in');
        if (!button) return;
        button.disabled = true;
        button.textContent = '\u0110ang check-in...';
        try {
            await checkIn(button.dataset.appointmentId);
        } catch (error) {
            alert(error.message);
            button.disabled = false;
            button.textContent = 'Check-in';
        }
    });

    statusFilter.addEventListener('change', loadQueue);
    document.getElementById('reloadQueueBtn').addEventListener('click', loadQueue);
    document.addEventListener('DOMContentLoaded', loadQueue);
})();
