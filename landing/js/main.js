(function () {
  "use strict";

  var reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

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
    var isOpen = function () { return toggle.getAttribute("aria-expanded") === "true"; };
    toggle.addEventListener("click", function () { setOpen(!isOpen()); });
    menu.addEventListener("click", function (e) { if (e.target.closest("a")) setOpen(false); });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && isOpen()) { setOpen(false); toggle.focus(); }
    });
    // Se cierra al tocar fuera o cuando el foco sale del menú.
    document.addEventListener("click", function (e) {
      if (isOpen() && !menu.contains(e.target) && !toggle.contains(e.target)) setOpen(false);
    });
    menu.addEventListener("focusout", function (e) {
      if (isOpen() && e.relatedTarget && !menu.contains(e.relatedTarget) && e.relatedTarget !== toggle) setOpen(false);
    });
  }

  var hasIO = "IntersectionObserver" in window;

  /* ---------- Aparición al hacer scroll ---------- */
  var reveals = document.querySelectorAll("[data-reveal], [data-stagger]");
  if (!hasIO || reduceMotion) {
    reveals.forEach(function (el) { el.classList.add("is-visible"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { entry.target.classList.add("is-visible"); io.unobserve(entry.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    reveals.forEach(function (el) { io.observe(el); });
  }

  /* ---------- Así funciona ----------
     Escritorio: el paso visible elige la pantalla del celular fijo (con cortina, flor y avance).
     Celular: los puntos siguen el deslizamiento del carrusel. */
  var steps = document.querySelectorAll(".step[data-step]");
  var device = document.querySelector(".steps__device");
  var screens = document.querySelectorAll(".steps__screens img");
  var flores = document.querySelectorAll(".steps__flores img");
  var bars = document.querySelectorAll(".steps__progress span");
  var dots = document.querySelectorAll(".steps__dots span");
  var current = 0;
  var mark = function (list, i) { list.forEach(function (el, k) { el.classList.toggle("is-active", k === i); }); };
  var activate = function (i) {
    if (i === current && steps[i] && steps[i].classList.contains("is-active")) return;
    screens.forEach(function (img, k) {
      img.classList.toggle("is-prev", k === current && k !== i);
      img.classList.toggle("is-active", k === i);
    });
    current = i;
    mark(steps, i); mark(flores, i); mark(bars, i);
    if (device) device.setAttribute("data-active", String(i));
  };
  if (steps.length) {
    mark(steps, 0);
    if (hasIO) {
      var stepIO = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) activate(Number(entry.target.getAttribute("data-step")));
        });
      }, { rootMargin: "-45% 0px -45% 0px", threshold: 0 });
      steps.forEach(function (s) { stepIO.observe(s); });
    }
    var list = document.querySelector(".steps__list");
    var syncDots = function () {
      if (!list || list.scrollWidth <= list.clientWidth) return;
      var w = steps[0].getBoundingClientRect().width + 16;
      var i = Math.max(0, Math.min(steps.length - 1, Math.round(list.scrollLeft / w)));
      mark(dots, i);
      steps.forEach(function (s, k) { s.classList.toggle("is-current", k === i); });
    };
    if (list) { list.addEventListener("scroll", syncDots, { passive: true }); syncDots(); }
  }

  /* ---------- Mapa de la red: sin animación si se pidió reducir movimiento ---------- */
  if (reduceMotion) {
    document.querySelectorAll(".mesh-map").forEach(function (svg) {
      if (svg.pauseAnimations) svg.pauseAnimations();
      var dot = svg.querySelector(".mesh-map__dot");
      if (dot) dot.remove();
    });
  }
})();
