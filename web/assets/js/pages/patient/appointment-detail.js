(function () {
    const appointmentId = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("appointmentTitle");
    const meta = document.getElementById("appointmentMeta");
    const detail = document.getElementById("appointmentDetail");

    function formatDateTime(value) {
        if (!value) return "Ch\u01b0a c\u1eadp nh\u1eadt";
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? value.replace("T", " ") : date.toLocaleString("vi-VN");
    }

    function createDetailItem(label, value) {
        const item = document.createElement("div");
        item.className = "appointment-detail-item";
        const name = document.createElement("span");
        name.textContent = label;
        const content = document.createElement("strong");
        content.textContent = value || "Ch\u01b0a c\u1eadp nh\u1eadt";
        item.append(name, content);
        return item;
    }

    function render(appointment) {
        const status = PatientAppointmentStatus.get(appointment.status);
        title.textContent = `L\u1ecbch h\u1eb9n #${appointment.appointmentId}`;
        meta.textContent = `${formatDateTime(appointment.appointmentTime)} | ${status.label}`;
        detail.replaceChildren();
        detail.className = "";

        const badge = document.createElement("span");
        badge.className = `status-pill ${status.className}`;
        badge.textContent = status.label;

        const grid = document.createElement("div");
        grid.className = "appointment-detail-grid";
        grid.append(
            createDetailItem("B\u00e1c s\u0129", appointment.doctorName),
            createDetailItem("Chuy\u00ean khoa", appointment.department),
            createDetailItem("Ng\u00e0y gi\u1edd kh\u00e1m", formatDateTime(appointment.appointmentTime)),
            createDetailItem("Ca kh\u00e1m", appointment.timeSlot),
            createDetailItem("Ph\u00f2ng kh\u00e1m", appointment.roomName || "Ch\u01b0a ph\u00e2n ph\u00f2ng"),
            createDetailItem("V\u1ecb tr\u00ed ph\u00f2ng", appointment.roomLocation || "Ch\u01b0a c\u1eadp nh\u1eadt"),
            createDetailItem("S\u1ed1 th\u1ee9 t\u1ef1", String(appointment.queueNumber)),
            createDetailItem("H\u00ecnh th\u1ee9c \u0111\u1eb7t", appointment.bookingType === "Online" ? "Tr\u1ef1c tuy\u1ebfn" : "T\u1ea1i qu\u1ea7y"),
            createDetailItem("Email b\u00e1c s\u0129", appointment.doctorEmail),
            createDetailItem("S\u1ed1 \u0111i\u1ec7n tho\u1ea1i b\u00e1c s\u0129", appointment.doctorPhone),
            createDetailItem("M\u00e3 ca kh\u00e1m", String(appointment.scheduleId))
        );

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-primary";
        chatLink.href = ApiClient.buildUrl(`/patient/ai-chat?appointmentId=${appointment.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao \u0111\u1ed5i v\u1edbi AI';
        actions.append(chatLink);
        detail.append(badge, grid, actions);
    }

    if (!Number.isInteger(appointmentId) || appointmentId <= 0) {
        detail.textContent = "M\u00e3 l\u1ecbch h\u1eb9n kh\u00f4ng h\u1ee3p l\u1ec7.";
        meta.textContent = "";
        return;
    }

    ApiClient.get(`/patient/api/appointments?id=${appointmentId}`)
        .then((data) => render(data.appointment))
        .catch((error) => {
            detail.textContent = error.message;
            meta.textContent = "";
        });
})();