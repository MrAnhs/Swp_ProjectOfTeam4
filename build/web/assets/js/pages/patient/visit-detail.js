(function () {
    const id = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("visitTitle");
    const meta = document.getElementById("visitMeta");
    const detail = document.getElementById("visitDetail");

    function value(input) { return input ?? "Ch\u01B0a c\u00F3"; }
    function metric(label, data) {
        const item = document.createElement("div");
        item.className = "metric-card";
        const name = document.createElement("span"); name.textContent = label;
        const content = document.createElement("strong"); content.textContent = value(data);
        item.append(name, content); return item;
    }
    function render(visit) {
        title.textContent = `L\u1EA7n kh\u00E1m #${visit.appointmentId}`;
        meta.textContent = `${visit.doctorName} - ${visit.department || "Ch\u01B0a c\u1EADp nh\u1EADt chuy\u00EAn khoa"}`;
        detail.replaceChildren(); detail.className = "";
        if (visit.appointmentStatus === "Absent" || visit.appointmentStatus === "Cancelled") {
            const status = PatientAppointmentStatus.get(visit.appointmentStatus);
            const message = document.createElement("div");
            message.className = "result-pending";
            message.innerHTML = `<h2>${status.label}</h2><p>Lịch hẹn này không phát sinh kết quả khám.</p>`;
            detail.append(message);
            return;
        }
        if (!visit.resultVisible) {
            const pending = document.createElement("div");
            pending.className = "result-pending";
            pending.innerHTML = "<h2>K\u1EBFt qu\u1EA3 \u0111ang \u0111\u01B0\u1EE3c x\u1EED l\u00FD</h2><p>B\u00E1c s\u0129 ch\u01B0a cho ph\u00E9p c\u00F4ng b\u1ED1 k\u1EBFt qu\u1EA3 c\u1EE7a l\u1EA7n kh\u00E1m n\u00E0y.</p>";
            detail.append(pending); return;
        }
        const diagnosis = document.createElement("section");
        diagnosis.className = "visit-diagnosis";
        const heading = document.createElement("h2"); heading.textContent = "Ch\u1EA9n \u0111o\u00E1n c\u1EE7a b\u00E1c s\u0129";
        const conclusion = document.createElement("p"); conclusion.textContent = `K\u1EBFt lu\u1EADn: ${value(visit.finalDiagnosis)}`;
        const note = document.createElement("p"); note.textContent = `Ghi ch\u00FA: ${value(visit.doctorNote)}`;
        diagnosis.append(heading, conclusion, note);
        const grid = document.createElement("div"); grid.className = "metric-grid";
        const m = visit.metrics || {};
        [["Urea",m.urea],["Creatinine",m.cr],["HbA1c",m.hba1c],["Cholesterol",m.chol],
         ["Triglycerides",m.tg],["HDL",m.hdl],["LDL",m.ldl],["VLDL",m.vldl],
         ["BMI",m.bmi],["C\u00E2n n\u1EB7ng",m.weight],["Chi\u1EC1u cao",m.height]]
            .forEach(([label,data]) => grid.append(metric(label,data)));
        detail.append(diagnosis, grid);
    }
    if (!Number.isInteger(id) || id <= 0) { detail.textContent = "M\u00E3 l\u1EA7n kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7."; return; }
    ApiClient.get(`/patient/api/history?appointmentId=${id}`)
        .then((data) => render(data.visit))
        .catch((error) => { detail.textContent = error.message; meta.textContent = ""; });
})();
