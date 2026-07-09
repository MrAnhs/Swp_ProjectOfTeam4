(function () {
    const list = document.getElementById("visitList");
    function date(value) {
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? value.replace("T", " ") : parsed.toLocaleString("vi-VN");
    }
    ApiClient.get("/patient/api/history")
        .then((data) => {
            list.replaceChildren();
            if (!data.visits?.length) {
                list.textContent = "Bạn chưa có lịch sử khám.";
                return;
            }
            data.visits.forEach((visit) => {
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
                result.className = `status-pill ${visit.resultVisible ? "completed" : "waiting"}`;
                result.textContent = visit.resultVisible ? "Đã có kết quả" : "Đang xử lý";
                const link = document.createElement("a");
                link.className = "btn-page-secondary";
                link.href = ApiClient.buildUrl(`/patient/history/detail?id=${visit.appointmentId}`);
                link.textContent = "Xem chi tiết";
                info.append(title, doctor, time, result);
                item.append(info, link);
                list.append(item);
            });
        })
        .catch((error) => { list.textContent = `Không thể tải lịch sử khám: ${error.message}`; });
})();
