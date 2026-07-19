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

        detail.append(badge, grid);

        if (appointment.laboratoryRooms) {
            const labNotice = document.createElement("section");
            labNotice.className = "appointment-lab-notice";
            const labTitle = document.createElement("h3");
            labTitle.innerHTML = '<i class="bi bi-droplet-half"></i> Th\u00f4ng tin x\u00e9t nghi\u1ec7m';
            const labGrid = document.createElement("div");
            labGrid.className = "appointment-detail-grid";
            labGrid.append(
                createDetailItem("Ph\u00f2ng x\u00e9t nghi\u1ec7m", appointment.laboratoryRooms),
                createDetailItem("V\u1ecb tr\u00ed c\u1ea7n \u0111\u1ebfn", appointment.laboratoryRoomLocations)
            );
            labNotice.append(labTitle, labGrid);
            detail.append(labNotice);
        }

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-primary";
        chatLink.href = ApiClient.buildUrl(`/patient/ai-chat?appointmentId=${appointment.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao \u0111\u1ed5i v\u1edbi AI';
        actions.append(chatLink);

        if (appointment.status === "Waiting") {
            const cancelBtn = document.createElement("button");
            cancelBtn.type = "button";
            cancelBtn.className = "btn-page-danger";
            cancelBtn.innerHTML = '<i class="bi bi-x-circle"></i> H\u1ee7y l\u1ecbch h\u1eb9n';
            cancelBtn.addEventListener("click", () => {
                const now = new Date();
                const apptTime = new Date(appointment.appointmentTime);
                const diffHours = (apptTime - now) / (1000 * 60 * 60);

                if (diffHours < 24) {
                    alert("L\u1ecbch h\u1eb9n c\u00f2n \u00edt h\u01a1n 24 gi\u1edd tr\u01b0\u1edbc gi\u1edd kh\u00e1m. Vui l\u00f2ng li\u00ea\u006e h\u1ec7 Hotline b\u1ec7nh vi\u1ec7n (1900 xxxx) \u0111\u1ec3 \u0111\u01b0\u1ee3c h\u1ed7 tr\u1ee3 h\u1ee7y l\u1ecbch.");
                } else {
                    if (confirm("B\u1ea1n c\u00f3 ch\u1eafc ch\u1eafn mu\u1ed1n h\u1ee7y l\u1ecbch h\u1eb9n n\u00e0y kh\u00f4ng?")) {
                        cancelBtn.disabled = true;
                        ApiClient.postForm("/patient/api/appointments", new URLSearchParams({
                            action: "cancel",
                            id: appointment.appointmentId
                        }))
                        .then(() => {
                            alert("\u0110\u00e3 h\u1ee7y l\u1ecbch h\u1eb9n th\u00e0nh c\u00f4ng.");
                            window.location.reload();
                        })
                        .catch((error) => {
                            alert(error.message || "Kh\u00f4ng th\u1ec3 h\u1ee7y l\u1ecbch h\u1eb9n. Vui l\u00f2ng th\u1eed l\u1ea1i.");
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
