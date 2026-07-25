(function () {
    const page = document.querySelector('[data-notification-page]');
    if (!page) return;

    const context = page.dataset.contextPath || '';
    const list = page.querySelector('[data-notification-list]');
    const totalElement = page.querySelector('[data-notification-total]');
    const unreadElement = page.querySelector('[data-notification-unread]');
    const description = page.querySelector('[data-notification-description]');
    const footer = page.querySelector('[data-notification-footer]');
    const refreshButton = page.querySelector('[data-notification-refresh]');
    const viewAllButton = page.querySelector('[data-notification-view-all]');
    const filterButtons = Array.from(page.querySelectorAll('[data-notification-filter]'));
    let notifications = [];
    let mode = 'recent';

    const labels = {
        loading: 'Đang tải thông báo...',
        emptyTitle: 'Chưa có thông báo',
        emptyText: 'Các cập nhật mới từ hệ thống sẽ xuất hiện tại đây.',
        error: 'Không thể tải thông báo. Vui lòng thử lại.',
        defaultTitle: 'Thông báo',
        recentDescription: 'Hiển thị 5 thông báo mới nhất.',
        allDescription: 'Hiển thị tất cả thông báo gần đây.'
    };

    function formatDate(value) {
        if (!value) return '';
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return value;
        return new Intl.DateTimeFormat('vi-VN', {
            hour: '2-digit', minute: '2-digit',
            day: '2-digit', month: '2-digit', year: 'numeric'
        }).format(date);
    }

    function iconFor(type) {
        const normalized = String(type || '').toLowerCase();
        if (normalized.includes('success') || normalized.includes('complete') || normalized.includes('paid')) {
            return { icon: 'bi-check-circle', className: 'success' };
        }
        if (normalized.includes('warning') || normalized.includes('appointment') || normalized.includes('reminder')) {
            return { icon: 'bi-calendar-event', className: 'warning' };
        }
        return { icon: 'bi-bell', className: '' };
    }

    function resolveTargetUrl(targetUrl, type, title, content) {
        if (targetUrl) {
            if (/^https?:\/\//i.test(targetUrl) || targetUrl.startsWith(context + '/')) {
                return targetUrl;
            }
            return context + (targetUrl.startsWith('/') ? targetUrl : '/' + targetUrl);
        }
        const normType = String(type || '').toLowerCase();
        const normTitle = String(title || '').toLowerCase();
        const normContent = String(content || '').toLowerCase();
        if (normType.includes('appointment') || normTitle.includes('lịch') || normContent.includes('lịch')) {
            return context + '/patient/appointments';
        }
        return '';
    }

    function updateSummary() {
        totalElement.textContent = notifications.length;
        unreadElement.textContent = notifications.filter(item => !item.isRead).length;
    }

    function setMode(nextMode) {
        mode = nextMode;
        filterButtons.forEach(button => {
            button.classList.toggle('active', button.dataset.notificationFilter === mode);
        });
        description.textContent = mode === 'all' ? labels.allDescription : labels.recentDescription;
        render();
    }

    function createItem(item) {
        const element = document.createElement('article');
        element.className = 'patient-notification-item' + (item.isRead ? '' : ' is-unread');
        element.tabIndex = 0;
        element.setAttribute('role', 'button');

        const iconInfo = iconFor(item.type);
        const icon = document.createElement('span');
        icon.className = 'patient-notification-icon ' + iconInfo.className;
        const iconGlyph = document.createElement('i');
        iconGlyph.className = 'bi ' + iconInfo.icon;
        icon.appendChild(iconGlyph);

        const content = document.createElement('div');
        content.className = 'patient-notification-content';
        const title = document.createElement('h3');
        title.textContent = item.title || labels.defaultTitle;
        const message = document.createElement('p');
        message.textContent = item.content || '';
        const meta = document.createElement('div');
        meta.className = 'patient-notification-meta';
        if (!item.isRead) {
            const dot = document.createElement('span');
            dot.className = 'notification-unread-dot';
            meta.appendChild(dot);
        }
        const time = document.createElement('span');
        time.textContent = formatDate(item.createdAt);
        meta.appendChild(time);
        content.append(title, message, meta);

        const chevron = document.createElement('i');
        chevron.className = 'bi bi-chevron-right patient-notification-chevron';
        element.append(icon, content, chevron);

        function openNotification() {
            const destUrl = resolveTargetUrl(item.targetUrl, item.type, item.title, item.content);
            const finish = function () {
                item.isRead = true;
                updateSummary();
                if (destUrl) {
                    window.location.assign(destUrl);
                } else {
                    render();
                }
            };
            if (item.isRead) {
                if (destUrl) window.location.assign(destUrl);
                return;
            }
            fetch(context + '/notifications/' + encodeURIComponent(item.id) + '/read', {
                method: 'POST', credentials: 'same-origin'
            }).then(response => {
                if (!response.ok) throw new Error();
                return response.json();
            }).then(finish).catch(function () {
                if (destUrl) window.location.assign(destUrl);
            });
        }

        element.addEventListener('click', openNotification);
        element.addEventListener('keydown', function (event) {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                openNotification();
            }
        });
        return element;
    }

    function render() {
        list.replaceChildren();
        const visibleItems = mode === 'all' ? notifications : notifications.slice(0, 5);
        footer.hidden = mode === 'all' || notifications.length <= 5;

        if (!visibleItems.length) {
            const empty = document.createElement('div');
            empty.className = 'notification-page-empty';
            empty.innerHTML = '<i class="bi bi-inbox"></i>';
            const title = document.createElement('strong');
            title.textContent = labels.emptyTitle;
            const text = document.createElement('span');
            text.textContent = labels.emptyText;
            empty.append(title, text);
            list.appendChild(empty);
            return;
        }
        visibleItems.forEach(item => list.appendChild(createItem(item)));
    }

    function showLoading() {
        list.innerHTML = '<div class="notification-page-loading"><span class="notification-spinner"></span>' + labels.loading + '</div>';
    }

    function load() {
        showLoading();
        refreshButton.classList.add('is-loading');
        refreshButton.disabled = true;
        fetch(context + '/notifications/all', { credentials: 'same-origin' })
            .then(response => { if (!response.ok) throw new Error(); return response.json(); })
            .then(data => {
                notifications = Array.isArray(data.notifications) ? data.notifications : [];
                updateSummary();
                render();
            })
            .catch(() => {
                list.innerHTML = '<div class="notification-page-error"><i class="bi bi-exclamation-circle"></i><span>' + labels.error + '</span></div>';
                footer.hidden = true;
            })
            .finally(() => {
                refreshButton.classList.remove('is-loading');
                refreshButton.disabled = false;
            });
    }

    filterButtons.forEach(button => {
        button.addEventListener('click', () => setMode(button.dataset.notificationFilter));
    });
    viewAllButton.addEventListener('click', () => setMode('all'));
    refreshButton.addEventListener('click', load);
    load();
}());
