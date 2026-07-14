(function () {
    const departmentSelect = document.getElementById("bookingDepartment");
    const dateInput = document.getElementById("bookingDate");
    const sessionSelect = document.getElementById("bookingSession");
    const doctorNameInput = document.getElementById("bookingDoctorName");
    const doctorList = document.getElementById("bookingDoctorList");
    const doctorCount = document.getElementById("bookingDoctorCount");
    const filterDescription = document.getElementById("bookingFilterDescription");
    const stepDate = document.getElementById("bookingStepDate");
    const stepTime = document.getElementById("bookingStepTime");
    const stepConfirm = document.getElementById("bookingStepConfirm");
    const resultPanel = document.getElementById("bookingResult");

    let doctorRequestSequence = 0;
    let searchTimer = null;

    function todayValue() {
        const today = new Date();
        return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
    }

    function formatDate(dateValue, includeWeekday = false) {
        const date = new Date(`${dateValue}T00:00:00`);
        return new Intl.DateTimeFormat("vi-VN", {
            weekday: includeWeekday ? "long" : undefined,
            day: "2-digit",
            month: "2-digit",
            year: "numeric"
        }).format(date);
    }

    function roomLabel(schedule) {
        return schedule.roomName || "Ch\u01b0a ph\u00e2n ph\u00f2ng";
    }

    function roomLocation(schedule) {
        return schedule.roomLocation || "Ch\u01b0a c\u1eadp nh\u1eadt v\u1ecb tr\u00ed";
    }

    function setWorkflowStep(step) {
        [stepDate, stepTime, stepConfirm].forEach((item, index) => {
            const itemStep = index + 1;
            item.classList.toggle("active", itemStep === step);
            item.classList.toggle("completed", itemStep < step);
        });
    }

    function isMorning(timeSlot) {
        const hour = Number.parseInt(timeSlot.substring(0, 2), 10);
        return Number.isFinite(hour) && hour < 12;
    }

    function showDepartmentPrompt() {
        doctorList.className = "doctor-booking-list loading-state";
        doctorList.textContent = "Vui l\u00f2ng ch\u1ecdn khoa kh\u00e1m tr\u01b0\u1edbc \u0111\u1ec3 h\u1ec7 th\u1ed1ng l\u1ecdc b\u00e1c s\u0129 v\u00e0 ca kh\u00e1m ph\u00f9 h\u1ee3p.";
        doctorCount.innerHTML = '<i class="bi bi-hospital"></i><span>Ch\u01b0a ch\u1ecdn khoa</span>';
        filterDescription.textContent = "Sau khi ch\u1ecdn khoa, h\u1ec7 th\u1ed1ng s\u1ebd l\u1ecdc l\u1ecbch theo ng\u00e0y, bu\u1ed5i kh\u00e1m v\u00e0 t\u00ean b\u00e1c s\u0129.";
        setWorkflowStep(1);
    }

    function createScheduleButton(doctor, schedule) {
        const label = document.createElement("label");
        label.className = "doctor-time-slot";

        const input = document.createElement("input");
        input.type = "radio";
        input.name = "scheduleId";
        input.value = schedule.scheduleId;

        const time = document.createElement("strong");
        time.textContent = schedule.timeSlot;

        const availability = document.createElement("small");
        availability.textContent = `C\u00f2n ${schedule.availableSlots} ch\u1ed7`;

        const room = document.createElement("small");
        room.className = "doctor-time-room";
        room.textContent = `Ph\u00f2ng: ${roomLabel(schedule)}`;

        const location = document.createElement("small");
        location.className = "doctor-time-location";
        location.textContent = roomLocation(schedule);

        input.addEventListener("change", () => {
            setWorkflowStep(3);
            document.querySelectorAll(".doctor-time-slot").forEach((slot) => {
                slot.classList.toggle("active", slot.contains(input));
            });
            document.querySelectorAll(".doctor-booking-card").forEach((card) => {
                card.classList.toggle("active", String(card.dataset.doctorId) === String(doctor.doctorId));
            });
            document.querySelectorAll(".doctor-card-message").forEach((message) => {
                message.hidden = true;
                message.textContent = "";
            });
        });

        label.append(input, time, availability, room, location);
        return label;
    }

    function createScheduleGroup(title, iconClass, doctor, schedules) {
        const group = document.createElement("div");
        group.className = "doctor-session-group";

        const heading = document.createElement("h4");
        const icon = document.createElement("i");
        icon.className = iconClass;
        const text = document.createElement("span");
        text.textContent = title;
        heading.append(icon, text);

        const slots = document.createElement("div");
        slots.className = "doctor-time-slots";
        schedules.forEach((schedule) => slots.append(createScheduleButton(doctor, schedule)));

        group.append(heading, slots);
        return group;
    }

    function createDoctorCard(doctor, selectedDate) {
        const card = document.createElement("article");
        card.className = "doctor-booking-card";
        card.dataset.doctorId = doctor.doctorId;

        const header = document.createElement("div");
        header.className = "doctor-booking-card__header";

        const identity = document.createElement("div");
        identity.className = "doctor-booking-card__identity";

        const avatar = document.createElement("span");
        avatar.className = "doctor-avatar doctor-avatar--outline";
        avatar.innerHTML = '<i class="bi bi-person-fill"></i>';

        const info = document.createElement("div");
        const name = document.createElement("h3");
        name.textContent = doctor.fullName || "B\u00e1c s\u0129";
        const department = document.createElement("p");
        department.textContent = `Chuy\u00ean khoa: ${doctor.department || "Ch\u01b0a c\u1eadp nh\u1eadt"}`;
        info.append(name, department);
        identity.append(avatar, info);

        const dateBadge = document.createElement("span");
        dateBadge.className = "doctor-date-badge";
        dateBadge.innerHTML = '<i class="bi bi-calendar-check"></i>';
        const dateText = document.createElement("span");
        dateText.textContent = formatDate(selectedDate, true);
        dateBadge.append(dateText);
        header.append(identity, dateBadge);

        const scheduleArea = document.createElement("div");
        scheduleArea.className = "doctor-booking-card__schedules";

        const heading = document.createElement("div");
        heading.className = "doctor-schedule-heading";
        const headingTitle = document.createElement("strong");
        headingTitle.textContent = "Gi\u1edd kh\u00e1m c\u00f2n tr\u1ed1ng";
        const headingHint = document.createElement("span");
        headingHint.textContent = "Ch\u1ecdn m\u1ed9t khung gi\u1edd \u0111\u1ec3 \u0111\u1eb7t l\u1ecbch";
        heading.append(headingTitle, headingHint);
        scheduleArea.append(heading);

        const morningSchedules = doctor.schedules.filter((schedule) => isMorning(schedule.timeSlot));
        const afternoonSchedules = doctor.schedules.filter((schedule) => !isMorning(schedule.timeSlot));
        if (morningSchedules.length) {
            scheduleArea.append(createScheduleGroup("Bu\u1ed5i s\u00e1ng", "bi bi-sun", doctor, morningSchedules));
        }
        if (afternoonSchedules.length) {
            scheduleArea.append(createScheduleGroup("Bu\u1ed5i chi\u1ec1u", "bi bi-sunset", doctor, afternoonSchedules));
        }

        const footer = document.createElement("div");
        footer.className = "doctor-booking-card__footer";
        const cardMessage = document.createElement("p");
        cardMessage.className = "doctor-card-message";
        cardMessage.hidden = true;

        const bookButton = document.createElement("button");
        bookButton.type = "button";
        bookButton.className = "btn-page-primary doctor-book-button";
        bookButton.innerHTML = 'X\u00e1c nh\u1eadn \u0111\u1eb7t l\u1ecbch <i class="bi bi-arrow-right"></i>';
        bookButton.addEventListener("click", () => bookAppointment(doctor, card, cardMessage, bookButton));

        footer.append(cardMessage, bookButton);
        card.append(header, scheduleArea, footer);
        return card;
    }

    function renderDoctors(data) {
        doctorList.replaceChildren();
        doctorList.className = "doctor-booking-list";
        doctorCount.innerHTML = '<i class="bi bi-people"></i>';
        const countText = document.createElement("span");
        countText.textContent = `T\u00ecm th\u1ea5y ${data.doctorCount} b\u00e1c s\u0129 ph\u00f9 h\u1ee3p`;
        doctorCount.append(countText);
        filterDescription.textContent = `Khoa ${data.department}, l\u1ecbch c\u00f2n tr\u1ed1ng ng\u00e0y ${formatDate(data.date)} theo b\u1ed9 l\u1ecdc \u0111\u00e3 ch\u1ecdn.`;

        if (!data.doctors.length) {
            const empty = document.createElement("div");
            empty.className = "booking-empty-state";
            empty.innerHTML = '<i class="bi bi-calendar-x"></i>';
            const title = document.createElement("strong");
            title.textContent = "Kh\u00f4ng t\u00ecm th\u1ea5y l\u1ecbch kh\u00e1m ph\u00f9 h\u1ee3p";
            const description = document.createElement("p");
            description.textContent = "B\u1ea1n h\u00e3y th\u1eed ch\u1ecdn ng\u00e0y kh\u00e1c, \u0111\u1ed5i bu\u1ed5i kh\u00e1m ho\u1eb7c x\u00f3a t\u00ean b\u00e1c s\u0129.";
            empty.append(title, description);
            doctorList.append(empty);
            return;
        }

        data.doctors.forEach((doctor) => doctorList.append(createDoctorCard(doctor, data.date)));
    }

    async function loadDepartments() {
        departmentSelect.disabled = true;
        try {
            const data = await ApiClient.get("/patient/api/doctors?mode=departments");
            departmentSelect.replaceChildren();
            const placeholder = document.createElement("option");
            placeholder.value = "";
            placeholder.textContent = "Ch\u1ecdn khoa kh\u00e1m";
            departmentSelect.append(placeholder);
            (data.departments || []).forEach((department) => {
                const option = document.createElement("option");
                option.value = department;
                option.textContent = department;
                departmentSelect.append(option);
            });
        } catch (error) {
            doctorList.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i danh s\u00e1ch khoa: ${error.message}`;
        } finally {
            departmentSelect.disabled = false;
        }
    }

    async function loadDoctors() {
        if (!departmentSelect.value) {
            showDepartmentPrompt();
            return;
        }

        const requestSequence = ++doctorRequestSequence;
        setWorkflowStep(2);
        doctorList.className = "doctor-booking-list loading-state";
        doctorList.textContent = "\u0110ang t\u1ea3i c\u00e1c b\u00e1c s\u0129 c\u00f3 l\u1ecbch tr\u1ed1ng...";
        doctorCount.textContent = "\u0110ang t\u1ea3i";
        filterDescription.textContent = "\u0110ang ki\u1ec3m tra l\u1ecbch kh\u00e1m...";

        const query = new URLSearchParams({
            department: departmentSelect.value,
            date: dateInput.value,
            session: sessionSelect.value
        });
        const doctorName = doctorNameInput.value.trim();
        if (doctorName) {
            query.set("name", doctorName);
        }

        try {
            const data = await ApiClient.get(`/patient/api/doctors?${query}`);
            if (requestSequence !== doctorRequestSequence) return;
            renderDoctors(data);
        } catch (error) {
            if (requestSequence !== doctorRequestSequence) return;
            doctorList.className = "doctor-booking-list loading-state";
            doctorList.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i l\u1ecbch kh\u00e1m: ${error.message}`;
            doctorCount.textContent = "Kh\u00f4ng th\u1ec3 t\u1ea3i d\u1eef li\u1ec7u";
        }
    }

    async function bookAppointment(doctor, card, cardMessage, bookButton) {
        const selectedSchedule = card.querySelector('input[name="scheduleId"]:checked');
        if (!selectedSchedule) {
            cardMessage.hidden = false;
            cardMessage.className = "doctor-card-message error";
            cardMessage.textContent = "Vui l\u00f2ng ch\u1ecdn m\u1ed9t gi\u1edd kh\u00e1m tr\u01b0\u1edbc khi \u0111\u1eb7t l\u1ecbch.";
            return;
        }

        cardMessage.hidden = true;
        cardMessage.textContent = "";
        bookButton.disabled = true;
        bookButton.innerHTML = '<span class="spinner-border spinner-border-sm"></span> \u0110ang \u0111\u1eb7t l\u1ecbch...';

        const body = new URLSearchParams({
            doctorId: doctor.doctorId,
            scheduleId: selectedSchedule.value
        });

        try {
            const data = await ApiClient.postForm("/patient/api/appointments", body);
            await loadDoctors();
            renderBookingResult(data);
        } catch (error) {
            cardMessage.hidden = false;
            cardMessage.className = "doctor-card-message error";
            cardMessage.textContent = error.message;
            bookButton.disabled = false;
            bookButton.innerHTML = 'X\u00e1c nh\u1eadn \u0111\u1eb7t l\u1ecbch <i class="bi bi-arrow-right"></i>';
        }
    }

    function renderBookingResult(data) {
        resultPanel.replaceChildren();
        resultPanel.hidden = false;
        const title = document.createElement("h2");
        title.textContent = "\u0110\u1eb7t l\u1ecbch th\u00e0nh c\u00f4ng";
        const description = document.createElement("p");
        description.textContent = "L\u1ecbch h\u1eb9n \u0111\u00e3 \u0111\u01b0\u1ee3c t\u1ea1o v\u00e0 \u0111ang \u1edf tr\u1ea1ng th\u00e1i ch\u1edd kh\u00e1m.";
        const grid = document.createElement("div");
        grid.className = "booking-result-grid";
        [
            ["M\u00e3 l\u1ecbch h\u1eb9n", `#${data.appointmentId}`],
            ["B\u00e1c s\u0129", data.doctorName],
            ["Chuy\u00ean khoa", data.department || "Ch\u01b0a c\u1eadp nh\u1eadt"],
            ["Ng\u00e0y gi\u1edd", data.appointmentTime.replace("T", " ")],
            ["Ca kh\u00e1m", data.timeSlot],
            ["Ph\u00f2ng kh\u00e1m", data.roomName || "Ch\u01b0a ph\u00e2n ph\u00f2ng"],
            ["V\u1ecb tr\u00ed", data.roomLocation || "Ch\u01b0a c\u1eadp nh\u1eadt"],
            ["S\u1ed1 th\u1ee9 t\u1ef1", data.queueNumber]
        ].forEach(([label, value]) => {
            const item = document.createElement("div");
            const name = document.createElement("span");
            name.textContent = label;
            const content = document.createElement("strong");
            content.textContent = value;
            item.append(name, content);
            grid.append(item);
        });

        const detailLink = document.createElement("a");
        detailLink.className = "btn-page-primary";
        detailLink.href = ApiClient.buildUrl(`/patient/appointments/detail?id=${data.appointmentId}`);
        detailLink.innerHTML = '<i class="bi bi-eye"></i> Xem l\u1ecbch h\u1eb9n';
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-secondary";
        chatLink.href = ApiClient.buildUrl(`/patient/ai-chat?appointmentId=${data.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao \u0111\u1ed5i v\u1edbi AI';
        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        actions.append(detailLink, chatLink);
        resultPanel.append(title, description, grid, actions);
        setWorkflowStep(4);
        resultPanel.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    departmentSelect.addEventListener("change", loadDoctors);
    dateInput.addEventListener("change", loadDoctors);
    sessionSelect.addEventListener("change", loadDoctors);
    doctorNameInput.addEventListener("input", () => {
        window.clearTimeout(searchTimer);
        searchTimer = window.setTimeout(loadDoctors, 300);
    });

    const today = todayValue();
    dateInput.min = today;
    dateInput.value = today;
    sessionSelect.value = "all";
    showDepartmentPrompt();
    loadDepartments();
})();