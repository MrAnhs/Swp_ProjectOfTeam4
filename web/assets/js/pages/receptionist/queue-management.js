(function () {
    const utils = window.ReceptionistUtils;
    const list = document.getElementById('queueList');
    const statusFilter = document.getElementById('queueStatusFilter');

    function statusLabel(status) {
        const map = {
            Waiting: 'Đang chờ xác nhận',
            Checked_In: 'Đã xác nhận',
            In_Progress: 'Đang khám',
            Completed: 'Hoàn tất',
            Absent: 'Vắng mặt',
            Cancelled: 'Đã hủy'
        };
        return map[status] || status || 'Không xác định';
    }

    function statusBadgeClass(status) {
        switch (status) {
            case 'Waiting': return 'text-bg-warning';
            case 'Checked_In': return 'text-bg-success';
            case 'In_Progress': return 'text-bg-info';
            case 'Completed': return 'text-bg-secondary';
            case 'Absent': return 'text-bg-danger';
            case 'Cancelled': return 'text-bg-dark';
            default: return 'text-bg-info';
        }
    }

    function render(items) {
        if (!items || items.length === 0) {
            list.innerHTML = '<div class="empty-state">Không có bệnh nhân trong hàng đợi phù hợp.</div>';
            return;
        }
        list.innerHTML = items.map(function (item) {
            const action = item.status === 'Waiting'
                ? '<button class="btn btn-sm btn-primary queue-check-in" data-appointment-id="' + utils.escapeHtml(item.appointmentId) + '">Check-in</button>'
                : '';
            const revisitBadge = item.revisitDate
                ? '<span class="badge text-bg-warning ms-2"><i class="bi bi-calendar-event me-1"></i>Hẹn tái khám: ' + utils.escapeHtml(item.revisitDate) + '</span>'
                : '';
            return '<div class="queue-row">'
                + '<div><div class="fw-bold">Số ' + utils.escapeHtml(item.queueNumber) + ' - ' + utils.escapeHtml(item.patientName) + '</div>'
                + '<div class="muted-text">' + utils.escapeHtml(item.phone) + ' | ' + utils.escapeHtml(item.doctorName) + ' | ' + utils.escapeHtml(item.appointmentTime) + '</div></div>'
                + '<div class="d-flex align-items-center gap-2">'
                + revisitBadge
                + '<span class="badge ' + statusBadgeClass(item.status) + '">' + utils.escapeHtml(statusLabel(item.status)) + '</span>'
                + action
                + '</div>'
                + '</div>';
        }).join('');
    }

    async function loadQueue() {
        list.innerHTML = '<div class="empty-state">Đang tải hàng đợi...</div>';
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
        button.textContent = 'Đang check-in...';
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
