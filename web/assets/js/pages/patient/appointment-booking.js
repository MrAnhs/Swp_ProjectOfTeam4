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
        return schedule.roomName || "Chưa phân phòng";
    }

    function roomLocation(schedule) {
        return schedule.roomLocation || "Chưa cập nhật vị trí";
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
        doctorList.textContent = "Vui lòng chọn khoa khám trước để hệ thống lọc bác sĩ và ca khám phù hợp.";
        doctorCount.innerHTML = '<i class="bi bi-hospital"></i><span>Chưa chọn khoa</span>';
        filterDescription.textContent = "Sau khi chọn khoa, hệ thống sẽ lọc lịch theo ngày, buổi khám và tên bác sĩ.";
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
        availability.textContent = `Còn ${schedule.availableSlots} chỗ`;

        const room = document.createElement("small");
        room.className = "doctor-time-room";
        room.textContent = `Phòng: ${roomLabel(schedule)}`;

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
        name.textContent = doctor.fullName || "Bác sĩ";
        const department = document.createElement("p");
        department.textContent = `Chuyên khoa: ${doctor.department || "Chưa cập nhật"}`;
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
        headingTitle.textContent = "Giờ khám còn trống";
        const headingHint = document.createElement("span");
        headingHint.textContent = "Chọn một khung giờ để đặt lịch";
        heading.append(headingTitle, headingHint);
        scheduleArea.append(heading);

        const morningSchedules = doctor.schedules.filter((schedule) => isMorning(schedule.timeSlot));
        const afternoonSchedules = doctor.schedules.filter((schedule) => !isMorning(schedule.timeSlot));
        if (morningSchedules.length) {
            scheduleArea.append(createScheduleGroup("Buổi sáng", "bi bi-sun", doctor, morningSchedules));
        }
        if (afternoonSchedules.length) {
            scheduleArea.append(createScheduleGroup("Buổi chiều", "bi bi-sunset", doctor, afternoonSchedules));
        }

        const footer = document.createElement("div");
        footer.className = "doctor-booking-card__footer";
        const cardMessage = document.createElement("p");
        cardMessage.className = "doctor-card-message";
        cardMessage.hidden = true;

        const bookButton = document.createElement("button");
        bookButton.type = "button";
        bookButton.className = "btn-page-primary doctor-book-button";
        bookButton.innerHTML = 'Xác nhận đặt lịch <i class="bi bi-arrow-right"></i>';
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
        countText.textContent = `Tìm thấy ${data.doctorCount} bác sĩ phù hợp`;
        doctorCount.append(countText);
        filterDescription.textContent = `Khoa ${data.department}, lịch còn trống ngày ${formatDate(data.date)} theo bộ lọc đã chọn.`;

        if (!data.doctors.length) {
            const empty = document.createElement("div");
            empty.className = "booking-empty-state";
            empty.innerHTML = '<i class="bi bi-calendar-x"></i>';
            const title = document.createElement("strong");
            title.textContent = "Không tìm thấy lịch khám phù hợp";
            const description = document.createElement("p");
            description.textContent = "Bạn hãy thử chọn ngày khác, đổi buổi khám hoặc xóa tên bác sĩ.";
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
            placeholder.textContent = "Chọn khoa khám";
            departmentSelect.append(placeholder);
            (data.departments || []).forEach((department) => {
                const option = document.createElement("option");
                option.value = department;
                option.textContent = department;
                departmentSelect.append(option);
            });
        } catch (error) {
            doctorList.textContent = `Không thể tải danh sách khoa: ${error.message}`;
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
        doctorList.textContent = "Đang tải các bác sĩ có lịch trống...";
        doctorCount.textContent = "Đang tải";
        filterDescription.textContent = "Đang kiểm tra lịch khám...";

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
            doctorList.textContent = `Không thể tải lịch khám: ${error.message}`;
            doctorCount.textContent = "Không thể tải dữ liệu";
        }
    }

    async function bookAppointment(doctor, card, cardMessage, bookButton) {
        const selectedSchedule = card.querySelector('input[name="scheduleId"]:checked');
        if (!selectedSchedule) {
            cardMessage.hidden = false;
            cardMessage.className = "doctor-card-message error";
            cardMessage.textContent = "Vui lòng chọn một giờ khám trước khi đặt lịch.";
            return;
        }

        cardMessage.hidden = true;
        cardMessage.textContent = "";
        bookButton.disabled = true;
        bookButton.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Đang đặt lịch...';

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
            bookButton.innerHTML = 'Xác nhận đặt lịch <i class="bi bi-arrow-right"></i>';
        }
    }

    function renderBookingResult(data) {
        resultPanel.replaceChildren();
        resultPanel.hidden = false;
        const title = document.createElement("h2");
        title.textContent = "Đặt lịch thành công";
        const description = document.createElement("p");
        description.textContent = "Lịch hẹn đã được tạo và đang ở trạng thái chờ khám.";
        const grid = document.createElement("div");
        grid.className = "booking-result-grid";
        [
            ["Mã lịch hẹn", `#${data.appointmentId}`],
            ["Bác sĩ", data.doctorName],
            ["Chuyên khoa", data.department || "Chưa cập nhật"],
            ["Ngày giờ", data.appointmentTime.replace("T", " ")],
            ["Ca khám", data.timeSlot],
            ["Phòng khám", data.roomName || "Chưa phân phòng"],
            ["Vị trí", data.roomLocation || "Chưa cập nhật"],
            ["Số thứ tự", data.queueNumber]
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
        detailLink.innerHTML = '<i class="bi bi-eye"></i> Xem lịch hẹn';
        const chatLink = document.createElement("a");
        chatLink.className = "btn-page-secondary";
        chatLink.href = ApiClient.buildUrl(`/patient/ai-chat?appointmentId=${data.appointmentId}`);
        chatLink.innerHTML = '<i class="bi bi-chat-dots"></i> Trao đổi với AI';
        const actions = document.createElement("div");
        actions.className = "form-actions appointment-actions";
        actions.append(detailLink, chatLink);
        resultPanel.append(title, description, grid, actions);
        setWorkflowStep(4);
        resultPanel.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    departmentSelect.addEventListener("change", loadDoctors);
    dateInput.addEventListener("change", () => {
        const today = todayValue();
        if (dateInput.value && dateInput.value < today) {
            alert("Ngày hẹn khám không được chọn ngày đã qua!");
            dateInput.value = today;
        }
        loadDoctors();
    });
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