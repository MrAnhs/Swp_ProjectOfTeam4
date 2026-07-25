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

    function value(input, fallback = "Chưa có") {
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
            ["LDL", record.ldl], ["VLDL", record.vldl], ["Cân nặng", record.weight],
            ["Chiều cao", record.height], ["BMI", record.bmi]
        ].forEach(([label, metricValue]) => grid.append(createMetric(label, metricValue)));

        const symptoms = document.createElement("p");
        symptoms.textContent = `Triệu chứng: ${value(record.symptoms)}`;
        symptoms.style.marginTop = "1rem";
        overview.append(grid, symptoms);
        title.textContent = `Hồ sơ #${record.healthRecordId}`;
        meta.textContent = `Ngày gửi: ${value(record.createdAt)} | Trạng thái: ${record.status === "approved" ? "Đã duyệt" : "Chờ xử lý"}`;
    }

    async function loadDiagnosis() {
        if (diagnosisLoaded) return;
        diagnosisLoaded = true;
        diagnosis.textContent = "Đang tải chẩn đoán...";
        try {
            const data = await ApiClient.get(`/get-diagnosis?healthRecordId=${recordId}`);
            diagnosis.replaceChildren();
            if (!data.diagnosis) {
                diagnosis.textContent = "Hồ sơ đang chờ bác sĩ xử lý.";
                return;
            }
            const content = document.createElement("div");
            const doctor = document.createElement("p");
            doctor.textContent = `Bác sĩ: ${value(data.doctorName)}`;
            const conclusion = document.createElement("p");
            conclusion.textContent = `Chẩn đoán: ${value(data.diagnosis.final_diagnosis)}`;
            const note = document.createElement("p");
            note.textContent = `Ghi chú: ${value(data.diagnosis.doctor_note)}`;
            const time = document.createElement("p");
            time.textContent = `Thời gian xử lý: ${value(data.diagnosis.processed_at)}`;
            content.append(doctor, conclusion, note, time);
            diagnosis.append(content);
        } catch (error) {
            diagnosis.textContent = `Không thể tải chẩn đoán: ${error.message}`;
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
        chat.textContent = "Đang tải tóm tắt & lịch sử AI...";
        try {
            const data = await ApiClient.get(`/get-ai-summary?healthRecordId=${recordId}`);
            chat.replaceChildren();
            if (!data.summaries || !data.summaries.length) {
                chat.textContent = "Hồ sơ này không có tóm tắt & lịch sử AI.";
                return;
            }
            data.summaries.forEach((summary) => {
                if (summary.aiSummary && summary.aiSummary !== "null" && summary.aiSummary.trim() !== "") {
                    const summaryBox = document.createElement("div");
                    summaryBox.className = "ai-summary-box";
                    summaryBox.innerHTML = `
                        <div class="ai-summary-header">
                            <i class="bi bi-robot text-success"></i>
                            <strong>Tóm tắt quan trọng từ AI</strong>
                        </div>
                        <div class="ai-summary-content">${formatSummary(summary.aiSummary)}</div>
                    `;
                    chat.append(summaryBox);
                }
                appendConversation(summary.chatHistory);
            });
        } catch (error) {
            chat.textContent = `Không thể tải tóm tắt & lịch sử AI: ${error.message}`;
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
        overview.textContent = "Mã hồ sơ không hợp lệ.";
        meta.textContent = "";
        return;
    }

    ApiClient.get("/medical-history")
        .then((data) => {
            const record = (data.records || []).find((item) => Number(item.healthRecordId) === recordId);
            if (!record) throw new Error("Không tìm thấy hồ sơ hoặc bạn không có quyền truy cập.");
            renderOverview(record);
        })
        .catch((error) => {
            overview.textContent = error.message;
            meta.textContent = "";
        });
})();