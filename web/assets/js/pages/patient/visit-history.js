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
            return { label: "\u0110\u00E3 ho\u00E0n th\u00E0nh", className: "completed", filter: "completed" };
        }
        return { label: "\u0110ang x\u1EED l\u00FD", className: "waiting", filter: "processing" };
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
            list.textContent = "B\u1EA1n ch\u01B0a c\u00F3 l\u1ECBch s\u1EED kh\u00E1m ph\u00F9 h\u1EE3p.";
            return;
        }

        visible.forEach((visit) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `L\u1EA7n kh\u00E1m #${visit.appointmentId}`;
            const doctor = document.createElement("p");
            doctor.textContent = `${visit.doctorName} - ${visit.department || "Ch\u01B0a c\u1EADp nh\u1EADt chuy\u00EAn khoa"}`;
            const time = document.createElement("p");
            time.textContent = `Ng\u00E0y kh\u00E1m: ${date(visit.appointmentTime)}`;
            const result = document.createElement("span");
            const meta = statusMeta(visit);
            result.className = `status-pill ${meta.className}`;
            result.textContent = meta.label;
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/history/detail?id=${visit.appointmentId}`);
            link.textContent = "Xem chi ti\u1EBFt";
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
                list.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i l\u1ECBch s\u1EED kh\u00E1m: ${error.message}`;
            })
            .finally(() => list.classList.remove("loading-state"));
    }

    statusFilter.addEventListener("change", render);
    searchInput.addEventListener("input", render);
    dateFilter.addEventListener("change", loadVisits);
    loadVisits();
})();
