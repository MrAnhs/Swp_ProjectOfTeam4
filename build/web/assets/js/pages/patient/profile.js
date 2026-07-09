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
            emailInput.setCustomValidity("Email kh\u00F4ng \u0111\u00FAng \u0111\u1ECBnh d\u1EA1ng.");
        }

        if (!dobInput.value || dobInput.value < dobInput.min || dobInput.value > today) {
            dobInput.setCustomValidity("Ng\u00E0y sinh ph\u1EA3i h\u1EE3p l\u1EC7, t\u1EEB 01/01/1900 \u0111\u1EBFn ng\u00E0y hi\u1EC7n t\u1EA1i.");
        }

        if (!phonePattern.test(phoneInput.value.trim().replace(/[\s.\-()]/g, ""))) {
            phoneInput.setCustomValidity("S\u1ED1 \u0111i\u1EC7n tho\u1EA1i ph\u1EA3i l\u00E0 s\u1ED1 di \u0111\u1ED9ng Vi\u1EC7t Nam h\u1EE3p l\u1EC7, v\u00ED d\u1EE5 0912345678 ho\u1EB7c +84912345678.");
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
            if (!result.success) throw new Error(result.error || "Kh\u00F4ng th\u1EC3 l\u01B0u th\u00F4ng tin");
            showMessage("success", "\u0110\u00E3 l\u01B0u th\u00F4ng tin c\u00E1 nh\u00E2n.");
        } catch (error) {
            showMessage("error", error.message);
        }
    });
})();
