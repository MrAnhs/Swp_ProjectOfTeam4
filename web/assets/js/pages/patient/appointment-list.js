(function () {
    const list = document.getElementById("appointmentList");
    const statusFilter = document.getElementById("appointmentStatusFilter");
    const searchInput = document.getElementById("appointmentSearch");
    let appointments = [];

    function formatDateTime(value) {
        if (!value) return "Chưa cập nhật";
        const date = new Date(value);
        return Number.isNaN(date.getTime())
            ? value.replace("T", " ")
            : date.toLocaleString("vi-VN");
    }

    function render() {
        const status = statusFilter.value;
        const query = searchInput.value.trim().toLowerCase();
        const visible = appointments.filter((appointment) => {
            const matchesStatus = !status || appointment.status === status;
            const haystack = `${appointment.appointmentId} ${appointment.doctorName} ${appointment.department}`
                    .toLowerCase();
            return matchesStatus && (!query || haystack.includes(query));
        });

        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Không tìm thấy lịch hẹn phù hợp.";
            return;
        }

        visible.forEach((appointment) => {
            const item = document.createElement("article");
            item.className = "record-item appointment-item";

            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `Lịch hẹn #${appointment.appointmentId}`;
            const doctor = document.createElement("p");
            doctor.textContent = `${appointment.doctorName} - ${appointment.department || "Chưa cập nhật chuyên khoa"}`;
            const time = document.createElement("p");
            time.textContent = `Thời gian: ${formatDateTime(appointment.appointmentTime)} | Ca: ${appointment.timeSlot}`;
            const queue = document.createElement("p");
            queue.textContent = `Số thứ tự: ${appointment.queueNumber}`;

            const statusMeta = PatientAppointmentStatus.get(appointment.status);
            const badge = document.createElement("span");
            badge.className = `status-pill ${statusMeta.className}`;
            badge.textContent = statusMeta.label;

            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(
                    `/patient/appointments/detail?id=${appointment.appointmentId}`);
            link.textContent = "Xem chi tiết";

            info.append(title, doctor, time, queue, badge);
            item.append(info, link);
            list.append(item);
        });
    }

    statusFilter.addEventListener("change", render);
    searchInput.addEventListener("input", render);

    ApiClient.get("/patient/api/appointments")
        .then((data) => {
            appointments = data.appointments || [];
            render();
        })
        .catch((error) => {
            list.textContent = `Không thể tải lịch hẹn: ${error.message}`;
        });
})();
