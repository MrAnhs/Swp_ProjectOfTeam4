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
    phoneFeedback.textContent = "Enter a valid Vietnamese mobile number, for example 0912345678 or +84912345678.";

    function validatePasswordConfirmation() {
        if (confirmPassword.value && password.value !== confirmPassword.value) {
            confirmPassword.setCustomValidity("Mật khẩu xác nhận không khớp");
            confirmFeedback.textContent = "Mật khẩu xác nhận không khớp.";
            return;
        }
        confirmPassword.setCustomValidity("");
        confirmFeedback.textContent = "Confirm your password.";
    }

    function validateDob() {
        if (dob.value && (dob.value < dob.min || dob.value > today)) {
            dob.setCustomValidity("Invalid date of birth");
            dobFeedback.textContent = "Date of birth must be between 01/01/1900 and today.";
            return;
        }
        dob.setCustomValidity("");
        dobFeedback.textContent = "Enter a valid date of birth that is not in the future.";
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
            phone.setCustomValidity("Invalid Vietnamese phone number");
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
