(function () {
    const form = document.getElementById("healthRecordForm");
    const weight = document.getElementById("weight");
    const height = document.getElementById("height");
    const bmi = document.getElementById("bmi");
    const message = document.getElementById("formMessage");
    const warningText = "Chỉ số này không bình thường, bạn có chắc chắn đã nhập đúng dữ liệu từ kết quả xét nghiệm không?";
    const hardLimitText = "Giá trị này nằm ngoài phạm vi sinh lý của con người, vui lòng kiểm tra lại.";

    const rules = {
        urea: rule(0.5, 60, between(2.5, 7.5)),
        creatinine: rule(10, 2000, between(45, 110)),
        hba1c: rule(2, 25, between(4, 5.6)),
        cholesterol: rule(0.5, 25, lessThan(5.2)),
        tg: rule(0.1, 50, lessThan(1.7)),
        hdl: rule(0.1, 5, greaterThan(1)),
        ldl: rule(0.1, 15, lessThan(3.4)),
        weight: ruleExclusiveMin(0, 800, between(25, 200)),
        height: ruleExclusiveMin(0, 300, between(50, 250))
    };

    function rule(hardMin, hardMax, isNormal) {
        return { isWithinHardLimit: between(hardMin, hardMax), isNormal };
    }

    function ruleExclusiveMin(hardMin, hardMax, isNormal) {
        return { isWithinHardLimit: (value) => value > hardMin && value <= hardMax, isNormal };
    }

    function between(min, max) {
        return (value) => value >= min && value <= max;
    }

    function lessThan(max) {
        return (value) => value < max;
    }

    function greaterThan(min) {
        return (value) => value > min;
    }

    function feedbackFor(input) {
        let feedback = input.parentElement.querySelector(".metric-feedback");
        if (!feedback) {
            feedback = document.createElement("small");
            feedback.className = "metric-feedback";
            feedback.hidden = true;
            input.insertAdjacentElement("afterend", feedback);
        }
        return feedback;
    }

    function clearFieldState(input) {
        const feedback = feedbackFor(input);
        input.classList.remove("metric-warning", "metric-error");
        input.setCustomValidity("");
        feedback.hidden = true;
        feedback.className = "metric-feedback";
        feedback.textContent = "";
    }

    function validateField(input) {
        const validationRule = rules[input.name];
        if (!validationRule || input.value.trim() === "") {
            clearFieldState(input);
            return true;
        }

        const value = Number(input.value);
        const feedback = feedbackFor(input);
        input.classList.remove("metric-warning", "metric-error");

        if (!Number.isFinite(value) || !validationRule.isWithinHardLimit(value)) {
            input.classList.add("metric-error");
            input.setCustomValidity(hardLimitText);
            feedback.className = "metric-feedback error";
            feedback.textContent = hardLimitText;
            feedback.hidden = false;
            return false;
        }

        input.setCustomValidity("");
        if (!validationRule.isNormal(value)) {
            input.classList.add("metric-warning");
            feedback.className = "metric-feedback warning";
            feedback.textContent = warningText;
            feedback.hidden = false;
            return true;
        }

        clearFieldState(input);
        return true;
    }

    function validateAllFields() {
        let valid = true;
        Object.keys(rules).forEach((name) => {
            const input = form.elements.namedItem(name);
            if (input && !validateField(input)) {
                valid = false;
            }
        });
        return valid;
    }

    function calculateBmi() {
        const weightValue = Number(weight.value);
        const heightValue = Number(height.value) / 100;
        bmi.value = weightValue > 0 && heightValue > 0
            ? (weightValue / (heightValue * heightValue)).toFixed(2)
            : "";
    }

    function showMessage(type, value) {
        message.hidden = false;
        message.className = `form-message ${type}`;
        message.textContent = value;
    }

    Object.keys(rules).forEach((name) => {
        const input = form.elements.namedItem(name);
        if (!input) return;
        input.addEventListener("input", () => validateField(input));
        input.addEventListener("blur", () => validateField(input));
    });

    weight.addEventListener("input", calculateBmi);
    height.addEventListener("input", calculateBmi);
    form.addEventListener("reset", () => setTimeout(() => {
        Object.keys(rules).forEach((name) => {
            const input = form.elements.namedItem(name);
            if (input) clearFieldState(input);
        });
        message.hidden = true;
        calculateBmi();
    }));

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        if (!validateAllFields()) {
            showMessage("error", hardLimitText);
            form.reportValidity();
            return;
        }

        const submit = form.querySelector('button[type="submit"]');
        submit.disabled = true;
        try {
            const result = await ApiClient.postForm(
                "/submit-health-record",
                new URLSearchParams(new FormData(form))
            );
            if (!result.success) {
                throw new Error(result.error || "Không thể gửi hồ sơ");
            }
            window.location.href = ApiClient.buildUrl(`/patient/health-records/detail?id=${result.healthRecordId}`);
        } catch (error) {
            showMessage("error", error.message);
        } finally {
            submit.disabled = false;
        }
    });
})();