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
            throw new Error(data.error || "Có lỗi xảy ra. Vui lòng thử lại.");
        }
        return data;
    }

    function startCountdown(seconds) {
        clearInterval(countdownTimer);
        let remaining = seconds;
        resendButton.disabled = true;
        const update = () => {
            countdown.textContent = remaining > 0
                    ? `Gửi lại sau ${remaining} giây` : "";
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
            showMessage("Vui lòng nhập email tài khoản.", true);
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
            showMessage("Mã xác thực phải gồm 6 chữ số.", true);
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
            showMessage("Mật khẩu mới phải có ít nhất 8 ký tự.", true);
            return;
        }
        if (newPassword !== confirmation) {
            showMessage("Mật khẩu xác nhận không khớp.", true);
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
