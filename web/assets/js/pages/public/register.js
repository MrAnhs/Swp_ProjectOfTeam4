(() => {
    "use strict";

    const form = document.querySelector(".needs-validation");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");
    const confirmFeedback = document.getElementById("confirmFeedback");
    const dob = document.getElementById("dob");
    const dobFeedback = document.getElementById("dobFeedback");
    const phone = document.getElementById("phone");
    const phoneFeedback = phone.closest(".input-group").querySelector(".invalid-feedback");
    const phonePattern = /^(0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])\d{7}|(\+?84)(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])\d{7})$/;
    const now = new Date();
    const today = [
        now.getFullYear(),
        String(now.getMonth() + 1).padStart(2, "0"),
        String(now.getDate()).padStart(2, "0")
    ].join("-");

    dob.max = today;
    phoneFeedback.textContent = "Vui lòng nhập số điện thoại Việt Nam hợp lệ, ví dụ 0912345678 hoặc +84912345678.";

    function validatePasswordConfirmation() {
        if (confirmPassword.value && password.value !== confirmPassword.value) {
            confirmPassword.setCustomValidity("Mật khẩu xác nhận không khớp");
            confirmFeedback.textContent = "Mật khẩu xác nhận không khớp.";
            return;
        }
        confirmPassword.setCustomValidity("");
        confirmFeedback.textContent = "Vui lòng xác nhận mật khẩu.";
    }

    function validateDob() {
        if (dob.value && (dob.value < dob.min || dob.value > today)) {
            dob.setCustomValidity("Ngày sinh không hợp lệ");
            dobFeedback.textContent = "Ngày sinh phải nằm trong khoảng từ 01/01/1900 đến hôm nay.";
            return;
        }
        dob.setCustomValidity("");
        dobFeedback.textContent = "Ngày sinh phải hợp lệ và không được vượt quá ngày hiện tại.";
    }

    function normalizePhone(value) {
        const cleaned = value.trim().replace(/[\s.\-()]/g, "");
        if (cleaned.startsWith("+84")) return `0${cleaned.slice(3)}`;
        if (cleaned.startsWith("84") && cleaned.length === 11) return `0${cleaned.slice(2)}`;
        return cleaned;
    }

    function validatePhone() {
        const cleaned = phone.value.trim().replace(/[\s.\-()]/g, "");
        if (phone.value && !phonePattern.test(cleaned)) {
            phone.setCustomValidity("Số điện thoại Việt Nam không hợp lệ");
            return;
        }
        phone.setCustomValidity("");
        if (phone.value) {
            phone.value = normalizePhone(phone.value);
        }
    }

    password.addEventListener("input", validatePasswordConfirmation);
    confirmPassword.addEventListener("input", validatePasswordConfirmation);
    dob.addEventListener("input", validateDob);
    phone.addEventListener("input", () => phone.setCustomValidity(""));

    const emailInput = document.getElementById("email");
    const btnSendOtp = document.getElementById("btnSendOtp");
    const otpStatusMsg = document.getElementById("otpStatusMsg");

    if (btnSendOtp && emailInput) {
        let cooldownTimer = null;

        btnSendOtp.addEventListener("click", async () => {
            const email = emailInput.value.trim();
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

            if (!email || !emailRegex.test(email)) {
                showOtpStatus("Vui lòng nhập email hợp lệ trước khi gửi mã OTP.", true);
                emailInput.focus();
                return;
            }

            btnSendOtp.disabled = true;
            btnSendOtp.textContent = "Đang gửi...";
            showOtpStatus("Đang gửi mã OTP tới email của bạn...", false);

            try {
                const params = new URLSearchParams();
                params.append("action", "send-otp");
                params.append("email", email);

                const res = await fetch("register", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                });
                const data = await res.json();

                if (res.ok && data.success) {
                    showOtpStatus(data.message || "Mã OTP đã được gửi về email của bạn.", false);
                    startCooldown(60);
                } else {
                    showOtpStatus(data.message || "Không thể gửi mã OTP. Vui lòng thử lại.", true);
                    btnSendOtp.disabled = false;
                    btnSendOtp.textContent = "Gửi lại OTP";
                }
            } catch (err) {
                console.error("Send OTP error:", err);
                showOtpStatus("Lỗi kết nối. Vui lòng thử lại.", true);
                btnSendOtp.disabled = false;
                btnSendOtp.textContent = "Gửi lại OTP";
            }
        });

        function showOtpStatus(msg, isError) {
            if (!otpStatusMsg) return;
            otpStatusMsg.style.display = "block";
            otpStatusMsg.style.color = isError ? "#ef4444" : "#2AB5A3";
            otpStatusMsg.textContent = msg;
        }

        function startCooldown(seconds) {
            let remain = seconds;
            btnSendOtp.disabled = true;
            btnSendOtp.textContent = `Gửi lại (${remain}s)`;

            if (cooldownTimer) clearInterval(cooldownTimer);
            cooldownTimer = setInterval(() => {
                remain--;
                if (remain <= 0) {
                    clearInterval(cooldownTimer);
                    btnSendOtp.disabled = false;
                    btnSendOtp.textContent = "Gửi lại OTP";
                } else {
                    btnSendOtp.textContent = `Gửi lại (${remain}s)`;
                }
            }, 1000);
        }
    }

    form.addEventListener("submit", (event) => {
        validatePasswordConfirmation();
        validateDob();
        validatePhone();

        if (!form.checkValidity()) {
            event.preventDefault();
            event.stopPropagation();
        }
        form.classList.add("was-validated");
    });
})();
