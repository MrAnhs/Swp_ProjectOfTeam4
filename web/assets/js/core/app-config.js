(function () {
    const meta = document.querySelector('meta[name="app-context-path"]');
    const configuredPath = meta ? meta.content : "";

    window.AppConfig = Object.freeze({
        contextPath: configuredPath.replace(/\/$/, "")
    });
})();
