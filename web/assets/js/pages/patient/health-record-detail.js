(function () {
    const params = new URLSearchParams(window.location.search);
    const recordId = Number(params.get("id"));
    const title = document.getElementById("recordTitle");
    const meta = document.getElementById("recordMeta");
    const overview = document.getElementById("overviewTab");
    const diagnosis = document.getElementById("diagnosisTab");
    const chat = document.getElementById("chatHistoryTab");
    let diagnosisLoaded = false;
    let chatLoaded = false;

    function value(input, fallback = "Ch\u01b0a c\u00f3") {
        return input && input !== "null" ? String(input) : fallback;
    }

    function createMetric(label, metricValue) {
        const card = document.createElement("div");
        card.className = "metric-card";
        const name = document.createElement("span");
        name.textContent = label;
        const data = document.createElement("strong");
        data.textContent = value(metricValue);
        card.append(name, data);
        return card;
    }

    function renderOverview(record) {
        overview.replaceChildren();
        const grid = document.createElement("div");
        grid.className = "metric-grid";
        [
            ["Urea", record.urea], ["Creatinine", record.cr], ["HbA1c", record.hba1c],
            ["Cholesterol", record.chol], ["Triglycerides", record.tg], ["HDL", record.hdl],
            ["LDL", record.ldl], ["VLDL", record.vldl], ["C\u00e2n n\u1eb7ng", record.weight],
            ["Chi\u1ec1u cao", record.height], ["BMI", record.bmi]
        ].forEach(([label, metricValue]) => grid.append(createMetric(label, metricValue)));

        const symptoms = document.createElement("p");
        symptoms.textContent = `Tri\u1ec7u ch\u1ee9ng: ${value(record.symptoms)}`;
        symptoms.style.marginTop = "1rem";
        overview.append(grid, symptoms);
        title.textContent = `H\u1ed3 s\u01a1 #${record.healthRecordId}`;
        meta.textContent = `Ng\u00e0y g\u1eedi: ${value(record.createdAt)} | Tr\u1ea1ng th\u00e1i: ${record.status === "approved" ? "\u0110\u00e3 duy\u1ec7t" : "Ch\u1edd x\u1eed l\u00fd"}`;
    }

    async function loadDiagnosis() {
        if (diagnosisLoaded) return;
        diagnosisLoaded = true;
        diagnosis.textContent = "\u0110ang t\u1ea3i ch\u1ea9n \u0111o\u00e1n...";
        try {
            const data = await ApiClient.get(`/get-diagnosis?healthRecordId=${recordId}`);
            diagnosis.replaceChildren();
            if (!data.diagnosis) {
                diagnosis.textContent = "H\u1ed3 s\u01a1 \u0111ang ch\u1edd b\u00e1c s\u0129 x\u1eed l\u00fd.";
                return;
            }
            const content = document.createElement("div");
            const doctor = document.createElement("p");
            doctor.textContent = `B\u00e1c s\u0129: ${value(data.doctorName)}`;
            const conclusion = document.createElement("p");
            conclusion.textContent = `Ch\u1ea9n \u0111o\u00e1n: ${value(data.diagnosis.final_diagnosis)}`;
            const note = document.createElement("p");
            note.textContent = `Ghi ch\u00fa: ${value(data.diagnosis.doctor_note)}`;
            const time = document.createElement("p");
            time.textContent = `Th\u1eddi gian x\u1eed l\u00fd: ${value(data.diagnosis.processed_at)}`;
            content.append(doctor, conclusion, note, time);
            diagnosis.append(content);
        } catch (error) {
            diagnosis.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i ch\u1ea9n \u0111o\u00e1n: ${error.message}`;
        }
    }

    function formatSummary(text) {
        if (!text) return "";
        let html = text.trim();
        if (html.includes("- ") || html.includes("* ")) {
            const items = html.split(/\n*(?:[*-]|\d+\.)\s+/).filter(Boolean);
            return "<ul>" + items.map(item => `<li>${item.replace(/\n/g, "<br>")}</li>`).join("") + "</ul>";
        }
        return html.replace(/\n/g, "<br>");
    }

    function appendConversation(history) {
        const lines = value(history, "").split(/\r?\n/).filter(Boolean);
        lines.forEach((line) => {
            const item = document.createElement("div");
            item.className = `chat-history-message ${line.toLowerCase().startsWith("ai:") ? "ai" : ""}`;
            item.textContent = line;
            chat.append(item);
        });
    }

    async function loadChat() {
        if (chatLoaded) return;
        chatLoaded = true;
        chat.textContent = "\u0110ang t\u1ea3i t\u00f3m t\u1eaft & l\u1ecbch s\u1eed AI...";
        try {
            const data = await ApiClient.get(`/get-ai-summary?healthRecordId=${recordId}`);
            chat.replaceChildren();
            if (!data.summaries || !data.summaries.length) {
                chat.textContent = "H\u1ed3 s\u01a1 n\u00e0y kh\u00f4ng c\u00f3 t\u00f3m t\u1eaft & l\u1ecbch s\u1eed AI.";
                return;
            }
            data.summaries.forEach((summary) => {
                if (summary.aiSummary && summary.aiSummary !== "null" && summary.aiSummary.trim() !== "") {
                    const summaryBox = document.createElement("div");
                    summaryBox.className = "ai-summary-box";
                    summaryBox.innerHTML = `
                        <div class="ai-summary-header">
                            <i class="bi bi-robot text-success"></i>
                            <strong>T\u00f3m t\u1eaft quan tr\u1ecdng t\u1eeb AI</strong>
                        </div>
                        <div class="ai-summary-content">${formatSummary(summary.aiSummary)}</div>
                    `;
                    chat.append(summaryBox);
                }
                appendConversation(summary.chatHistory);
            });
        } catch (error) {
            chat.textContent = `Kh\u00f4ng th\u1ec3 t\u1ea3i t\u00f3m t\u1eaft & l\u1ecbch s\u1eed AI: ${error.message}`;
        }
    }

    document.querySelectorAll("[data-tab-target]").forEach((button) => {
        button.addEventListener("click", () => {
            document.querySelectorAll("[data-tab-target]").forEach((item) => item.classList.remove("active"));
            document.querySelectorAll(".detail-tab").forEach((item) => item.classList.remove("active"));
            button.classList.add("active");
            document.getElementById(button.dataset.tabTarget).classList.add("active");
            if (button.dataset.tabTarget === "diagnosisTab") loadDiagnosis();
            if (button.dataset.tabTarget === "chatHistoryTab") loadChat();
        });
    });

    if (!Number.isInteger(recordId) || recordId <= 0) {
        overview.textContent = "M\u00e3 h\u1ed3 s\u01a1 kh\u00f4ng h\u1ee3p l\u1ec7.";
        meta.textContent = "";
        return;
    }

    ApiClient.get("/medical-history")
        .then((data) => {
            const record = (data.records || []).find((item) => Number(item.healthRecordId) === recordId);
            if (!record) throw new Error("Kh\u00f4ng t\u00ecm th\u1ea5y h\u1ed3 s\u01a1 ho\u1eb7c b\u1ea1n kh\u00f4ng c\u00f3 quy\u1ec1n truy c\u1eadp.");
            renderOverview(record);
        })
        .catch((error) => {
            overview.textContent = error.message;
            meta.textContent = "";
        });
})();