(function () {
    const list = document.getElementById("invoiceList");
    const filter = document.getElementById("invoiceStatusFilter");
    const search = document.getElementById("invoiceSearch");
    const dateFilter = document.getElementById("invoiceDateFilter");
    let invoices = [];
    const money = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" });

    function render() {
        const query = search.value.trim();
        const visible = invoices.filter((invoice) =>
            (!filter.value || invoice.status === filter.value)
            && (!query || String(invoice.invoiceId).includes(query)));
        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Kh\u00F4ng c\u00F3 h\u00F3a \u0111\u01A1n ph\u00F9 h\u1EE3p.";
            return;
        }
        visible.forEach((invoice) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `H\u00F3a \u0111\u01A1n #${invoice.invoiceId}`;
            const amount = document.createElement("p");
            amount.textContent = `S\u1ED1 ti\u1EC1n: ${money.format(invoice.finalAmount)}`;
            const method = document.createElement("p");
            method.textContent = `Ph\u01B0\u01A1ng th\u1EE9c: ${invoice.paymentMethod || "Ch\u01B0a ch\u1ECDn"}`;
            const badge = document.createElement("span");
            badge.className = `status-pill ${invoice.status === "Paid" ? "completed" : "waiting"}`;
            badge.textContent = invoice.status === "Paid" ? "\u0110\u00E3 thanh to\u00E1n" : "Ch\u01B0a thanh to\u00E1n";
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/invoices/detail?id=${invoice.invoiceId}`);
            link.textContent = "Xem chi ti\u1EBFt";
            info.append(title, amount, method, badge);
            item.append(info, link);
            list.append(item);
        });
    }
    filter.addEventListener("change", render);
    search.addEventListener("input", render);
    dateFilter.addEventListener("change", loadInvoices);

    function loadInvoices() {
        const query = dateFilter.value
            ? `?searchDate=${encodeURIComponent(dateFilter.value)}` : "";
        list.classList.add("loading-state");
        ApiClient.get(`/patient/api/invoices${query}`)
            .then((data) => { invoices = data.invoices || []; render(); })
            .catch((error) => { list.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i h\u00F3a \u0111\u01A1n: ${error.message}`; })
            .finally(() => list.classList.remove("loading-state"));
    }

    loadInvoices();
})();
