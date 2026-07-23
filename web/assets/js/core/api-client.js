(function () {
    function buildUrl(path) {
        if (/^https?:\/\//i.test(path)) {
            return path;
        }

        const normalizedPath = path.startsWith("/") ? path : `/${path}`;
        return `${window.AppConfig.contextPath}${normalizedPath}`;
    }

    async function request(path, options = {}) {
        const response = await fetch(buildUrl(path), {
            credentials: "same-origin",
            ...options
        });

        const contentType = response.headers.get("content-type") || "";
        const body = contentType.includes("application/json")
            ? await response.json()
            : await response.text();

        if (!response.ok) {
            const message = body && body.error ? body.error : `HTTP ${response.status}`;
            throw new Error(message);
        }

        return body;
    }

    window.ApiClient = Object.freeze({
        buildUrl,
        request,
        get: (path) => request(path),
        postForm: (path, data) => request(path, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: data instanceof URLSearchParams ? data : new URLSearchParams(data)
        })
    });
})();
