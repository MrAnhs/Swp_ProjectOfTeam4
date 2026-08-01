(function () {
    const list = document.getElementById("visitList");
    const statusFilter = document.getElementById("visitStatusFilter");
    const searchInput = document.getElementById("visitSearch");
    const dateFilter = document.getElementById("visitDateFilter");
    let visits = [];

    function date(value) {
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? value.replace("T", " ") : parsed.toLocaleString("vi-VN");
    }

    function statusMeta(visit) {
        if (visit.resultVisible) {
            return { label: "Đã hoàn thành", className: "completed", filter: "completed" };
        }
        return { label: "Đang xử lý", className: "waiting", filter: "processing" };
    }

    function render() {
        const status = statusFilter.value;
        const query = searchInput.value.trim().toLowerCase();
        const visible = visits.filter((visit) => {
            const matchesStatus = !status || statusMeta(visit).filter === status;
            const haystack = `${visit.appointmentId} ${visit.doctorName} ${visit.department}`.toLowerCase();
            return matchesStatus && (!query || haystack.includes(query));
        });

        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Bạn chưa có lịch sử khám phù hợp.";
            return;
        }

        visible.forEach((visit) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `Lần khám #${visit.appointmentId}`;
            const doctor = document.createElement("p");
            doctor.textContent = `${visit.doctorName} - ${visit.department || "Chưa cập nhật chuyên khoa"}`;
            const time = document.createElement("p");
            time.textContent = `Ngày khám: ${date(visit.appointmentTime)}`;
            const result = document.createElement("span");
            const meta = statusMeta(visit);
            result.className = `status-pill ${meta.className}`;
            result.textContent = meta.label;
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/history/detail?id=${visit.appointmentId}`);
            link.textContent = "Xem chi tiết";
            info.append(title, doctor, time, result);
            item.append(info, link);
            list.append(item);
        });
    }

    function loadVisits() {
        const query = dateFilter.value
            ? `?searchDate=${encodeURIComponent(dateFilter.value)}` : "";
        list.classList.add("loading-state");
        ApiClient.get(`/patient/api/history${query}`)
            .then((data) => { visits = data.visits || []; render(); })
            .catch((error) => {
                list.textContent = `Không thể tải lịch sử khám: ${error.message}`;
            })
            .finally(() => list.classList.remove("loading-state"));
    }

    statusFilter.addEventListener("change", render);
    searchInput.addEventListener("input", render);
    dateFilter.addEventListener("change", loadVisits);
    loadVisits();
})();
