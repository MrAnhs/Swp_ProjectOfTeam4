(function () {
    "use strict";

    const context = document.querySelector('meta[name="app-context-path"]')?.content || "";
    const message = document.getElementById("forgotMessage");
    const resendButton = document.getElementById("resendResetOtp");
    const countdown = document.getElementById("resetOtpCountdown");
    let email = "";
    let countdownTimer = null;

    function showMessage(text, error) {
        message.hidden = false;
        message.textContent = text;
        message.className = "forgot-message" + (error ? " error" : "");
    }

    function hideMessage() {
        message.hidden = true;
        message.textContent = "";
    }

    function showStep(step) {
        document.querySelectorAll("[data-step]").forEach(section => {
            section.hidden = section.dataset.step !== step;
        });
        const order = { request: 0, verify: 1, reset: 2, success: 3 };
        document.querySelectorAll("[data-progress]").forEach((item, index) => {
            item.classList.toggle("active", index <= Math.min(order[step], 2));
        });
        hideMessage();
    }

    async function post(path, params) {
        const response = await fetch(context + "/forgot-password" + path, {
            method: "POST",
            credentials: "same-origin",
            headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" },
            body: new URLSearchParams(params)
        });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.error || "C\u00F3 l\u1ED7i x\u1EA3y ra. Vui l\u00F2ng th\u1EED l\u1EA1i.");
        }
        return data;
    }

    function startCountdown(seconds) {
        clearInterval(countdownTimer);
        let remaining = seconds;
        resendButton.disabled = true;
        const update = () => {
            countdown.textContent = remaining > 0
                    ? `G\u1EEDi l\u1EA1i sau ${remaining} gi\u00E2y` : "";
            if (remaining <= 0) {
                clearInterval(countdownTimer);
                countdownTimer = null;
                resendButton.disabled = false;
            }
            remaining -= 1;
        };
        update();
        countdownTimer = setInterval(update, 1000);
    }

    document.getElementById("requestOtpForm").addEventListener("submit", async event => {
        event.preventDefault();
        email = document.getElementById("resetEmail").value.trim();
        if (!email) {
            showMessage("Vui l\u00F2ng nh\u1EADp email t\u00E0i kho\u1EA3n.", true);
            return;
        }
        const button = event.submitter;
        button.disabled = true;
        hideMessage();
        try {
            const result = await post("/request", { email });
            document.getElementById("resetEmailDisplay").textContent = email;
            showStep("verify");
            startCountdown(60);
            showMessage(result.message, false);
            document.getElementById("resetOtp").focus();
        } catch (error) {
            showMessage(error.message, true);
        } finally {
            button.disabled = false;
        }
    });

    document.getElementById("verifyOtpForm").addEventListener("submit", async event => {
        event.preventDefault();
        const otp = document.getElementById("resetOtp").value.trim();
        if (!/^\d{6}$/.test(otp)) {
            showMessage("M\u00E3 x\u00E1c th\u1EF1c ph\u1EA3i g\u1ED3m 6 ch\u1EEF s\u1ED1.", true);
            return;
        }
        const button = event.submitter;
        button.disabled = true;
        hideMessage();
        try {
            await post("/verify", { email, otp });
            showStep("reset");
            document.getElementById("resetNewPassword").focus();
        } catch (error) {
            showMessage(error.message, true);
        } finally {
            button.disabled = false;
        }
    });

    resendButton.addEventListener("click", async () => {
        resendButton.disabled = true;
        hideMessage();
        try {
            const result = await post("/request", { email });
            startCountdown(60);
            showMessage(result.message, false);
        } catch (error) {
            resendButton.disabled = false;
            showMessage(error.message, true);
        }
    });

    document.querySelector('[data-back="request"]').addEventListener("click", () => {
        clearInterval(countdownTimer);
        document.getElementById("resetOtp").value = "";
        showStep("request");
    });

    document.getElementById("resetPasswordForm").addEventListener("submit", async event => {
        event.preventDefault();
        const newPassword = document.getElementById("resetNewPassword").value;
        const confirmation = document.getElementById("resetPasswordConfirmation").value;
        if (newPassword.length < 8) {
            showMessage("M\u1EADt kh\u1EA9u m\u1EDBi ph\u1EA3i c\u00F3 \u00EDt nh\u1EA5t 8 k\u00FD t\u1EF1.", true);
            return;
        }
        if (newPassword !== confirmation) {
            showMessage("M\u1EADt kh\u1EA9u x\u00E1c nh\u1EADn kh\u00F4ng kh\u1EDBp.", true);
            return;
        }
        const button = event.submitter;
        button.disabled = true;
        hideMessage();
        try {
            await post("/reset", { newPassword, confirmation });
            showStep("success");
        } catch (error) {
            showMessage(error.message, true);
        } finally {
            button.disabled = false;
        }
    });
})();
