(function () {
    const form = document.getElementById("profileForm");
    const message = document.getElementById("profileMessage");
    const emailInput = document.getElementById("profileEmail");
    const phoneInput = document.getElementById("profilePhone");
    const dobInput = document.getElementById("profileDob");
    const phonePattern = /^(0(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])\d{7}|(\+?84)(3[2-9]|5[2689]|7[06-9]|8[1-689]|9[0-46-9])\d{7})$/;
    const now = new Date();
    const today = [
        now.getFullYear(),
        String(now.getMonth() + 1).padStart(2, "0"),
        String(now.getDate()).padStart(2, "0")
    ].join("-");

    dobInput.max = today;

    function showMessage(type, value) {
        message.hidden = false;
        message.className = `form-message ${type}`;
        message.textContent = value;
    }

    function normalizePhone(value) {
        const cleaned = value.trim().replace(/[\s.\-()]/g, "");
        if (cleaned.startsWith("+84")) return `0${cleaned.slice(3)}`;
        if (cleaned.startsWith("84") && cleaned.length === 11) return `0${cleaned.slice(2)}`;
        return cleaned;
    }

    function validateProfileForm() {
        const normalizedPhone = normalizePhone(phoneInput.value);
        phoneInput.setCustomValidity("");
        emailInput.setCustomValidity("");
        dobInput.setCustomValidity("");

        if (!emailInput.validity.valid) {
            emailInput.setCustomValidity("Email không đúng định dạng.");
        }

        if (!dobInput.value || dobInput.value < dobInput.min || dobInput.value > today) {
            dobInput.setCustomValidity("Ngày sinh phải hợp lệ, từ 01/01/1900 đến ngày hiện tại.");
        }

        if (!phonePattern.test(phoneInput.value.trim().replace(/[\s.\-()]/g, ""))) {
            phoneInput.setCustomValidity("Số điện thoại phải là số di động Việt Nam hợp lệ, ví dụ 0912345678 hoặc +84912345678.");
        } else {
            phoneInput.value = normalizedPhone;
        }

        return form.reportValidity();
    }

    ApiClient.get("/update-profile")
        .then((data) => {
            document.getElementById("profileName").value = data.fullName || "";
            document.getElementById("profileEmail").value = data.email || "";
            document.getElementById("profilePhone").value = data.phone || "";
            document.getElementById("profileGender").value = data.gender || "";
            dobInput.value = data.dob || "";
            document.getElementById("profileAddress").value = data.address || "";
        })
        .catch((error) => showMessage("error", error.message));

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        if (!validateProfileForm()) return;

        try {
            const result = await ApiClient.postForm("/update-profile", new URLSearchParams(new FormData(form)));
            if (!result.success) throw new Error(result.error || "Không thể lưu thông tin");
            showMessage("success", "Đã lưu thông tin cá nhân.");
        } catch (error) {
            showMessage("error", error.message);
        }
    });
})();
