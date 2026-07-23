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
            message.innerHTML = `<h2>${status.label}</h2><p>L\u1ECBch h\u1EB9n n\u00E0y kh\u00F4ng ph\u00E1t sinh k\u1EBFt qu\u1EA3 kh\u00E1m.</p>`;
            detail.append(message);
            return;
        }
        const diagnosis = document.createElement("section");
        diagnosis.className = "visit-diagnosis";
        const heading = document.createElement("h2"); heading.textContent = "Ch\u1EA9n \u0111o\u00E1n c\u1EE7a b\u00E1c s\u0129";

        if (!visit.resultVisible) {
            const hiddenMsg = document.createElement("p");
            hiddenMsg.className = "alert alert-warning border-0 shadow-sm small py-2 px-3 mb-0";
            hiddenMsg.style.background = "rgba(255, 193, 7, 0.15)";
            hiddenMsg.style.color = "#ffe082";
            hiddenMsg.innerHTML = "<i class='bi bi-shield-lock-fill me-2'></i>Vui l\u00F2ng li\u00EAn h\u1EC7 b\u00E1c s\u0129 \u0111\u1EC3 xem k\u1EBFt qu\u1EA3 ch\u1EA9n \u0111o\u00E1n.";
            diagnosis.append(heading, hiddenMsg);
        } else {
            const conclusion = document.createElement("p"); conclusion.textContent = `K\u1EBFt lu\u1EADn: ${value(visit.finalDiagnosis)}`;
            const note = document.createElement("p"); note.textContent = `Ghi ch\u00FA: ${value(visit.doctorNote)}`;
            diagnosis.append(heading, conclusion, note);
        }

        if (visit.revisitDate && visit.revisitDate !== "Ch\u01B0a c\u00F3") {
            let rawDate = visit.revisitDate.split("T")[0];
            let parts = rawDate.split("-");
            let formattedDate = parts.length === 3 ? `${parts[2]}/${parts[1]}/${parts[0]}` : rawDate;
            const revisitPara = document.createElement("p");
            revisitPara.className = "visit-revisit-info";
            revisitPara.style.marginTop = "12px";
            revisitPara.style.paddingTop = "10px";
            revisitPara.style.borderTop = "1px solid rgba(255,255,255,0.15)";
            revisitPara.style.color = "#81c784";
            revisitPara.style.fontWeight = "600";
            revisitPara.innerHTML = `<i class="bi bi-calendar-event me-2"></i>Ng\u00E0y t\u00E1i kh\u00E1m: <span style="font-size:1.05rem; font-weight:700; text-decoration: underline;">${formattedDate}</span>`;
            diagnosis.append(revisitPara);
        }

        const grid = document.createElement("div"); grid.className = "metric-grid";
        const m = visit.metrics || {};
        [["Urea", m.urea], ["Creatinine", m.cr], ["HbA1c", m.hba1c], ["Cholesterol", m.chol],
        ["Triglycerides", m.tg], ["HDL", m.hdl], ["LDL", m.ldl], ["VLDL", m.vldl],
        ["BMI", m.bmi], ["C\u00E2n n\u1EB7ng", m.weight], ["Chi\u1EC1u cao", m.height]]
            .forEach(([label, data]) => grid.append(metric(label, data)));
        detail.append(diagnosis, grid);
    }
    if (!Number.isInteger(id) || id <= 0) { detail.textContent = "M\u00E3 l\u1EA7n kh\u00E1m kh\u00F4ng h\u1EE3p l\u1EC7."; return; }
    ApiClient.get(`/patient/api/history?appointmentId=${id}`)
        .then((data) => render(data.visit))
        .catch((error) => { detail.textContent = error.message; meta.textContent = ""; });
})();
