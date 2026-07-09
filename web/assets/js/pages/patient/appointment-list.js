(function () {
    const list = document.getElementById("appointmentList");
    const statusFilter = document.getElementById("appointmentStatusFilter");
    const searchInput = document.getElementById("appointmentSearch");
    let appointments = [];

    function formatDateTime(value) {
        if (!value) return "Ch\u01B0a c\u1EADp nh\u1EADt";
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
            list.textContent = "Kh\u00F4ng t\u00ECm th\u1EA5y l\u1ECBch h\u1EB9n ph\u00F9 h\u1EE3p.";
            return;
        }

        visible.forEach((appointment) => {
            const item = document.createElement("article");
            item.className = "record-item appointment-item";

            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `L\u1ECBch h\u1EB9n #${appointment.appointmentId}`;
            const doctor = document.createElement("p");
            doctor.textContent = `${appointment.doctorName} - ${appointment.department || "Ch\u01B0a c\u1EADp nh\u1EADt chuy\u00EAn khoa"}`;
            const time = document.createElement("p");
            time.textContent = `Th\u1EDDi gian: ${formatDateTime(appointment.appointmentTime)} | Ca: ${appointment.timeSlot}`;
            const queue = document.createElement("p");
            queue.textContent = `S\u1ED1 th\u1EE9 t\u1EF1: ${appointment.queueNumber}`;

            const statusMeta = PatientAppointmentStatus.get(appointment.status);
            const badge = document.createElement("span");
            badge.className = `status-pill ${statusMeta.className}`;
            badge.textContent = statusMeta.label;

            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(
                    `/patient/appointments/detail?id=${appointment.appointmentId}`);
            link.textContent = "Xem chi ti\u1EBFt";

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
            list.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i l\u1ECBch h\u1EB9n: ${error.message}`;
        });
})();
