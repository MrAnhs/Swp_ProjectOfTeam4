(function () {
    const invoiceId = Number(new URLSearchParams(window.location.search).get("id"));
    const title = document.getElementById("invoiceTitle");
    const meta = document.getElementById("invoiceMeta");
    const detail = document.getElementById("invoiceDetail");
    const money = new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND"
    });
    const dateTime = new Intl.DateTimeFormat("vi-VN", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    });

    function text(value, fallback = "Chưa cập nhật") {
        return value ? String(value) : fallback;
    }

    function formatDateTime(value) {
        if (!value) {
            return "Chưa có";
        }
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? "Không xác định" : dateTime.format(parsed);
    }

    function statusText(status) {
        return status === "Paid" ? "Đã thanh toán" : "Chưa thanh toán";
    }

    function paymentMethodText(method) {
        const labels = {
            Cash: "Tiền mặt",
            Momo: "Ví MoMo",
            VNPay: "VNPay",
            Bank_Transfer: "Chuyển khoản ngân hàng"
        };
        return labels[method] || "Chưa chọn";
    }

    function serviceTypeText(type) {
        if (type === "Lab_Test") {
            return "Xét nghiệm";
        }
        if (type === "Examination") {
            return "Khám bệnh";
        }
        return text(type, "Dịch vụ y tế");
    }

    function createInfoItem(label, value) {
        const item = document.createElement("div");
        item.className = "invoice-info-item";
        const name = document.createElement("span");
        name.textContent = label;
        const content = document.createElement("strong");
        content.textContent = value;
        item.append(name, content);
        return item;
    }

    function createInvoiceHeader(invoice) {
        const header = document.createElement("section");
        header.className = "invoice-document-header";

        const brand = document.createElement("div");
        brand.className = "invoice-brand";
        const brandIcon = document.createElement("span");
        brandIcon.innerHTML = '<i class="bi bi-heart-pulse-fill"></i>';
        const brandText = document.createElement("div");
        const systemName = document.createElement("strong");
        systemName.textContent = "DiabetesCare";
        const systemDescription = document.createElement("span");
        systemDescription.textContent = "Hệ thống theo dõi và chăm sóc sức khỏe";
        brandText.append(systemName, systemDescription);
        brand.append(brandIcon, brandText);

        const heading = document.createElement("div");
        heading.className = "invoice-heading";
        const invoiceLabel = document.createElement("span");
        invoiceLabel.textContent = "HÓA ĐƠN DỊCH VỤ Y TẾ";
        const invoiceNumber = document.createElement("h2");
        invoiceNumber.textContent = `Số: HD-${String(invoice.invoiceId).padStart(6, "0")}`;
        const badge = document.createElement("span");
        badge.className = `status-pill ${
            invoice.status === "Paid" ? "completed" : "waiting"
        }`;
        badge.textContent = statusText(invoice.status);
        heading.append(invoiceLabel, invoiceNumber, badge);

        header.append(brand, heading);
        return header;
    }

    function createInformationSection(invoice) {
        const section = document.createElement("section");
        section.className = "invoice-information";

        const invoiceBlock = document.createElement("div");
        invoiceBlock.className = "invoice-info-block";
        const invoiceTitle = document.createElement("h3");
        invoiceTitle.textContent = "Thông tin hóa đơn";
        const invoiceGrid = document.createElement("div");
        invoiceGrid.className = "invoice-info-grid";
        invoiceGrid.append(
            createInfoItem("Mã hóa đơn", `HD-${String(invoice.invoiceId).padStart(6, "0")}`),
            createInfoItem("Ngày tạo", formatDateTime(invoice.createdAt)),
            createInfoItem("Ngày xuất", formatDateTime(invoice.exportedAt)),
            createInfoItem("Phương thức thanh toán",
                paymentMethodText(invoice.paymentMethod))
        );
        invoiceBlock.append(invoiceTitle, invoiceGrid);

        const patientBlock = document.createElement("div");
        patientBlock.className = "invoice-info-block";
        const patientTitle = document.createElement("h3");
        patientTitle.textContent = "Thông tin bệnh nhân";
        const patientGrid = document.createElement("div");
        patientGrid.className = "invoice-info-grid";
        patientGrid.append(
            createInfoItem("Mã bệnh nhân", `BN-${String(invoice.patientId).padStart(6, "0")}`),
            createInfoItem("Họ và tên", text(invoice.patientName)),
            createInfoItem("Số điện thoại", text(invoice.patientPhone)),
            createInfoItem("Email", text(invoice.patientEmail))
        );
        if (invoice.patientAddress) {
            const address = createInfoItem("Địa chỉ", invoice.patientAddress);
            address.classList.add("invoice-info-item--wide");
            patientGrid.append(address);
        }
        patientBlock.append(patientTitle, patientGrid);

        section.append(invoiceBlock, patientBlock);
        return section;
    }

    function createItemsTable(items) {
        const section = document.createElement("section");
        section.className = "invoice-service-section";
        const heading = document.createElement("h3");
        heading.textContent = "Chi tiết dịch vụ";
        section.append(heading);

        if (!items.length) {
            const empty = document.createElement("p");
            empty.className = "loading-state";
            empty.textContent = "Hóa đơn chưa có dịch vụ.";
            section.append(empty);
            return section;
        }

        const wrapper = document.createElement("div");
        wrapper.className = "invoice-table-wrapper";
        const table = document.createElement("table");
        table.className = "invoice-service-table";

        const head = document.createElement("thead");
        const headRow = document.createElement("tr");
        ["STT", "Dịch vụ", "Mã lịch hẹn", "Đơn giá", "Số lượng", "Thành tiền"]
            .forEach((label) => {
                const cell = document.createElement("th");
                cell.textContent = label;
                headRow.append(cell);
            });
        head.append(headRow);

        const body = document.createElement("tbody");
        items.forEach((service, index) => {
            const row = document.createElement("tr");

            const order = document.createElement("td");
            order.textContent = String(index + 1);

            const serviceCell = document.createElement("td");
            const serviceName = document.createElement("strong");
            serviceName.textContent = service.serviceName;
            const serviceType = document.createElement("small");
            serviceType.textContent = serviceTypeText(service.serviceType);
            serviceCell.append(serviceName, serviceType);

            const appointment = document.createElement("td");
            appointment.textContent = `#${service.appointmentId}`;

            const price = document.createElement("td");
            price.textContent = money.format(service.price);

            const quantity = document.createElement("td");
            quantity.textContent = String(service.quantity);

            const lineTotal = document.createElement("td");
            lineTotal.className = "invoice-line-total";
            lineTotal.textContent = money.format(service.price * service.quantity);

            row.append(order, serviceCell, appointment, price, quantity, lineTotal);
            body.append(row);
        });

        table.append(head, body);
        wrapper.append(table);
        section.append(wrapper);
        return section;
    }

    function createTotals(invoice) {
        const totals = document.createElement("section");
        totals.className = "invoice-totals";

        const total = document.createElement("p");
        total.append(createSpan("Tạm tính"), createStrong(money.format(invoice.totalAmount)));

        const deduction = document.createElement("p");
        deduction.append(
            createSpan("Giảm trừ bảo hiểm"),
            createStrong(`-${money.format(invoice.insuranceDeduction)}`)
        );

        const finalAmount = document.createElement("p");
        finalAmount.className = "invoice-final";
        finalAmount.append(
            createSpan(invoice.status === "Paid" ? "Đã thanh toán" : "Cần thanh toán"),
            createStrong(money.format(invoice.finalAmount))
        );

        totals.append(total, deduction, finalAmount);
        return totals;
    }

    function createSpan(value) {
        const element = document.createElement("span");
        element.textContent = value;
        return element;
    }

    function createStrong(value) {
        const element = document.createElement("strong");
        element.textContent = value;
        return element;
    }

    function createPaymentForm(invoice) {
        const form = document.createElement("form");
        form.className = "payment-request-form";
        form.innerHTML = `
            <label>Phương thức thanh toán
                <select name="paymentMethod" required>
                    <option value="">Chọn phương thức</option>
                    <option value="Cash">Tiền mặt</option>
                    <option value="Momo">MoMo</option>
                    <option value="VNPay">VNPay</option>
                    <option value="Bank_Transfer">Chuyển khoản ngân hàng</option>
                </select>
            </label>
            <button class="btn-page-primary" type="submit">Gửi yêu cầu thanh toán</button>
            <div class="form-message" hidden></div>
        `;
        form.paymentMethod.value = invoice.paymentMethod || "";
        form.addEventListener("submit", async (event) => {
            event.preventDefault();
            const message = form.querySelector(".form-message");
            try {
                const result = await ApiClient.postForm(
                    "/patient/api/invoices",
                    new URLSearchParams({
                        invoiceId: String(invoice.invoiceId),
                        paymentMethod: form.paymentMethod.value
                    })
                );
                message.hidden = false;
                message.className = "form-message success";
                message.textContent = result.message;
            } catch (error) {
                message.hidden = false;
                message.className = "form-message error";
                message.textContent = error.message;
            }
        });
        return form;
    }

    function render(data) {
        const invoice = data.invoice;
        title.textContent = `Hóa đơn #${invoice.invoiceId}`;
        meta.textContent = `Ngày tạo: ${formatDateTime(invoice.createdAt)} • ${
            statusText(invoice.status)
        }`;
        detail.replaceChildren();
        detail.className = "invoice-document";

        detail.append(
            createInvoiceHeader(invoice),
            createInformationSection(invoice),
            createItemsTable(data.items || []),
            createTotals(invoice)
        );

        if (invoice.status === "Pending") {
            detail.append(createPaymentForm(invoice));
        }
    }

    if (!Number.isInteger(invoiceId) || invoiceId <= 0) {
        detail.textContent = "Mã hóa đơn không hợp lệ.";
        return;
    }

    ApiClient.get(`/patient/api/invoices?id=${invoiceId}`)
        .then(render)
        .catch((error) => {
            detail.textContent = error.message;
            meta.textContent = "";
        });
})();
