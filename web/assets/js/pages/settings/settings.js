(function () {
    const root = document.querySelector(".settings-page");
    if (!root) return;
    const context = document.querySelector('meta[name="app-context-path"]')?.content || "";
    const personalForm = document.getElementById("personalForm");
    const personalMessage = document.getElementById("personalMessage");
    const dialog = document.getElementById("accountDialog");
    let profile = null;
    let editing = false;

    function showMessage(element, text, error) {
        element.hidden = false;
        element.textContent = text;
        element.className = "settings-message" + (error ? " error" : "");
    }

    function setField(name, value) {
        const field = document.querySelector(`[data-field="${name}"]`);
        if (field) field.value = value || "";
        const text = document.querySelector(`strong[data-field="${name}"]`);
        if (text) text.textContent = value || "Chưa cập nhật";
    }

    function render(data) {
        profile = data;
        ["fullName", "dateOfBirth", "gender", "phone", "address"].forEach(name => setField(name, data[name]));
        setField("email", data.email);
        setField("accountPhone", data.phone);
        setField("createdAt", data.createdAt ? data.createdAt.replace("T", " ") : "");
        ["department", "labName", "deskLocation"].forEach(name => setField(name, data[name]));
        document.querySelectorAll("[data-role-field]").forEach(el => { el.hidden = !data[el.dataset.roleField]; });
    }

    async function request(path, options) {
        const response = await fetch(context + "/settings" + path, { credentials: "same-origin", ...options });
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || "Có lỗi xảy ra");
        return data;
    }

    function setEditing(value) {
        editing = value;
        document.querySelectorAll("[data-field]").forEach(field => {
            if (["department", "labName", "deskLocation", "email", "accountPhone", "createdAt"].includes(field.dataset.field)) return;
            if (field.tagName === "SELECT") field.disabled = !value; else field.readOnly = !value;
        });
        document.querySelector('[data-edit="personal"]').hidden = value;
        const actions = document.querySelector('[data-edit-actions="personal"]');
        actions.hidden = !value;
        actions.style.display = value ? "flex" : "none";
    }

    document.querySelectorAll(".settings-tab").forEach(tab => tab.addEventListener("click", () => {
        document.querySelectorAll(".settings-tab").forEach(item => item.classList.toggle("active", item === tab));
        document.querySelectorAll("[data-panel]").forEach(panel => { panel.hidden = panel.dataset.panel !== tab.dataset.tab; });
    }));
    document.querySelector('[data-edit="personal"]').addEventListener("click", () => setEditing(true));
    document.querySelector('[data-cancel="personal"]').addEventListener("click", () => { render(profile); setEditing(false); });
    personalForm.addEventListener("submit", async event => {
        event.preventDefault();
        try {
            const result = await request("/profile", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" }, body: new URLSearchParams(new FormData(personalForm)) });
            if (!result.success) throw new Error(result.error);
            profile = await request("/profile"); render(profile); setEditing(false); showMessage(personalMessage, "Đã lưu thông tin cá nhân.", false);
        } catch (error) { showMessage(personalMessage, error.message, true); }
    });

    function openDialog(type) {
        document.getElementById("emailFields").hidden = type !== "email";
        document.getElementById("passwordFields").hidden = type !== "password";
        document.getElementById("dialogTitle").textContent = type === "email" ? "Đổi email" : "Đổi mật khẩu";
        document.getElementById("dialogMessage").hidden = true;
        document.getElementById("accountDialogForm").dataset.type = type;
        dialog.showModal();
    }
    document.querySelector('[data-action="email"]').addEventListener("click", () => openDialog("email"));
    document.querySelector('[data-action="password"]').addEventListener("click", () => openDialog("password"));
    document.getElementById("accountDialogForm").addEventListener("submit", async event => {
        if (event.submitter && event.submitter.value === "cancel") {
            return;
        }
        event.preventDefault();
        const form = event.currentTarget; const type = form.dataset.type;
        const params = type === "email"
            ? { newEmail: document.getElementById("newEmail").value, currentPassword: document.getElementById("emailPassword").value }
            : { currentPassword: document.getElementById("currentPassword").value, newPassword: document.getElementById("newPassword").value, confirmation: document.getElementById("passwordConfirmation").value };
        try {
            const result = await request("/" + type, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" }, body: new URLSearchParams(params) });
            if (!result.success) throw new Error(result.error);
            dialog.close(); profile = await request("/profile"); render(profile); showMessage(personalMessage, type === "email" ? "Đã đổi email." : "Đã đổi mật khẩu.", false);
        } catch (error) { showMessage(document.getElementById("dialogMessage"), error.message, true); }
    });
    request("/profile").then(render).catch(error => showMessage(personalMessage, error.message, true));
})();
