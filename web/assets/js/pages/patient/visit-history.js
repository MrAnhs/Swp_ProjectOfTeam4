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
                list.textContent = "B\u1EA1n ch\u01B0a c\u00F3 l\u1ECBch s\u1EED kh\u00E1m.";
                return;
            }
            data.visits.forEach((visit) => {
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
                result.className = `status-pill ${visit.resultVisible ? "completed" : "waiting"}`;
                result.textContent = visit.resultVisible ? "\u0110\u00E3 c\u00F3 k\u1EBFt qu\u1EA3" : "\u0110ang x\u1EED l\u00FD";
                const link = document.createElement("a");
                link.className = "btn-page-secondary";
                link.href = ApiClient.buildUrl(`/patient/history/detail?id=${visit.appointmentId}`);
                link.textContent = "Xem chi ti\u1EBFt";
                info.append(title, doctor, time, result);
                item.append(info, link);
                list.append(item);
            });
        })
        .catch((error) => { list.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i l\u1ECBch s\u1EED kh\u00E1m: ${error.message}`; });
})();
