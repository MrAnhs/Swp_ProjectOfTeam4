(function () {
    const appointmentId = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("appointmentTitle");
    const meta = document.getElementById("appointmentMeta");
    const detail = document.getElementById("appointmentDetail");

    function formatDateTime(value) {
        if (!value) return "Chưa cập nhật";
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? value.replace("T", " ") : date.toLocaleString("vi-VN");
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
            createDetailItem("Phòng khám", appointment.roomName || "Chưa phân phòng"),
            createDetailItem("Vị trí phòng", appointment.roomLocation || "Chưa cập nhật"),
            createDetailItem("Số thứ tự", String(appointment.queueNumber)),
            createDetailItem("Hình thức đặt", appointment.bookingType === "Online" ? "Trực tuyến" : "Tại quầy"),
            createDetailItem("Email bác sĩ", appointment.doctorEmail),
            createDetailItem("Số điện thoại bác sĩ", appointment.doctorPhone),
            createDetailItem("Mã ca khám", String(appointment.scheduleId))
        );

        detail.append(badge, grid);

        if (appointment.laboratoryRooms) {
            const labNotice = document.createElement("section");
            labNotice.className = "appointment-lab-notice";
            const labTitle = document.createElement("h3");
            labTitle.innerHTML = '<i class="bi bi-droplet-half"></i> Thông tin xét nghiệm';
            const labGrid = document.createElement("div");
            labGrid.className = "appointment-detail-grid";
            labGrid.append(
                createDetailItem("Phòng xét nghiệm", appointment.laboratoryRooms),
                createDetailItem("Vị trí cần đến", appointment.laboratoryRoomLocations)
            );
            labNotice.append(labTitle, labGrid);
            detail.append(labNotice);
        }

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-primary";
        chatLink.href = ApiClient.buildUrl(`/patient/ai-chat?appointmentId=${appointment.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao đổi với AI';
        actions.append(chatLink);

        if (appointment.status === "Waiting") {
            const cancelBtn = document.createElement("button");
            cancelBtn.type = "button";
            cancelBtn.className = "btn-page-danger";
            cancelBtn.innerHTML = '<i class="bi bi-x-circle"></i> Hủy lịch hẹn';
            cancelBtn.addEventListener("click", () => {
                const now = new Date();
                const apptTime = new Date(appointment.appointmentTime);
                const diffHours = (apptTime - now) / (1000 * 60 * 60);

                if (diffHours < 24) {
                    alert("Lịch hẹn còn ít hơn 24 giờ trước giờ khám. Vui lòng liên hệ Hotline bệnh viện (1900 xxxx) để được hỗ trợ hủy lịch.");
                } else {
                    if (confirm("Bạn có chắc chắn muốn hủy lịch hẹn này không?")) {
                        cancelBtn.disabled = true;
                        ApiClient.postForm("/patient/api/appointments", new URLSearchParams({
                            action: "cancel",
                            id: appointment.appointmentId
                        }))
                        .then(() => {
                            alert("Đã hủy lịch hẹn thành công.");
                            window.location.reload();
                        })
                        .catch((error) => {
                            alert(error.message || "Không thể hủy lịch hẹn. Vui lòng thử lại.");
                            cancelBtn.disabled = false;
                        });
                    }
                }
            });
            actions.append(cancelBtn);
        }

        detail.append(actions);
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
