(function () {
    const page = document.querySelector('[data-notifications-page]');
    if (!page) return;
    const context = page.dataset.contextPath || '';
    const list = page.querySelector('[data-notifications-list]');
    const refresh = page.querySelector('[data-notifications-refresh]');

    function render(items) {
        list.replaceChildren();
        if (!items.length) {
            const empty = document.createElement('p');
            empty.className = 'notification-empty';
            empty.textContent = 'Bạn không có thông báo nào.';
            list.appendChild(empty);
            return;
        }
        items.forEach(item => {
            const element = document.createElement('a');
            element.className = 'notification-item' + (item.isRead ? '' : ' is-unread');
            if (item.targetUrl) element.href = item.targetUrl;
            const title = document.createElement('span');
            title.className = 'notification-item-title';
            title.textContent = item.title || 'Thông báo';
            const content = document.createElement('span');
            content.className = 'notification-item-content';
            content.textContent = item.content || '';
            const time = document.createElement('span');
            time.className = 'notification-item-time';
            time.textContent = item.createdAt || '';
            element.append(title, content, time);
            element.addEventListener('click', function (event) {
                if (item.isRead) return;
                event.preventDefault();
                fetch(context + '/notifications/' + encodeURIComponent(item.id) + '/read', { method: 'POST', credentials: 'same-origin' })
                    .then(response => { if (!response.ok) throw new Error(); return response.json(); })
                    .then(() => { item.isRead = true; element.classList.remove('is-unread'); if (item.targetUrl) window.location.assign(item.targetUrl); })
                    .catch(() => { if (item.targetUrl) window.location.assign(item.targetUrl); });
            });
            list.appendChild(element);
        });
    }

    function load() {
        list.innerHTML = '<p class="notification-empty">Đang tải thông báo...</p>';
        fetch(context + '/notifications/all', { credentials: 'same-origin' })
            .then(response => { if (!response.ok) throw new Error(); return response.json(); })
            .then(data => render(Array.isArray(data.notifications) ? data.notifications : []))
            .catch(() => { list.innerHTML = '<p class="notification-error">Không thể tải thông báo.</p>'; });
    }
    refresh.addEventListener('click', load);
    load();
}());
