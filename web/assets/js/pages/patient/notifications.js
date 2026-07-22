(async function () {
    const container = document.getElementById("notificationsContainer");
    const btnMarkAllRead = document.getElementById("btnMarkAllRead");
    const sidebarBadge = document.getElementById("sidebar-notification-badge");

    // Lấy định dạng thời gian thân thiện
    function formatTime(timeStr) {
        if (!timeStr) return "";
        try {
            // Cắt bớt phần mili giây nếu có
            const cleanStr = timeStr.split(".")[0];
            return cleanStr.replace("T", " ");
        } catch (e) {
            return timeStr;
        }
    }

    async function loadNotifications() {
        try {
            container.replaceChildren();
            container.className = "loading-state";
            container.textContent = "\u0110ang t\u1EA3i danh s\u00E1ch th\u00F4ng b\u00E1o...";

            const data = await ApiClient.get("/patient/api/notifications");
            const notifications = data.notifications || [];

            container.replaceChildren();
            container.className = "notification-list";

            if (notifications.length === 0) {
                container.className = "";
                const emptyState = document.createElement("div");
                emptyState.className = "empty-notifications";
                emptyState.innerHTML = `
                    <i class="bi bi-bell-slash"></i>
                    <p>B\u00E1n kh\u00F4ng c\u00F3 th\u00F4ng b\u00E1o n\u00E0o.</p>
                `;
                container.appendChild(emptyState);
                btnMarkAllRead.classList.add("d-none");
                updateSidebarBadge(0);
                return;
            }

            // Hiển thị nút "Đánh dấu tất cả đã đọc" nếu có thông báo chưa đọc
            if (data.unreadCount > 0) {
                btnMarkAllRead.classList.remove("d-none");
            } else {
                btnMarkAllRead.classList.add("d-none");
            }
            updateSidebarBadge(data.unreadCount);

            notifications.forEach(n => {
                const card = document.createElement("div");
                card.className = "notification-card" + (n.isRead ? "" : " unread");
                card.dataset.id = n.notificationId;

                const iconWrapper = document.createElement("div");
                iconWrapper.className = "notification-icon-wrapper";
                
                // Chọn icon theo loại thông báo
                let iconClass = "bi-bell-fill";
                if (n.type === "RevisitReminder") {
                    iconClass = "bi-calendar2-event-fill";
                }
                iconWrapper.innerHTML = `<i class="bi ${iconClass}"></i>`;

                const body = document.createElement("div");
                body.className = "notification-body";

                const title = document.createElement("h3");
                title.className = "notification-title";
                title.textContent = n.title;
                if (!n.isRead) {
                    const dot = document.createElement("span");
                    dot.className = "unread-dot";
                    title.appendChild(dot);
                }

                const content = document.createElement("p");
                content.className = "notification-content";
                content.textContent = n.content;

                const time = document.createElement("span");
                time.className = "notification-time";
                time.innerHTML = `<i class="bi bi-clock me-1"></i> ${formatTime(n.createdAt)}`;

                body.append(title, content, time);
                card.append(iconWrapper, body);

                // Thêm sự kiện click để đánh dấu đã đọc
                card.addEventListener("click", async () => {
                    if (card.classList.contains("unread")) {
                        try {
                            const res = await ApiClient.postForm("/patient/api/notifications", {
                                action: "markRead",
                                notificationId: n.notificationId
                            });
                            if (res.success) {
                                card.classList.remove("unread");
                                const dot = card.querySelector(".unread-dot");
                                if (dot) dot.remove();
                                
                                // Cập nhật lại số lượng badge ở sidebar
                                let currentCount = parseInt(sidebarBadge.textContent, 10) || 0;
                                if (currentCount > 0) {
                                    updateSidebarBadge(currentCount - 1);
                                }
                            }
                        } catch (err) {
                            console.error("L\u1ED7i khi \u0111\u00E1nh d\u1EA5u \u0111\u00E3 \u0111\u1ECDc:", err);
                        }
                    }
                });

                container.appendChild(card);
            });

        } catch (error) {
            container.className = "";
            container.textContent = `Kh\u00F4ng th\u1EC3 t\u1EA3i danh s\u00E1ch th\u00F4ng b\u00E1o: ${error.message}`;
        }
    }

    function updateSidebarBadge(count) {
        if (!sidebarBadge) return;
        if (count > 0) {
            sidebarBadge.textContent = count;
            sidebarBadge.classList.remove("d-none");
        } else {
            sidebarBadge.textContent = "0";
            sidebarBadge.classList.add("d-none");
            btnMarkAllRead.classList.add("d-none");
        }
    }

    btnMarkAllRead.addEventListener("click", async () => {
        try {
            const res = await ApiClient.postForm("/patient/api/notifications", {
                action: "markAllRead"
            });
            if (res.success) {
                // Đổi tất cả giao diện card thành đã đọc
                document.querySelectorAll(".notification-card.unread").forEach(card => {
                    card.classList.remove("unread");
                    const dot = card.querySelector(".unread-dot");
                    if (dot) dot.remove();
                });
                updateSidebarBadge(0);
            }
        } catch (err) {
            alert("Kh\u00F4ng th\u1EC3 \u0111\u00E1nh d\u1EA5u t\u1EA5t c\u1EA3 \u0111\u00E3 \u0111\u1ECDc: " + err.message);
        }
    });

    // Tải dữ liệu ban đầu
    loadNotifications();
})();
