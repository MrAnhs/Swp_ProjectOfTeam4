(function () {
    const list = document.getElementById("recordList");
    const filter = document.getElementById("statusFilter");
    const search = document.getElementById("recordSearch");
    let records = [];

    function clean(value, fallback = "Ch\u01b0a c\u00f3") {
        return value && value !== "null" ? String(value) : fallback;
    }

    function render() {
        const query = search.value.trim().toLowerCase();
        const status = filter.value;
        const visible = records.filter((record) => {
            const matchesStatus = !status || record.status === status;
            const haystack = `${record.healthRecordId} ${record.symptoms || ""}`.toLowerCase();
            return matchesStatus && (!query || haystack.includes(query));
        });

        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Kh\u00f4ng t\u00ecm th\u1ea5y h\u1ed3 s\u01a1 ph\u00f9 h\u1ee3p.";
            return;
        }

        visible.forEach((record) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `H\u1ed3 s\u01a1 #${record.healthRecordId}`;
            const date = document.createElement("p");
            date.textContent = `Ng\u00e0y g\u1eedi: ${clean(record.createdAt)}`;
            const metrics = document.createElement("p");
            metrics.textContent = `HbA1c: ${clean(record.hba1c)} | BMI: ${clean(record.bmi)} | Tri\u1ec7u ch\u1ee9ng: ${clean(record.symptoms)}`;
            const pill = document.createElement("span");
            pill.className = `status-pill ${record.status === "approved" ? "approved" : ""}`;
            pill.textContent = record.status === "approved" ? "\u0110\u00e3 duy\u1ec7t" : "Ch\u1edd x\u1eed l\u00fd";
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/health-records/detail?id=${record.healthRecordId}`);
            link.textContent = "Xem chi ti\u1ebft";
            info.append(title, date, metrics, pill);
            item.append(info, link);
            list.append(item);
        });
    }

    filter.addEventListener("change", render);
    search.addEventListener("input", render);

    ApiClient.get("/medical-history")
        .then((data) => { records = data.records || []; render(); })
        .catch((error) => { list.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i l\u1ecbch s\u1eed: ${error.message}`; });
})();