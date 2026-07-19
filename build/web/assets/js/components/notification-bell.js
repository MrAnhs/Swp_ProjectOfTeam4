(function () {
    const center = document.querySelector('[data-notification-center]');
    if (!center || center.dataset.notificationInitialized === 'true') return;
    center.dataset.notificationInitialized = 'true';
    const context = center.dataset.contextPath || '';
    const trigger = center.querySelector('[data-notification-trigger]');
    const dropdown = center.querySelector('[data-notification-dropdown]');
    const list = center.querySelector('[data-notification-list]');
    const badge = center.querySelector('[data-notification-badge]');

    function setCount(count) {
        const value = Math.max(0, Number(count) || 0);
        badge.textContent = value > 99 ? '99+' : value;
        badge.classList.toggle('is-hidden', value === 0);
    }

    function render(items) {
        list.replaceChildren();
        if (!items.length) {
            const empty = document.createElement('p');
            empty.className = 'notification-empty';
            empty.textContent = 'Bạn không có thông báo mới.';
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
                event.preventDefault();
                fetch(context + '/notifications/' + encodeURIComponent(item.id) + '/read', { method: 'POST', credentials: 'same-origin' })
                    .then(response => { if (!response.ok) throw new Error('Không thể cập nhật thông báo'); return response.json(); })
                    .then(() => {
                        if (!item.isRead) setCount(Math.max(0, Number(badge.textContent) - 1));
                        if (item.targetUrl) window.location.assign(item.targetUrl);
                    })
                    .catch(() => { if (item.targetUrl) window.location.assign(item.targetUrl); });
            });
            list.appendChild(element);
        });
    }

    function load() {
        list.replaceChildren();
        const loading = document.createElement('p');
        loading.className = 'notification-empty';
        loading.textContent = 'Đang tải thông báo...';
        list.appendChild(loading);
        fetch(context + '/notifications', { credentials: 'same-origin' })
            .then(response => { if (!response.ok) throw new Error(); return response.json(); })
            .then(data => render(Array.isArray(data.notifications) ? data.notifications : []))
            .catch(() => {
                list.replaceChildren();
                const error = document.createElement('p');
                error.className = 'notification-error';
                error.textContent = 'Không thể tải thông báo.';
                list.appendChild(error);
            });
    }

    trigger.addEventListener('click', function () {
        const shouldOpen = dropdown.hidden;
        dropdown.hidden = !shouldOpen;
        trigger.setAttribute('aria-expanded', String(shouldOpen));
        if (shouldOpen) load();
    });
    center.querySelector('[data-notification-close]').addEventListener('click', function () {
        dropdown.hidden = true;
        trigger.setAttribute('aria-expanded', 'false');
    });
    document.addEventListener('click', function (event) {
        if (!center.contains(event.target)) {
            dropdown.hidden = true;
            trigger.setAttribute('aria-expanded', 'false');
        }
    });
}());

