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
    phoneFeedback.textContent = "Vui l\u00F2ng nh\u1EADp s\u1ED1 \u0111i\u1EC7n tho\u1EA1i Vi\u1EC7t Nam h\u1EE3p l\u1EC7, v\u00ED d\u1EE5 0912345678 ho\u1EB7c +84912345678.";

    function validatePasswordConfirmation() {
        if (confirmPassword.value && password.value !== confirmPassword.value) {
            confirmPassword.setCustomValidity("M\u1EADt kh\u1EA9u x\u00E1c nh\u1EADn kh\u00F4ng kh\u1EDBp");
            confirmFeedback.textContent = "M\u1EADt kh\u1EA9u x\u00E1c nh\u1EADn kh\u00F4ng kh\u1EDBp.";
            return;
        }
        confirmPassword.setCustomValidity("");
        confirmFeedback.textContent = "Vui l\u00F2ng x\u00E1c nh\u1EADn m\u1EADt kh\u1EA9u.";
    }

    function validateDob() {
        if (dob.value && (dob.value < dob.min || dob.value > today)) {
            dob.setCustomValidity("Ng\u00E0y sinh kh\u00F4ng h\u1EE3p l\u1EC7");
            dobFeedback.textContent = "Ng\u00E0y sinh ph\u1EA3i n\u1EB1m trong kho\u1EA3ng t\u1EEB 01/01/1900 \u0111\u1EBFn h\u00F4m nay.";
            return;
        }
        dob.setCustomValidity("");
        dobFeedback.textContent = "Ng\u00E0y sinh ph\u1EA3i h\u1EE3p l\u1EC7 v\u00E0 kh\u00F4ng \u0111\u01B0\u1EE3c v\u01B0\u1EE3t qu\u00E1 ng\u00E0y hi\u1EC7n t\u1EA1i.";
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
            phone.setCustomValidity("S\u1ED1 \u0111i\u1EC7n tho\u1EA1i Vi\u1EC7t Nam kh\u00F4ng h\u1EE3p l\u1EC7");
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
                showOtpStatus("Vui l\u00f2ng nh\u1eadp email h\u1ee3p l\u1ec7 tr\u01b0\u1edbc khi g\u1eedi m\u00e3 OTP.", true);
                emailInput.focus();
                return;
            }

            btnSendOtp.disabled = true;
            btnSendOtp.textContent = "\u0110ang g\u1eedi...";
            showOtpStatus("\u0110ang g\u1eedi m\u00e3 OTP t\u1edbi email c\u1ee7a b\u1ea1n...", false);

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
                    showOtpStatus(data.message || "M\u00e3 OTP \u0111\u00e3 \u0111\u01b0\u1ee3c g\u1eedi v\u1ec1 email c\u1ee7a b\u1ea1n.", false);
                    startCooldown(60);
                } else {
                    showOtpStatus(data.message || "Kh\u00f4ng th\u1ec3 g\u1eedi m\u00e3 OTP. Vui l\u00f2ng th\u1eed l\u1ea1i.", true);
                    btnSendOtp.disabled = false;
                    btnSendOtp.textContent = "G\u1eedi l\u1ea1i OTP";
                }
            } catch (err) {
                console.error("Send OTP error:", err);
                showOtpStatus("L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.", true);
                btnSendOtp.disabled = false;
                btnSendOtp.textContent = "G\u1eedi l\u1ea1i OTP";
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
            btnSendOtp.textContent = `G\u1eedi l\u1ea1i (${remain}s)`;

            if (cooldownTimer) clearInterval(cooldownTimer);
            cooldownTimer = setInterval(() => {
                remain--;
                if (remain <= 0) {
                    clearInterval(cooldownTimer);
                    btnSendOtp.disabled = false;
                    btnSendOtp.textContent = "G\u1eedi l\u1ea1i OTP";
                } else {
                    btnSendOtp.textContent = `G\u1eedi l\u1ea1i (${remain}s)`;
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
