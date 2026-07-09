(function () {
    const appointmentId = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("appointmentTitle");
    const meta = document.getElementById("appointmentMeta");
    const detail = document.getElementById("appointmentDetail");

    function formatDateTime(value) {
        if (!value) return "Chưa cập nhật";
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
        content.textContent = value || "Chưa cập nhật";
        item.append(name, content);
        return item;
    }

    function render(appointment) {
        const status = PatientAppointmentStatus.get(appointment.status);
        title.textContent = `Lịch hẹn #${appointment.appointmentId}`;
        meta.textContent = `${formatDateTime(appointment.appointmentTime)} | ${status.label}`;
        detail.replaceChildren();
        detail.className = "";

        const badge = document.createElement("span");
        badge.className = `status-pill ${status.className}`;
        badge.textContent = status.label;

        const grid = document.createElement("div");
        grid.className = "appointment-detail-grid";
        grid.append(
            createDetailItem("Bác sĩ", appointment.doctorName),
            createDetailItem("Chuyên khoa", appointment.department),
            createDetailItem("Ngày giờ khám", formatDateTime(appointment.appointmentTime)),
            createDetailItem("Ca khám", appointment.timeSlot),
            createDetailItem("Số thứ tự", String(appointment.queueNumber)),
            createDetailItem("Hình thức đặt", appointment.bookingType === "Online" ? "Trực tuyến" : "Tại quầy"),
            createDetailItem("Email bác sĩ", appointment.doctorEmail),
            createDetailItem("Số điện thoại bác sĩ", appointment.doctorPhone),
            createDetailItem("Mã ca khám", String(appointment.scheduleId))
        );

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-primary";
        chatLink.href = ApiClient.buildUrl(
                `/patient/ai-chat?appointmentId=${appointment.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao đổi với AI';
        actions.append(chatLink);

        detail.append(badge, grid, actions);
    }

    if (!Number.isInteger(appointmentId) || appointmentId <= 0) {
        detail.textContent = "Mã lịch hẹn không hợp lệ.";
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
