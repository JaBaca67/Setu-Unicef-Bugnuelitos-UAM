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

  /* ---------- Demo: recorrido de una alerta ---------- */
  var form = document.querySelector("[data-code-form]");
  var alertBox = document.querySelector("[data-alert]");
  var route = document.querySelector("[data-route]");
  var stateEl = document.querySelector("[data-state]");
  var status = document.querySelector("[data-status]");
  var statusText = document.querySelector("[data-status-text]");
  var modeButtons = document.querySelectorAll("[data-mode]");
  if (!form || !alertBox || !route) return;

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  var ROUTES = {
    online: {
      label: "Con internet",
      hops: ["Tu celular", "Servidor de SéTú", "MINED y dirección del colegio"],
      states: ["Pendiente de envío", "Enviada al sistema", "Recibida por el MINED y tu colegio"]
    },
    mesh: {
      label: "Sin internet (red mesh)",
      hops: ["Tu celular", "Celular de un compañero", "Celular puente", "Dirección del colegio"],
      states: ["Guardada cifrada en tu celular", "Saltando por Bluetooth", "Llegó al celular puente", "Llegó a tu colegio. Se sincroniza con el MINED al volver internet"]
    }
  };

  var mode = "online";
  var timers = [];
  var entered = false;

  function clearTimers() {
    timers.forEach(clearTimeout);
    timers = [];
  }

  function renderRoute() {
    var r = ROUTES[mode];
    route.innerHTML = "";
    r.hops.forEach(function (hop, i) {
      var li = document.createElement("li");
      var num = document.createElement("span");
      num.className = "hop";
      num.setAttribute("aria-hidden", "true");
      num.textContent = String(i + 1);
      li.appendChild(num);
      li.appendChild(document.createTextNode(hop));
      route.appendChild(li);
    });
  }

  function play() {
    clearTimers();
    renderRoute();
    var r = ROUTES[mode];
    var items = route.querySelectorAll("li");
    var step = function (i) {
      items.forEach(function (li, j) {
        li.classList.toggle("is-done", j < i);
        li.classList.toggle("is-current", j === i);
      });
      stateEl.textContent = r.states[i];
      stateEl.classList.toggle("is-ok", i === items.length - 1);
      if (i === items.length - 1) {
        items[i].classList.remove("is-current");
        items[i].classList.add("is-done");
      }
    };
    if (reduceMotion) {
      step(items.length - 1);
      return;
    }
    items.forEach(function (_, i) {
      timers.push(setTimeout(function () { step(i); }, 200 + i * 900));
    });
  }

  function setMode(next) {
    mode = next;
    modeButtons.forEach(function (b) {
      b.setAttribute("aria-checked", String(b.getAttribute("data-mode") === mode));
    });
    status.classList.toggle("is-mesh", mode === "mesh");
    statusText.textContent = ROUTES[mode].label;
    if (entered) play();
  }

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var input = form.querySelector("input");
    input.value = input.value.trim().toUpperCase() || "AULA24";
    entered = true;
    alertBox.hidden = false;
    play();
  });

  modeButtons.forEach(function (b) {
    b.addEventListener("click", function () { setMode(b.getAttribute("data-mode")); });
    b.addEventListener("keydown", function (e) {
      if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
        e.preventDefault();
        var other = b.getAttribute("data-mode") === "online" ? "mesh" : "online";
        setMode(other);
        document.querySelector('[data-mode="' + other + '"]').focus();
      }
    });
  });
})();
