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
  }

  /* ---------- Carruseles en celular: puntos que siguen el deslizamiento ---------- */
  document.querySelectorAll("[data-carousel]").forEach(function (list) {
    var items = Array.prototype.slice.call(list.children);
    if (items.length < 2) return;
    var dotsBox = document.createElement("div");
    dotsBox.className = "carousel-dots";
    dotsBox.setAttribute("aria-hidden", "true");
    items.forEach(function () { dotsBox.appendChild(document.createElement("span")); });
    list.insertAdjacentElement("afterend", dotsBox);
    var spans = dotsBox.querySelectorAll("span");
    var sync = function () {
      var scrollable = list.scrollWidth > list.clientWidth + 4;
      dotsBox.hidden = !scrollable;
      if (!scrollable) return;
      var max = list.scrollWidth - list.clientWidth;
      var i = Math.round((list.scrollLeft / max) * (items.length - 1));
      if (list.scrollLeft >= max - 2) i = items.length - 1;
      i = Math.max(0, Math.min(items.length - 1, i));
      mark(spans, i);
      items.forEach(function (it, k) { it.classList.toggle("is-current", k === i); });
    };
    list.addEventListener("scroll", sync, { passive: true });
    window.addEventListener("resize", sync);
    sync();
  });

  /* ---------- Videos: botón de play propio; los controles nativos aparecen al reproducir ---------- */
  document.querySelectorAll(".video-wrap").forEach(function (wrap) {
    var video = wrap.querySelector("video");
    var btn = wrap.querySelector(".video-play");
    if (!video || !btn) return;
    video.removeAttribute("controls");
    btn.addEventListener("click", function () {
      wrap.classList.add("is-playing");
      video.setAttribute("controls", "");
      var p = video.play();
      if (p && p.catch) p.catch(function () {});
      video.focus();
    });
  });

  /* ---------- Recorrido automático ----------
     Botón flotante que desplaza la página sola, despacio, y vuelve al inicio al llegar al final.
     Se detiene si la persona toca, usa la rueda o el teclado. Con ?auto (o #auto) en la URL
     arranca solo y, tras 25 s sin interacción, se reanuda: pensado para la pantalla del stand. */
  var autoBtn = document.querySelector(".autoscroll");
  if (autoBtn) {
    var params = new URLSearchParams(window.location.search);
    var kiosk = params.has("auto") || window.location.hash === "#auto";
    var speed = Math.max(40, Math.min(90, window.innerHeight / 12)); // px por segundo
    var running = false, rafId = 0, lastT = 0, pos = 0, holdUntil = 0, idleTimer = 0;
    var autoLabel = autoBtn.querySelector(".autoscroll__label");
    var setUi = function () {
      autoBtn.setAttribute("aria-pressed", String(running));
      var txt = running ? "Pausar recorrido" : "Recorrido automático";
      autoLabel.textContent = txt;
      autoBtn.setAttribute("title", txt);
    };
    var step = function (t) {
      if (!running) return;
      if (!lastT) lastT = t;
      var dt = Math.min(0.1, (t - lastT) / 1000);
      lastT = t;
      var max = document.documentElement.scrollHeight - window.innerHeight;
      if (t < holdUntil) { rafId = requestAnimationFrame(step); return; }
      if (pos >= max - 1) {
        // Final: pausa breve y vuelta al inicio.
        if (holdUntil >= 0) { holdUntil = -1; setTimeout(function () {
          if (!running) return;
          window.scrollTo({ top: 0, behavior: "smooth" });
          pos = 0; holdUntil = performance.now() + 3500;
        }, 3500); }
        rafId = requestAnimationFrame(step); return;
      }
      var y = window.scrollY || window.pageYOffset;
      if (Math.abs(y - pos) > 4) pos = y; // la persona movió la barra: seguir desde ahí
      pos = Math.min(max, pos + speed * dt);
      window.scrollTo({ top: pos, behavior: "instant" });
      rafId = requestAnimationFrame(step);
    };
    var start = function () {
      if (running) return;
      running = true; lastT = 0; holdUntil = 0;
      pos = window.scrollY || window.pageYOffset;
      setUi();
      rafId = requestAnimationFrame(step);
    };
    var stop = function () {
      if (!running) return;
      running = false;
      cancelAnimationFrame(rafId);
      setUi();
    };
    var scheduleResume = function () {
      clearTimeout(idleTimer);
      if (kiosk) idleTimer = setTimeout(start, 25000);
    };
    autoBtn.hidden = false;
    autoBtn.addEventListener("click", function () {
      clearTimeout(idleTimer);
      if (running) stop(); else start();
    });
    var userInput = function (e) {
      if (e.target && e.target.closest && e.target.closest(".autoscroll")) return;
      if (running) stop();
      scheduleResume();
    };
    ["wheel", "touchstart", "pointerdown", "keydown"].forEach(function (type) {
      window.addEventListener(type, userInput, { passive: true });
    });
    document.addEventListener("visibilitychange", function () { if (document.hidden) stop(); else scheduleResume(); });
    setUi();
    if (kiosk) setTimeout(start, 2500);
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
