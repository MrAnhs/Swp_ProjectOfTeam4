window.addEventListener("scroll", function () {
    const navbar = document.getElementById("navbar");
    if (!navbar) return;
    navbar.classList.toggle("scrolled", window.scrollY > 50);
});

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener("click", function (event) {
        const target = document.querySelector(this.getAttribute("href"));
        if (!target) return;
        event.preventDefault();
        target.scrollIntoView({ behavior: "smooth" });
    });
});
