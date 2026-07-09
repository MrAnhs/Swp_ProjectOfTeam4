(function () {
    const id = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("visitTitle");
    const meta = document.getElementById("visitMeta");
    const detail = document.getElementById("visitDetail");

    function value(input) { return input ?? "Chưa có"; }
    function metric(label, data) {
        const item = document.createElement("div");
        item.className = "metric-card";
        const name = document.createElement("span"); name.textContent = label;
        const content = document.createElement("strong"); content.textContent = value(data);
        item.append(name, content); return item;
    }
    function render(visit) {
        title.textContent = `Lần khám #${visit.appointmentId}`;
        meta.textContent = `${visit.doctorName} - ${visit.department || "Chưa cập nhật chuyên khoa"}`;
        detail.replaceChildren(); detail.className = "";
        if (!visit.resultVisible) {
            const pending = document.createElement("div");
            pending.className = "result-pending";
            pending.innerHTML = "<h2>Kết quả đang được xử lý</h2><p>Bác sĩ chưa cho phép công bố kết quả của lần khám này.</p>";
            detail.append(pending); return;
        }
        const diagnosis = document.createElement("section");
        diagnosis.className = "visit-diagnosis";
        const heading = document.createElement("h2"); heading.textContent = "Chẩn đoán của bác sĩ";
        const conclusion = document.createElement("p"); conclusion.textContent = `Kết luận: ${value(visit.finalDiagnosis)}`;
        const note = document.createElement("p"); note.textContent = `Ghi chú: ${value(visit.doctorNote)}`;
        diagnosis.append(heading, conclusion, note);
        const grid = document.createElement("div"); grid.className = "metric-grid";
        const m = visit.metrics || {};
        [["Urea",m.urea],["Creatinine",m.cr],["HbA1c",m.hba1c],["Cholesterol",m.chol],
         ["Triglycerides",m.tg],["HDL",m.hdl],["LDL",m.ldl],["VLDL",m.vldl],
         ["BMI",m.bmi],["Cân nặng",m.weight],["Chiều cao",m.height]]
            .forEach(([label,data]) => grid.append(metric(label,data)));
        detail.append(diagnosis, grid);
    }
    if (!Number.isInteger(id) || id <= 0) { detail.textContent = "Mã lần khám không hợp lệ."; return; }
    ApiClient.get(`/patient/api/history?appointmentId=${id}`)
        .then((data) => render(data.visit))
        .catch((error) => { detail.textContent = error.message; meta.textContent = ""; });
})();
