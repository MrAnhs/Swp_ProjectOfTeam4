(function () {
    const list = document.getElementById("recordList");
    const filter = document.getElementById("statusFilter");
    const search = document.getElementById("recordSearch");
    let records = [];

    function clean(value, fallback = "Chưa có") {
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
            list.textContent = "Không tìm thấy hồ sơ phù hợp.";
            return;
        }

        visible.forEach((record) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `Hồ sơ #${record.healthRecordId}`;
            const date = document.createElement("p");
            date.textContent = `Ngày gửi: ${clean(record.createdAt)}`;
            const metrics = document.createElement("p");
            metrics.textContent = `HbA1c: ${clean(record.hba1c)} | BMI: ${clean(record.bmi)} | Triệu chứng: ${clean(record.symptoms)}`;
            const pill = document.createElement("span");
            pill.className = `status-pill ${record.status === "approved" ? "approved" : ""}`;
            pill.textContent = record.status === "approved" ? "Đã duyệt" : "Chờ xử lý";
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/health-records/detail?id=${record.healthRecordId}`);
            link.textContent = "Xem chi tiết";
            info.append(title, date, metrics, pill);
            item.append(info, link);
            list.append(item);
        });
    }

    filter.addEventListener("change", render);
    search.addEventListener("input", render);

    ApiClient.get("/medical-history")
        .then((data) => { records = data.records || []; render(); })
        .catch((error) => { list.textContent = `Không thể tải lịch sử: ${error.message}`; });
})();
