(function () {
  "use strict";

  /* ---------- Menú móvil ---------- */
  var toggle = document.querySelector(".nav__toggle");
  var menu = document.getElementById("menu");
  if (toggle && menu) {
    var label = toggle.querySelector(".visually-hidden");
    var setOpen = function (open) {
      menu.classList.toggle("is-open", open);
      toggle.setAttribute("aria-expanded", String(open));
      if (label) label.textContent = open ? "Cerrar menú" : "Abrir menú";
    };
    toggle.addEventListener("click", function () {
      setOpen(toggle.getAttribute("aria-expanded") !== "true");
    });
    menu.addEventListener("click", function (e) {
      if (e.target.closest("a")) setOpen(false);
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && menu.classList.contains("is-open")) {
        setOpen(false);
        toggle.focus();
      }
    });
  }

})();
