const menuButton = document.querySelector("[data-menu-button]");
const navLinks = document.querySelector("[data-nav-links]");

if (menuButton && navLinks) {
  menuButton.addEventListener("click", () => {
    const isOpen = navLinks.classList.toggle("open");
    menuButton.setAttribute("aria-expanded", String(isOpen));
  });

  navLinks.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      navLinks.classList.remove("open");
      menuButton.setAttribute("aria-expanded", "false");
    });
  });
}

const path = window.location.pathname;
document.querySelectorAll("[data-nav-links] a").forEach((link) => {
  const href = link.getAttribute("href") || "";
  if (!href || href.startsWith("http")) {
    return;
  }
  const normalizedHref = new URL(href, window.location.href).pathname;
  if (normalizedHref === path || (path.endsWith("/") && normalizedHref.endsWith("/index.html"))) {
    link.classList.add("active");
  }
});
