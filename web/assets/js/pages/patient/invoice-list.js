(function () {
    const list = document.getElementById("invoiceList");
    const filter = document.getElementById("invoiceStatusFilter");
    const search = document.getElementById("invoiceSearch");
    let invoices = [];
    const money = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" });

    function render() {
        const query = search.value.trim();
        const visible = invoices.filter((invoice) =>
            (!filter.value || invoice.status === filter.value)
            && (!query || String(invoice.invoiceId).includes(query)));
        list.replaceChildren();
        if (!visible.length) {
            list.textContent = "Không có hóa đơn phù hợp.";
            return;
        }
        visible.forEach((invoice) => {
            const item = document.createElement("article");
            item.className = "record-item";
            const info = document.createElement("div");
            const title = document.createElement("h3");
            title.textContent = `Hóa đơn #${invoice.invoiceId}`;
            const amount = document.createElement("p");
            amount.textContent = `Số tiền: ${money.format(invoice.finalAmount)}`;
            const method = document.createElement("p");
            method.textContent = `Phương thức: ${invoice.paymentMethod || "Chưa chọn"}`;
            const badge = document.createElement("span");
            badge.className = `status-pill ${invoice.status === "Paid" ? "completed" : "waiting"}`;
            badge.textContent = invoice.status === "Paid" ? "Đã thanh toán" : "Chưa thanh toán";
            const link = document.createElement("a");
            link.className = "btn-page-secondary";
            link.href = ApiClient.buildUrl(`/patient/invoices/detail?id=${invoice.invoiceId}`);
            link.textContent = "Xem chi tiết";
            info.append(title, amount, method, badge);
            item.append(info, link);
            list.append(item);
        });
    }
    filter.addEventListener("change", render);
    search.addEventListener("input", render);
    ApiClient.get("/patient/api/invoices")
        .then((data) => { invoices = data.invoices || []; render(); })
        .catch((error) => { list.textContent = `Không thể tải hóa đơn: ${error.message}`; });
})();
