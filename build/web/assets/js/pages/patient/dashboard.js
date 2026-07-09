(async function () {
    const container = document.getElementById("latestRecord");
    try {
        const data = await ApiClient.get("/patient/api/history");
        const visit = data.visits?.[0];
        container.replaceChildren();
        if (!visit) {
            container.textContent = "Bạn chưa có lịch sử khám.";
            return;
        }

        const item = document.createElement("article");
        item.className = "record-item";
        const info = document.createElement("div");
        const title = document.createElement("h3");
        title.textContent = `Lần khám #${visit.appointmentId}`;
        const doctor = document.createElement("p");
        doctor.textContent = `${visit.doctorName} - ${visit.department || "Chưa cập nhật chuyên khoa"}`;
        const time = document.createElement("p");
        time.textContent = `Thời gian: ${visit.appointmentTime.replace("T", " ")}`;
        const status = document.createElement("span");
        status.className = `status-pill ${visit.resultVisible ? "completed" : "waiting"}`;
        status.textContent = visit.resultVisible ? "Đã có kết quả" : "Đang xử lý";
        const link = document.createElement("a");
        link.className = "btn-page-secondary";
        link.href = ApiClient.buildUrl(`/patient/history/detail?id=${visit.appointmentId}`);
        link.textContent = "Xem chi tiết";
        info.append(title, doctor, time, status);
        item.append(info, link);
        container.append(item);
    } catch (error) {
        container.textContent = `Không thể tải lần khám gần nhất: ${error.message}`;
    }
})();
