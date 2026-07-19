(function () {
    "use strict";

    const root = document.querySelector(".settings-page");
    if (!root) return;

    const context = document.querySelector('meta[name="app-context-path"]')?.content || "";
    const personalForm = document.getElementById("personalForm");
    const personalMessage = document.getElementById("personalMessage");
    const settingsMessage = document.getElementById("settingsMessage");
    const dialog = document.getElementById("accountDialog");
    const dialogForm = document.getElementById("accountDialogForm");
    const dialogMessage = document.getElementById("dialogMessage");
    const dialogSubmit = document.getElementById("dialogSubmit");
    const resendEmailOtp = document.getElementById("resendEmailOtp");
    const emailOtpCountdown = document.getElementById("emailOtpCountdown");

    let profile = null;
    let editing = false;
    let pendingEmail = "";
    let emailOtpRequested = false;
    let countdownTimer = null;

    function showMessage(element, message, error) {
        element.hidden = false;
        element.textContent = message;
        element.className = "settings-message" + (error ? " error" : "");
    }

    function hideMessage(element) {
        element.hidden = true;
        element.textContent = "";
        element.className = "settings-message";
    }

    function setField(name, value) {
        const field = document.querySelector(`[data-field="${name}"]`);
        if (field) field.value = value || "";
        const text = document.querySelector(`strong[data-field="${name}"]`);
        if (text) text.textContent = value || "Ch\u01B0a c\u1EADp nh\u1EADt";
    }

    function render(data) {
        profile = data;
        ["fullName", "dateOfBirth", "gender", "phone", "address"]
                .forEach(name => setField(name, data[name]));
        setField("email", data.email);
        setField("accountPhone", data.phone);
        setField("createdAt", data.createdAt ? data.createdAt.replace("T", " ") : "");
        ["department", "labName", "deskLocation"]
                .forEach(name => setField(name, data[name]));
    }

    async function request(path, options) {
        const response = await fetch(context + "/settings" + path, {
            credentials: "same-origin",
            ...options
        });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.error || "C\u00F3 l\u1ED7i x\u1EA3y ra. Vui l\u00F2ng th\u1EED l\u1EA1i.");
        }
        return data;
    }

    function post(path, params) {
        return request(path, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" },
            body: new URLSearchParams(params)
        });
    }

    function setEditing(value) {
        editing = value;
        document.querySelectorAll("[data-field]").forEach(field => {
            if (["department", "labName", "deskLocation", "email", "accountPhone", "createdAt"]
                    .includes(field.dataset.field)) return;
            if (field.tagName === "SELECT") field.disabled = !value;
            else field.readOnly = !value;
        });
        document.querySelector('[data-edit="personal"]').hidden = value;
        document.querySelector('[data-edit-actions="personal"]').hidden = !value;
    }

    document.querySelectorAll(".settings-tab").forEach(tab => {
        tab.addEventListener("click", () => {
            document.querySelectorAll(".settings-tab")
                    .forEach(item => item.classList.toggle("active", item === tab));
            document.querySelectorAll("[data-panel]")
                    .forEach(panel => panel.hidden = panel.dataset.panel !== tab.dataset.tab);
        });
    });

    document.querySelector('[data-edit="personal"]')
            .addEventListener("click", () => setEditing(true));
    document.querySelector('[data-cancel="personal"]').addEventListener("click", () => {
        render(profile);
        setEditing(false);
        hideMessage(personalMessage);
    });

    personalForm.addEventListener("submit", async event => {
        event.preventDefault();
        if (!editing) return;
        const submitButton = event.submitter;
        if (submitButton) submitButton.disabled = true;
        try {
            const result = await post("/profile", Object.fromEntries(new FormData(personalForm)));
            if (!result.success) throw new Error(result.error);
            profile = await request("/profile");
            render(profile);
            setEditing(false);
            showMessage(personalMessage, "\u0110\u00E3 l\u01B0u th\u00F4ng tin c\u00E1 nh\u00E2n.", false);
        } catch (error) {
            showMessage(personalMessage, error.message, true);
        } finally {
            if (submitButton) submitButton.disabled = false;
        }
    });

    function setDialogStep(type, otpStep) {
        document.getElementById("emailFields").hidden = type !== "email" || otpStep;
        document.getElementById("emailOtpFields").hidden = type !== "email" || !otpStep;
        document.getElementById("passwordFields").hidden = type !== "password";
        document.getElementById("dialogTitle").textContent = type === "password"
                ? "\u0110\u1ED5i m\u1EADt kh\u1EA9u"
                : otpStep ? "X\u00E1c th\u1EF1c email m\u1EDBi" : "\u0110\u1ED5i email";
        dialogSubmit.textContent = type === "password"
                ? "L\u01B0u thay \u0111\u1ED5i"
                : otpStep ? "X\u00E1c nh\u1EADn \u0111\u1ED5i email" : "G\u1EEDi m\u00E3 x\u00E1c th\u1EF1c";
    }

    function resetDialog() {
        clearInterval(countdownTimer);
        countdownTimer = null;
        pendingEmail = "";
        emailOtpRequested = false;
        dialogForm.reset();
        dialogForm.dataset.type = "";
        hideMessage(dialogMessage);
        resendEmailOtp.disabled = true;
        emailOtpCountdown.textContent = "";
        document.getElementById("emailOtpTarget").textContent = "";
        dialogSubmit.disabled = false;
    }

    function openDialog(type) {
        resetDialog();
        dialogForm.dataset.type = type;
        setDialogStep(type, false);
        dialog.showModal();
    }

    function startResendCountdown(seconds) {
        clearInterval(countdownTimer);
        let remaining = seconds;
        resendEmailOtp.disabled = true;
        const renderCountdown = () => {
            emailOtpCountdown.textContent = remaining > 0
                    ? `C\u00F3 th\u1EC3 g\u1EEDi l\u1EA1i sau ${remaining} gi\u00E2y` : "";
            if (remaining <= 0) {
                clearInterval(countdownTimer);
                countdownTimer = null;
                resendEmailOtp.disabled = false;
            }
            remaining -= 1;
        };
        renderCountdown();
        countdownTimer = setInterval(renderCountdown, 1000);
    }

    async function requestEmailOtp() {
        const newEmail = document.getElementById("newEmail").value.trim();
        const currentPassword = document.getElementById("emailPassword").value;
        if (!newEmail || !currentPassword) {
            throw new Error("Vui l\u00F2ng nh\u1EADp email m\u1EDBi v\u00E0 m\u1EADt kh\u1EA9u hi\u1EC7n t\u1EA1i.");
        }
        const result = await post("/email/request-otp", { newEmail, currentPassword });
        pendingEmail = newEmail;
        emailOtpRequested = true;
        document.getElementById("emailOtpTarget").textContent = pendingEmail;
        setDialogStep("email", true);
        startResendCountdown(60);
        document.getElementById("emailOtp").focus();
        showMessage(dialogMessage,
                "M\u00E3 x\u00E1c th\u1EF1c \u0111\u00E3 \u0111\u01B0\u1EE3c g\u1EEDi. Vui l\u00F2ng ki\u1EC3m tra h\u1ED9p th\u01B0.", false);
        return result;
    }

    async function confirmEmailOtp() {
        const otp = document.getElementById("emailOtp").value.trim();
        if (!/^\d{6}$/.test(otp)) {
            throw new Error("M\u00E3 x\u00E1c th\u1EF1c ph\u1EA3i g\u1ED3m 6 ch\u1EEF s\u1ED1.");
        }
        await post("/email/confirm", { newEmail: pendingEmail, otp });
        dialog.close();
        profile = await request("/profile");
        render(profile);
        showMessage(settingsMessage, "\u0110\u00E3 x\u00E1c th\u1EF1c v\u00E0 thay \u0111\u1ED5i email.", false);
    }

    document.querySelector('[data-action="email"]')
            .addEventListener("click", () => openDialog("email"));
    document.querySelector('[data-action="password"]')
            .addEventListener("click", () => openDialog("password"));
    dialog.addEventListener("close", resetDialog);

    resendEmailOtp.addEventListener("click", async () => {
        resendEmailOtp.disabled = true;
        hideMessage(dialogMessage);
        try {
            await post("/email/request-otp", {
                newEmail: pendingEmail,
                currentPassword: document.getElementById("emailPassword").value
            });
            startResendCountdown(60);
            showMessage(dialogMessage, "\u0110\u00E3 g\u1EEDi l\u1EA1i m\u00E3 x\u00E1c th\u1EF1c.", false);
        } catch (error) {
            resendEmailOtp.disabled = false;
            showMessage(dialogMessage, error.message, true);
        }
    });

    dialogForm.addEventListener("submit", async event => {
        if (event.submitter?.value === "cancel") return;
        event.preventDefault();
        hideMessage(dialogMessage);
        dialogSubmit.disabled = true;
        const type = dialogForm.dataset.type;
        try {
            if (type === "email") {
                if (emailOtpRequested) await confirmEmailOtp();
                else await requestEmailOtp();
                return;
            }

            await post("/password", {
                currentPassword: document.getElementById("currentPassword").value,
                newPassword: document.getElementById("newPassword").value,
                confirmation: document.getElementById("passwordConfirmation").value
            });
            dialog.close();
            showMessage(settingsMessage, "\u0110\u00E3 \u0111\u1ED5i m\u1EADt kh\u1EA9u.", false);
        } catch (error) {
            showMessage(dialogMessage, error.message, true);
        } finally {
            dialogSubmit.disabled = false;
        }
    });

    request("/profile")
            .then(render)
            .catch(error => showMessage(personalMessage, error.message, true));
})();
