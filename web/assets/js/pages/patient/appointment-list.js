(function () {
    const list = document.getElementById("appointmentList");
    const statusFilter = document.getElementById("appointmentStatusFilter");
    const searchInput = document.getElementById("appointmentSearch");
    const dateFilter = document.getElementById("appointmentDateFilter");
    let appointments = [];

    function formatDateTime(value) {
        if (!value) return "Ch\u01b0a c\u1eadp nh\u1eadt";
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? value.replace("T", " ") : date.toLocaleString("vi-VN");
    }

    function roomText(appointment) {
        const room = appointment.roomName || "Ch\u01b0a ph\u00e2n ph\u00f2ng";
        const location = appointment.roomLocation || "Ch\u01b0a c\u1eadp nh\u1eadt v\u1ecb tr\u00ed";
        return `Ph\u00f2ng kh\u00e1m: ${room} | V\u1ecb tr\u00ed: ${location}`;
    }

    function render() {
        const status = statusFilter.value;
        const query = searchInput.value.trim().toLowerCase();
        const visible = appointments.filter((appointment) => {
            const matchesStatus = !status || appointment.status === status;
            const haystack = `${appointment.appointmentId} ${appointment.doctorName} ${appointment.department} ${appointment.roomName} ${appointment.roomLocation} ${appointment.laboratoryRooms} ${appointment.laboratoryRoomLocations}`.toLowerCase();
            return matchesStatus && (!query || haystack.includes(query));
        });

        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Kh\u00f4ng t\u00ecm th\u1ea5y l\u1ecbch h\u1eb9n ph\u00f9 h\u1ee3p.";
            return;
        }

        visible.forEach((appointment) => {
            const item = document.createElement("article");
            item.className = "record-item appointment-item";

            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `L\u1ecbch h\u1eb9n #${appointment.appointmentId}`;

            const doctor = document.createElement("p");
            doctor.textContent = `${appointment.doctorName} - ${appointment.department || "Ch\u01b0a c\u1eadp nh\u1eadt chuy\u00ean khoa"}`;

            const time = document.createElement("p");
            time.textContent = `Th\u1eddi gian: ${formatDateTime(appointment.appointmentTime)} | Ca: ${appointment.timeSlot}`;

            const room = document.createElement("p");
            room.textContent = roomText(appointment);

            const queue = document.createElement("p");
            queue.textContent = `S\u1ed1 th\u1ee9 t\u1ef1: ${appointment.queueNumber}`;

            const laboratoryRoom = document.createElement("p");
            laboratoryRoom.className = "appointment-lab-summary";
            laboratoryRoom.hidden = !appointment.laboratoryRooms;
            laboratoryRoom.textContent = appointment.laboratoryRooms
                ? `Ph\u00f2ng x\u00e9t nghi\u1ec7m: ${appointment.laboratoryRooms} | V\u1ecb tr\u00ed: ${appointment.laboratoryRoomLocations || "Ch\u01b0a c\u1eadp nh\u1eadt"}`
                : "";

            const statusMeta = PatientAppointmentStatus.get(appointment.status);
            const badge = document.createElement("span");
            badge.className = `status-pill ${statusMeta.className}`;
            badge.textContent = statusMeta.label;

            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/appointments/detail?id=${appointment.appointmentId}`);
            link.textContent = "Xem chi ti\u1ebft";

            info.append(title, doctor, time, room, laboratoryRoom, queue, badge);
            item.append(info, link);
            list.append(item);
        });
    }

    statusFilter.addEventListener("change", render);
    searchInput.addEventListener("input", render);
    dateFilter.addEventListener("change", loadAppointments);

    function loadAppointments() {
        const query = dateFilter.value
            ? `?searchDate=${encodeURIComponent(dateFilter.value)}` : "";
        list.classList.add("loading-state");
        ApiClient.get(`/patient/api/appointments${query}`)
            .then((data) => {
                appointments = data.appointments || [];
                render();
            })
            .catch((error) => {
                list.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i l\u1ecbch h\u1eb9n: ${error.message}`;
            })
            .finally(() => list.classList.remove("loading-state"));
    }

    loadAppointments();
})();
