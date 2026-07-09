(function () {
    const appointmentId = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("appointmentTitle");
    const meta = document.getElementById("appointmentMeta");
    const detail = document.getElementById("appointmentDetail");

    function formatDateTime(value) {
        if (!value) return "Ch\u01B0a c\u1EADp nh\u1EADt";
        const date = new Date(value);
        return Number.isNaN(date.getTime())
            ? value.replace("T", " ")
            : date.toLocaleString("vi-VN");
    }

    function createDetailItem(label, value) {
        const item = document.createElement("div");
        item.className = "appointment-detail-item";
        const name = document.createElement("span");
        name.textContent = label;
        const content = document.createElement("strong");
        content.textContent = value || "Ch\u01B0a c\u1EADp nh\u1EADt";
        item.append(name, content);
        return item;
    }

    function render(appointment) {
        const status = PatientAppointmentStatus.get(appointment.status);
        title.textContent = `L\u1ECBch h\u1EB9n #${appointment.appointmentId}`;
        meta.textContent = `${formatDateTime(appointment.appointmentTime)} | ${status.label}`;
        detail.replaceChildren();
        detail.className = "";

        const badge = document.createElement("span");
        badge.className = `status-pill ${status.className}`;
        badge.textContent = status.label;

        const grid = document.createElement("div");
        grid.className = "appointment-detail-grid";
        grid.append(
            createDetailItem("B\u00E1c s\u0129", appointment.doctorName),
            createDetailItem("Chuy\u00EAn khoa", appointment.department),
            createDetailItem("Ng\u00E0y gi\u1EDD kh\u00E1m", formatDateTime(appointment.appointmentTime)),
            createDetailItem("Ca kh\u00E1m", appointment.timeSlot),
            createDetailItem("S\u1ED1 th\u1EE9 t\u1EF1", String(appointment.queueNumber)),
            createDetailItem("H\u00ECnh th\u1EE9c \u0111\u1EB7t", appointment.bookingType === "Online" ? "Tr\u1EF1c tuy\u1EBFn" : "T\u1EA1i qu\u1EA7y"),
            createDetailItem("Email b\u00E1c s\u0129", appointment.doctorEmail),
            createDetailItem("S\u1ED1 \u0111i\u1EC7n tho\u1EA1i b\u00E1c s\u0129", appointment.doctorPhone),
            createDetailItem("M\u00E3 ca kh\u00E1m", String(appointment.scheduleId))
        );

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-primary";
        chatLink.href = ApiClient.buildUrl(
                `/patient/ai-chat?appointmentId=${appointment.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao \u0111\u1ED5i v\u1EDBi AI';
        actions.append(chatLink);

        detail.append(badge, grid, actions);
    }

    if (!Number.isInteger(appointmentId) || appointmentId <= 0) {
        detail.textContent = "M\u00E3 l\u1ECBch h\u1EB9n kh\u00F4ng h\u1EE3p l\u1EC7.";
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
