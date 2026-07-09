(function () {
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
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, "0");
        const day = String(today.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
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
        availability.textContent = `C\u00F2n ${schedule.availableSlots} ch\u1ED7`;

        input.addEventListener("change", () => {
            setWorkflowStep(3);
            document.querySelectorAll(".doctor-time-slot").forEach((slot) => {
                slot.classList.toggle("active", slot.contains(input));
            });
            document.querySelectorAll(".doctor-booking-card").forEach((card) => {
                card.classList.toggle(
                    "active",
                    String(card.dataset.doctorId) === String(doctor.doctorId)
                );
            });
            document.querySelectorAll(".doctor-card-message").forEach((cardMessage) => {
                cardMessage.hidden = true;
                cardMessage.textContent = "";
            });
        });

        label.append(input, time, availability);
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
        schedules.forEach((schedule) => {
            slots.append(createScheduleButton(doctor, schedule));
        });

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
        name.textContent = doctor.fullName || "B\u00E1c s\u0129";
        const department = document.createElement("p");
        department.textContent = `Chuy\u00EAn khoa: ${doctor.department || "Ch\u01B0a c\u1EADp nh\u1EADt"}`;
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
        headingTitle.textContent = "Gi\u1EDD kh\u00E1m c\u00F2n tr\u1ED1ng";
        const headingHint = document.createElement("span");
        headingHint.textContent = "Ch\u1ECDn m\u1ED9t khung gi\u1EDD \u0111\u1EC3 \u0111\u1EB7t l\u1ECBch";
        heading.append(headingTitle, headingHint);
        scheduleArea.append(heading);

        const morningSchedules = doctor.schedules.filter(
            (schedule) => isMorning(schedule.timeSlot)
        );
        const afternoonSchedules = doctor.schedules.filter(
            (schedule) => !isMorning(schedule.timeSlot)
        );
        if (morningSchedules.length) {
            scheduleArea.append(createScheduleGroup(
                "Bu\u1ED5i s\u00E1ng", "bi bi-sun", doctor, morningSchedules
            ));
        }
        if (afternoonSchedules.length) {
            scheduleArea.append(createScheduleGroup(
                "Bu\u1ED5i chi\u1EC1u", "bi bi-sunset", doctor, afternoonSchedules
            ));
        }

        const footer = document.createElement("div");
        footer.className = "doctor-booking-card__footer";
        const cardMessage = document.createElement("p");
        cardMessage.className = "doctor-card-message";
        cardMessage.hidden = true;

        const bookButton = document.createElement("button");
        bookButton.type = "button";
        bookButton.className = "btn-page-primary doctor-book-button";
        bookButton.innerHTML = 'X\u00E1c nh\u1EADn \u0111\u1EB7t l\u1ECBch <i class="bi bi-arrow-right"></i>';
        bookButton.addEventListener("click", () => {
            bookAppointment(doctor, card, cardMessage, bookButton);
        });

        footer.append(cardMessage, bookButton);
        card.append(header, scheduleArea, footer);
        return card;
    }

    function renderDoctors(data) {
        doctorList.replaceChildren();
        doctorList.className = "doctor-booking-list";
        doctorCount.innerHTML = '<i class="bi bi-people"></i>';
        const countText = document.createElement("span");
        countText.textContent = `T\u00ECm th\u1EA5y ${data.doctorCount} b\u00E1c s\u0129 ph\u00F9 h\u1EE3p`;
        doctorCount.append(countText);
        filterDescription.textContent =
            `L\u1ECBch c\u00F2n tr\u1ED1ng ng\u00E0y ${formatDate(data.date)} theo b\u1ED9 l\u1ECDc \u0111\u00E3 ch\u1ECDn.`;

        if (!data.doctors.length) {
            const empty = document.createElement("div");
            empty.className = "booking-empty-state";
            empty.innerHTML = '<i class="bi bi-calendar-x"></i>';
            const title = document.createElement("strong");
            title.textContent = "Kh\u00F4ng t\u00ECm th\u1EA5y l\u1ECBch kh\u00E1m ph\u00F9 h\u1EE3p";
            const description = document.createElement("p");
            description.textContent =
                "B\u1EA1n h\u00E3y th\u1EED ch\u1ECDn ng\u00E0y kh\u00E1c, \u0111\u1ED5i bu\u1ED5i kh\u00E1m ho\u1EB7c x\u00F3a t\u00EAn b\u00E1c s\u0129.";
            empty.append(title, description);
            doctorList.append(empty);
            return;
        }

        data.doctors.forEach((doctor) => {
            doctorList.append(createDoctorCard(doctor, data.date));
        });
    }

    async function loadDoctors() {
        const requestSequence = ++doctorRequestSequence;
        setWorkflowStep(2);
        doctorList.className = "doctor-booking-list loading-state";
        doctorList.textContent = "\u0110ang t\u1EA3i c\u00E1c b\u00E1c s\u0129 c\u00F3 l\u1ECBch tr\u1ED1ng...";
        doctorCount.textContent = "\u0110ang t\u1EA3i";
        filterDescription.textContent = "\u0110ang ki\u1EC3m tra l\u1ECBch kh\u00E1m...";

        const query = new URLSearchParams({
            date: dateInput.value,
            session: sessionSelect.value
        });
        const doctorName = doctorNameInput.value.trim();
        if (doctorName) {
            query.set("name", doctorName);
        }

        try {
            const data = await ApiClient.get(`/patient/api/doctors?${query}`);
            if (requestSequence !== doctorRequestSequence) {
                return;
            }
            renderDoctors(data);
        } catch (error) {
            if (requestSequence !== doctorRequestSequence) {
                return;
            }
            doctorList.className = "doctor-booking-list loading-state";
            doctorList.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i l\u1ECBch kh\u00E1m: ${error.message}`;
            doctorCount.textContent = "Kh\u00F4ng th\u1EC3 t\u1EA3i d\u1EEF li\u1EC7u";
        }
    }

    async function bookAppointment(doctor, card, cardMessage, bookButton) {
        const selectedSchedule = card.querySelector(
            'input[name="scheduleId"]:checked'
        );
        if (!selectedSchedule) {
            cardMessage.hidden = false;
            cardMessage.className = "doctor-card-message error";
            cardMessage.textContent = "Vui l\u00F2ng ch\u1ECDn m\u1ED9t gi\u1EDD kh\u00E1m tr\u01B0\u1EDBc khi \u0111\u1EB7t l\u1ECBch.";
            return;
        }

        cardMessage.hidden = true;
        cardMessage.textContent = "";
        bookButton.disabled = true;
        bookButton.innerHTML = '<span class="spinner-border spinner-border-sm"></span> \u0110ang \u0111\u1EB7t l\u1ECBch...';

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
            bookButton.innerHTML = 'X\u00E1c nh\u1EADn \u0111\u1EB7t l\u1ECBch <i class="bi bi-arrow-right"></i>';
        }
    }

    function renderBookingResult(data) {
        resultPanel.replaceChildren();
        resultPanel.hidden = false;

        const title = document.createElement("h2");
        title.textContent = "\u0110\u1EB7t l\u1ECBch th\u00E0nh c\u00F4ng";
        const description = document.createElement("p");
        description.textContent = "L\u1ECBch h\u1EB9n \u0111\u00E3 \u0111\u01B0\u1EE3c t\u1EA1o v\u00E0 \u0111ang \u1EDF tr\u1EA1ng th\u00E1i ch\u1EDD kh\u00E1m.";

        const grid = document.createElement("div");
        grid.className = "booking-result-grid";
        [
            ["M\u00E3 l\u1ECBch h\u1EB9n", `#${data.appointmentId}`],
            ["B\u00E1c s\u0129", data.doctorName],
            ["Chuy\u00EAn khoa", data.department || "Ch\u01B0a c\u1EADp nh\u1EADt"],
            ["Ng\u00E0y gi\u1EDD", data.appointmentTime.replace("T", " ")],
            ["Ca kh\u00E1m", data.timeSlot],
            ["S\u1ED1 th\u1EE9 t\u1EF1", data.queueNumber]
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
        detailLink.href = ApiClient.buildUrl(
            `/patient/appointments/detail?id=${data.appointmentId}`
        );
        detailLink.innerHTML = '<i class="bi bi-eye"></i> Xem l\u1ECBch h\u1EB9n';

        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-secondary";
        chatLink.href = ApiClient.buildUrl(
            `/patient/ai-chat?appointmentId=${data.appointmentId}`
        );
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao \u0111\u1ED5i v\u1EDBi AI';

        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        actions.append(detailLink, chatLink);
        resultPanel.append(title, description, grid, actions);
        setWorkflowStep(4);
        resultPanel.scrollIntoView({ behavior: "smooth", block: "start" });
    }

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
    loadDoctors();
})();
