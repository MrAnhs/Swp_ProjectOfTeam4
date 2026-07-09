document.addEventListener("DOMContentLoaded", function () {
    const navbar = document.getElementById("navbar");
    if (!navbar) {
        return;
    }

    window.addEventListener("scroll", function () {
        if (window.scrollY > 50) {
            navbar.classList.add("scrolled");
        } else {
            navbar.classList.remove("scrolled");
        }
    });
});
