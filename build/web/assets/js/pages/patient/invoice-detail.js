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

    function text(value, fallback = "Ch\u01B0a c\u1EADp nh\u1EADt") {
        return value ? String(value) : fallback;
    }

    function formatDateTime(value) {
        if (!value) {
            return "Ch\u01B0a c\u00F3";
        }
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? "Kh\u00F4ng x\u00E1c \u0111\u1ECBnh" : dateTime.format(parsed);
    }

    function statusText(status) {
        return status === "Paid" ? "\u0110\u00E3 thanh to\u00E1n" : "Ch\u01B0a thanh to\u00E1n";
    }

    function paymentMethodText(method) {
        const labels = {
            Cash: "Ti\u1EC1n m\u1EB7t",
            Momo: "V\u00ED MoMo",
            VNPay: "VNPay",
            Bank_Transfer: "Chuy\u1EC3n kho\u1EA3n ng\u00E2n h\u00E0ng"
        };
        return labels[method] || "Ch\u01B0a ch\u1ECDn";
    }

    function serviceTypeText(type) {
        if (type === "Lab_Test") {
            return "X\u00E9t nghi\u1EC7m";
        }
        if (type === "Examination") {
            return "Kh\u00E1m b\u1EC7nh";
        }
        return text(type, "D\u1ECBch v\u1EE5 y t\u1EBF");
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
        systemDescription.textContent = "H\u1EC7 th\u1ED1ng theo d\u00F5i v\u00E0 ch\u0103m s\u00F3c s\u1EE9c kh\u1ECFe";
        brandText.append(systemName, systemDescription);
        brand.append(brandIcon, brandText);

        const heading = document.createElement("div");
        heading.className = "invoice-heading";
        const invoiceLabel = document.createElement("span");
        invoiceLabel.textContent = "H\u00D3A \u0110\u01A0N D\u1ECACH V\u1EE4 Y T\u1EBE";
        const invoiceNumber = document.createElement("h2");
        invoiceNumber.textContent = `S\u1ED1: HD-${String(invoice.invoiceId).padStart(6, "0")}`;
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
        invoiceTitle.textContent = "Th\u00F4ng tin h\u00F3a \u0111\u01A1n";
        const invoiceGrid = document.createElement("div");
        invoiceGrid.className = "invoice-info-grid";
        invoiceGrid.append(
            createInfoItem("M\u00E3 h\u00F3a \u0111\u01A1n", `HD-${String(invoice.invoiceId).padStart(6, "0")}`),
            createInfoItem("Ng\u00E0y t\u1EA1o", formatDateTime(invoice.createdAt)),
            createInfoItem("Ng\u00E0y xu\u1EA5t", formatDateTime(invoice.exportedAt)),
            createInfoItem("Ph\u01B0\u01A1ng th\u1EE9c thanh to\u00E1n",
                paymentMethodText(invoice.paymentMethod))
        );
        invoiceBlock.append(invoiceTitle, invoiceGrid);

        const patientBlock = document.createElement("div");
        patientBlock.className = "invoice-info-block";
        const patientTitle = document.createElement("h3");
        patientTitle.textContent = "Th\u00F4ng tin b\u1EC7nh nh\u00E2n";
        const patientGrid = document.createElement("div");
        patientGrid.className = "invoice-info-grid";
        patientGrid.append(
            createInfoItem("M\u00E3 b\u1EC7nh nh\u00E2n", `BN-${String(invoice.patientId).padStart(6, "0")}`),
            createInfoItem("H\u1ECD v\u00E0 t\u00EAn", text(invoice.patientName)),
            createInfoItem("S\u1ED1 \u0111i\u1EC7n tho\u1EA1i", text(invoice.patientPhone)),
            createInfoItem("Email", text(invoice.patientEmail))
        );
        if (invoice.patientAddress) {
            const address = createInfoItem("\u0110\u1ECBa ch\u1EC9", invoice.patientAddress);
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
        heading.textContent = "Chi ti\u1EBFt d\u1ECBch v\u1EE5";
        section.append(heading);

        if (!items.length) {
            const empty = document.createElement("p");
            empty.className = "loading-state";
            empty.textContent = "H\u00F3a \u0111\u01A1n ch\u01B0a c\u00F3 d\u1ECBch v\u1EE5.";
            section.append(empty);
            return section;
        }

        const wrapper = document.createElement("div");
        wrapper.className = "invoice-table-wrapper";
        const table = document.createElement("table");
        table.className = "invoice-service-table";

        const head = document.createElement("thead");
        const headRow = document.createElement("tr");
        ["STT", "D\u1ECBch v\u1EE5", "M\u00E3 l\u1ECBch h\u1EB9n", "\u0110\u01A1n gi\u00E1", "S\u1ED1 l\u01B0\u1EE3ng", "Th\u00E0nh ti\u1EC1n"]
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
        total.append(createSpan("T\u1EA1m t\u00EDnh"), createStrong(money.format(invoice.totalAmount)));

        const deduction = document.createElement("p");
        deduction.append(
            createSpan("Gi\u1EA3m tr\u1EEB b\u1EA3o hi\u1EC3m"),
            createStrong(`-${money.format(invoice.insuranceDeduction)}`)
        );

        const finalAmount = document.createElement("p");
        finalAmount.className = "invoice-final";
        finalAmount.append(
            createSpan(invoice.status === "Paid" ? "\u0110\u00E3 thanh to\u00E1n" : "C\u1EA7n thanh to\u00E1n"),
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
            <label>Ph\u01B0\u01A1ng th\u1EE9c thanh to\u00E1n
                <select name="paymentMethod" required>
                    <option value="">Ch\u1ECDn ph\u01B0\u01A1ng th\u1EE9c</option>
                    <option value="Cash">Ti\u1EC1n m\u1EB7t</option>
                    <option value="Momo">MoMo</option>
                    <option value="VNPay">VNPay</option>
                    <option value="Bank_Transfer">Chuy\u1EC3n kho\u1EA3n ng\u00E2n h\u00E0ng</option>
                </select>
            </label>
            <button class="btn-page-primary" type="submit">G\u1EEDi y\u00EAu c\u1EA7u thanh to\u00E1n</button>
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
        title.textContent = `H\u00F3a \u0111\u01A1n #${invoice.invoiceId}`;
        meta.textContent = `Ng\u00E0y t\u1EA1o: ${formatDateTime(invoice.createdAt)} \u2022 ${
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
        detail.textContent = "M\u00E3 h\u00F3a \u0111\u01A1n kh\u00F4ng h\u1EE3p l\u1EC7.";
        return;
    }

    ApiClient.get(`/patient/api/invoices?id=${invoiceId}`)
        .then(render)
        .catch((error) => {
            detail.textContent = error.message;
            meta.textContent = "";
        });
})();
