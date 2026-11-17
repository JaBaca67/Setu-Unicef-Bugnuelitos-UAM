/* SéTú · Landing page
   Tokens tomados del Manual de Identidad Gráfica (paleta y tipografías).
   Clayful se usa solo como trazos SVG en los titulares (licencia de uso personal). */

@font-face { font-family: "Poppins"; font-weight: 400; font-style: normal; font-display: swap; src: url("../assets/fonts/poppins-regular.woff2") format("woff2"); }
@font-face { font-family: "Poppins"; font-weight: 500; font-style: normal; font-display: swap; src: url("../assets/fonts/poppins-medium.woff2") format("woff2"); }
@font-face { font-family: "Poppins"; font-weight: 600; font-style: normal; font-display: swap; src: url("../assets/fonts/poppins-semibold.woff2") format("woff2"); }
@font-face { font-family: "Poppins"; font-weight: 700; font-style: normal; font-display: swap; src: url("../assets/fonts/poppins-bold.woff2") format("woff2"); }

:root {
  /* Paleta oficial */
  --setu-blue: #0C62EB;
  --setu-magenta: #FF0092;
  --setu-yellow: #FFE000;
  --setu-green: #00C642;
  --setu-white: #FFFFFF;
  --setu-black: #000000;

  --font: "Poppins", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;

  /* Escala tipográfica (razón ~1.25) */
  --fs-sm: 0.875rem;
  --fs-base: 1rem;
  --fs-md: 1.125rem;
  --fs-lg: 1.375rem;
  --fs-xl: clamp(1.75rem, 1.2rem + 2.4vw, 2.75rem);
  --fs-hero: clamp(2rem, 1.2rem + 3.6vw, 3.6rem);

  --space-1: 0.5rem;
  --space-2: 1rem;
  --space-3: 1.5rem;
  --space-4: 2.5rem;
  --space-5: 4rem;
  --space-6: 6rem;

  --radius-sm: 10px;
  --radius-md: 18px;
  --radius-lg: 28px;
  --radius-pill: 999px;

  --pattern: url("../assets/brand/patron-ondas.svg");
  --nav-h: 68px;
}

*, *::before, *::after { box-sizing: border-box; }

html {
  overflow-x: clip;
  scroll-behavior: smooth;
  scroll-padding-top: calc(var(--nav-h) + env(safe-area-inset-top, 0px));
  -webkit-text-size-adjust: 100%;
}

body {
  overflow-x: clip;
  margin: 0;
  font-family: var(--font);
  font-size: var(--fs-base);
  line-height: 1.6;
  color: var(--setu-black);
  background: var(--setu-white);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}

img { max-width: 100%; height: auto; display: block; }
a { color: inherit; }
h1, h2, h3 { margin: 0; line-height: 1.15; font-weight: 700; }
p { margin: 0; }

:focus-visible {
  outline: 3px solid var(--setu-magenta);
  outline-offset: 3px;
  border-radius: 6px;
}

.visually-hidden {
  position: absolute !important;
  width: 1px; height: 1px; overflow: hidden;
  clip: rect(0 0 0 0); white-space: nowrap;
}

.skip {
  position: absolute; left: 1rem; top: -100px; z-index: 100;
  background: var(--setu-yellow); color: var(--setu-black);
  padding: 0.75rem 1rem; border-radius: var(--radius-sm); font-weight: 600;
}
.skip:focus { top: 1rem; }

.wrap { width: min(1160px, 100% - 2.5rem); margin-inline: auto; }
.wrap--narrow { width: min(760px, 100% - 2.5rem); }

.h2 { font-size: var(--fs-xl); letter-spacing: -0.01em; color: var(--setu-blue); }
.h2--light { color: var(--setu-white); }
.lead { font-size: var(--fs-md); max-width: 62ch; margin-top: var(--space-2); }

/* Cintillo con titular Clayful: tratamiento propio de las artes de campaña */
.tape {
  display: inline-flex;
  align-items: center;
  padding: 0.28em 0.38em 0.22em;
  margin-top: 0.12em;
  line-height: 0;
  color: var(--setu-white);
  transform: rotate(-1.2deg);
}
.tape { max-width: 100%; }
.tape svg { height: 1em; width: auto; max-width: 100%; overflow: visible; }
.h2 .tape { font-size: 1.3em; }
.tape--magenta { background: var(--setu-magenta); }
.tape--yellow { background: var(--setu-yellow); }
.tape--blue-ink { color: var(--setu-blue); }

/* Botones */
.btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem;
  min-height: 46px; padding: 0.7rem 1.25rem;
  border-radius: var(--radius-pill);
  font: 600 var(--fs-base)/1.2 var(--font);
  text-decoration: none; border: 2px solid transparent; cursor: pointer;
  transition: transform 0.15s ease;
}
.btn:active { transform: translateY(1px) scale(0.98); }
.btn--primary { background: var(--setu-blue); color: var(--setu-white); }
.btn--ghost { background: transparent; color: var(--setu-blue); border-color: var(--setu-blue); }
.btn--yellow { background: var(--setu-yellow); color: var(--setu-black); }
.btn--lg { min-height: 56px; padding: 0.9rem 1.6rem; font-size: var(--fs-md); }
.btn--sm { min-height: 40px; padding: 0.5rem 0.9rem; font-size: var(--fs-sm); }

/* ---------- NAV ---------- */
.nav {
  position: sticky; top: 0; z-index: 50;
  background: var(--setu-white);
  padding-top: env(safe-area-inset-top, 0px);
  border-bottom: 3px solid var(--setu-blue);
}
.nav__inner {
  width: min(1160px, 100% - 2.5rem); margin-inline: auto;
  height: var(--nav-h);
  display: flex; align-items: center; justify-content: space-between; gap: 1rem;
}
/* Zona de seguridad del logotipo: margen libre alrededor del identificador */
.nav__brand { display: block; padding: 6px; margin-left: -6px; }
.nav__brand img { height: 34px; width: auto; }

.nav__toggle {
  display: inline-grid; place-items: center;
  width: 46px; height: 46px; border-radius: var(--radius-sm);
  background: var(--setu-blue); border: 0; cursor: pointer;
}
.nav__toggle-bars, .nav__toggle-bars::before, .nav__toggle-bars::after {
  display: block; width: 20px; height: 2.5px; border-radius: 2px;
  background: var(--setu-white); position: relative; content: "";
  transition: transform 0.2s ease;
}
.nav__toggle-bars::before { position: absolute; top: -6px; }
.nav__toggle-bars::after { position: absolute; top: 6px; }
.nav__toggle[aria-expanded="true"] .nav__toggle-bars { background: transparent; }
.nav__toggle[aria-expanded="true"] .nav__toggle-bars::before { transform: translateY(6px) rotate(45deg); }
.nav__toggle[aria-expanded="true"] .nav__toggle-bars::after { transform: translateY(-6px) rotate(-45deg); }

.nav__menu {
  position: absolute; left: 0; right: 0; top: 100%;
  display: none; flex-direction: column; gap: 0.25rem;
  padding: 1rem 1.25rem 1.5rem;
  background: var(--setu-white);
  border-bottom: 3px solid var(--setu-blue);
}
.nav__menu.is-open { display: flex; }
.nav__menu > a:not(.btn) {
  padding: 0.75rem 0.25rem; font-weight: 500; text-decoration: none;
}
.nav__menu .btn { margin-top: 0.5rem; }

@media (min-width: 980px) {
  .nav__toggle { display: none; }
  .nav__menu {
    position: static; display: flex; flex-direction: row; align-items: center;
    gap: 0.4rem; padding: 0; border: 0; background: none;
  }
  .nav__menu > a:not(.btn) { padding: 0.5rem 0.7rem; font-size: var(--fs-sm); }
  .nav__menu > a:not(.btn):hover { color: var(--setu-blue); text-decoration: underline; text-underline-offset: 6px; text-decoration-thickness: 2px; }
  .nav__menu .btn { margin: 0 0 0 0.3rem; min-height: 42px; font-size: var(--fs-sm); }
}

/* ---------- HERO ---------- */
.hero {
  background: var(--setu-blue) var(--pattern) repeat;
  color: var(--setu-white);
  overflow: hidden;
}
.hero__inner {
  width: min(1160px, 100% - 2.5rem); margin-inline: auto;
  display: grid; grid-template-columns: minmax(0, 1fr); gap: var(--space-4);
  padding: var(--space-4) 0 var(--space-5);
}
.hero__title { font-size: var(--fs-hero); letter-spacing: -0.015em; }
.hero__line { display: block; }
.hero__title .tape { font-size: min(1.32em, 15vw); margin-top: 0.18em; }
.hero__lead { font-size: var(--fs-md); max-width: 46ch; margin-top: var(--space-3); }
.hero__actions { margin-top: var(--space-4); scroll-margin-top: calc(var(--nav-h) + 1rem); }
.hero__note { font-size: var(--fs-sm); margin-top: 0.75rem; max-width: 42ch; }

.hero__demo { position: relative; justify-self: center; width: min(330px, 100% - 2rem); }
.deco { position: absolute; pointer-events: none; }
.deco--flor { width: 150px; right: -70px; top: -30px; }
.deco--espiral { width: 90px; left: -46px; bottom: 90px; }
.deco--personaje { width: 74px; right: -18px; bottom: -26px; }

@media (min-width: 900px) {
  .hero__inner {
    grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr); align-items: center;
    padding: var(--space-5) 0 var(--space-6);
  }
}

/* Teléfono de demostración */
.phone {
  position: relative; z-index: 1;
  background: var(--setu-black);
  border-radius: 40px; padding: 12px;
}
.phone__notch {
  position: absolute; top: 12px; left: 50%; transform: translateX(-50%);
  width: 92px; height: 22px; border-radius: 0 0 14px 14px; background: var(--setu-black); z-index: 2;
}
.phone__screen {
  background: var(--setu-white); color: var(--setu-black);
  border-radius: 30px; padding: 34px 16px 16px;
  min-height: 470px; display: flex; flex-direction: column; gap: 14px;
}
.phone__top { display: flex; align-items: center; justify-content: space-between; }

.status {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 0.78rem; font-weight: 600;
  padding: 4px 10px; border-radius: var(--radius-pill);
  background: var(--setu-blue); color: var(--setu-white);
}
.status__dot { width: 8px; height: 8px; border-radius: 50%; background: var(--setu-green); }
.status.is-mesh { background: var(--setu-yellow); color: var(--setu-black); }
.status.is-mesh .status__dot { background: var(--setu-magenta); }

.code label { display: block; font-weight: 600; font-size: var(--fs-sm); color: var(--setu-blue); }
.code__row { display: flex; gap: 8px; margin-top: 6px; }
.code input {
  flex: 1; min-width: 0;
  font: 600 1.05rem/1 var(--font); letter-spacing: 0.12em; text-transform: uppercase;
  padding: 0.55rem 0.75rem; border: 2px solid var(--setu-blue); border-radius: var(--radius-sm);
  color: var(--setu-black); background: var(--setu-white);
}
.code__hint { font-size: 0.75rem; margin-top: 6px; }

.alert {
  border: 2px solid var(--setu-blue); border-radius: var(--radius-md);
  padding: 12px; flex: 1;
}
.alert__title { font-size: 0.82rem; }
.route { list-style: none; margin: 12px 0 0; padding: 0; display: grid; gap: 4px; }
.route li {
  display: flex; align-items: center; gap: 10px;
  font-size: 0.82rem; font-weight: 500;
  padding: 6px 8px; border-radius: var(--radius-sm);
  opacity: 0.35; transition: opacity 0.3s ease, background-color 0.3s ease;
}
.route li .hop {
  flex: none; display: grid; place-items: center;
  width: 26px; height: 26px; border-radius: 50%;
  background: var(--setu-blue); color: var(--setu-white);
  font-size: 0.72rem; font-weight: 700;
}
.route li.is-done { opacity: 1; }
.route li.is-current { opacity: 1; background: var(--setu-yellow); }
.route li.is-current .hop { background: var(--setu-magenta); }
.alert__state { margin-top: 10px; font-size: 0.8rem; font-weight: 600; color: var(--setu-blue); min-height: 1.3em; }
.alert__state.is-ok { color: var(--setu-black); }
.alert__state.is-ok::before { content: ""; display: inline-block; width: 10px; height: 10px; border-radius: 50%; background: var(--setu-green); margin-right: 6px; }

.switch {
  margin-top: auto;
  display: grid; grid-template-columns: 1fr 1fr;
  background: var(--setu-blue); border-radius: var(--radius-pill); padding: 4px;
}
.switch button {
  font: 600 0.82rem/1 var(--font); border: 0; cursor: pointer;
  padding: 0.65rem 0.5rem; border-radius: var(--radius-pill);
  background: transparent; color: var(--setu-white);
}
.switch button[aria-checked="true"] { background: var(--setu-white); color: var(--setu-blue); }

/* ---------- COMPARE ---------- */
.compare { padding: var(--space-5) 0; }
.compare__grid { display: grid; grid-template-columns: minmax(0, 1fr); gap: var(--space-3); margin-top: var(--space-4); }
.compare__col { border-radius: var(--radius-lg); padding: var(--space-3); }
.compare__col h3 { font-size: var(--fs-lg); margin-bottom: var(--space-2); }
.compare__col--before { border: 3px dashed var(--setu-black); }
.compare__col--after { background: var(--setu-blue); color: var(--setu-white); position: relative; }
.compare__col--after::after {
  content: ""; position: absolute; width: 74px; height: 74px; right: -14px; top: -26px;
  background: url("../assets/elements/elemento-04-pieza-verde.svg") center/contain no-repeat;
  transform: rotate(14deg);
}
.checks { list-style: none; margin: 0; padding: 0; display: grid; gap: 1rem; }
.checks li { position: relative; padding-left: 2.1rem; }
.checks li::before {
  position: absolute; left: 0; top: 0.1em;
  width: 1.45rem; height: 1.45rem; border-radius: 50%;
  display: grid; place-items: center; font-weight: 700; font-size: 0.85rem; line-height: 1;
}
.checks--no li::before { content: "✕"; border: 2px solid var(--setu-black); }
.checks--yes li::before { content: "✓"; background: var(--setu-green); color: var(--setu-white); }
.checks strong { font-weight: 600; }

@media (min-width: 800px) {
  .compare__grid { grid-template-columns: 1fr 1fr; align-items: start; }
  .compare__col { padding: var(--space-4); }
}

/* ---------- STEPS ---------- */
.steps { background: var(--setu-yellow); padding: var(--space-5) 0; }
.steps__list {
  list-style: none; margin: var(--space-4) 0 0; padding: 0;
  display: grid; gap: var(--space-3);
}
.step {
  position: relative; background: var(--setu-white);
  border-radius: var(--radius-lg); padding: var(--space-4) var(--space-3) var(--space-3);
}
.step h3 { font-size: var(--fs-lg); margin-bottom: 0.6rem; }
.step__num {
  position: absolute; top: -22px; left: var(--space-3);
  width: 52px; height: 52px; display: grid; place-items: center;
  font-size: 1.5rem; font-weight: 700; color: var(--setu-white);
  border-radius: 14px;
}
.step--blue .step__num { background: var(--setu-blue); }
.step--magenta .step__num { background: var(--setu-magenta); }
.step--green .step__num { background: var(--setu-green); }
.step--blue h3 { color: var(--setu-blue); }
.step--magenta h3 { color: var(--setu-magenta); }
.step--green h3 { color: var(--setu-black); }

@media (min-width: 900px) {
  .steps__list { grid-template-columns: repeat(3, 1fr); gap: var(--space-3); margin-top: var(--space-5); }
  .step:nth-child(2) { transform: translateY(28px); }
  .step:nth-child(3) { transform: translateY(56px); }
  .steps { padding-bottom: calc(var(--space-5) + 56px); }
}

/* ---------- PILLARS ---------- */
.pillars { background: var(--setu-blue) var(--pattern) repeat; color: var(--setu-white); padding: var(--space-5) 0; }
.pillars__grid { display: grid; gap: var(--space-3); margin-top: var(--space-4); }
.pillar { padding: var(--space-3); border-radius: var(--radius-lg); border: 2px solid var(--setu-white); }
.pillar h3 { font-size: var(--fs-lg); margin: 1rem 0 0.5rem; }
.pillar__icon { width: 76px; height: 76px; margin: -10px 0 0 -10px; }
.mesh-map { display: block; width: 100%; height: auto; margin-top: var(--space-3); }
.pillar--mesh { background: var(--setu-white); color: var(--setu-black); border-color: var(--setu-white); }
.pillar--mesh h3 { color: var(--setu-blue); }
.pillar__clay { display: block; color: var(--setu-magenta); line-height: 0; }
.pillar__clay svg { height: 2.6rem; width: auto; max-width: 100%; }

@media (min-width: 900px) {
  .pillars__grid { grid-template-columns: 1fr 1.25fr 1fr; align-items: stretch; }
  .pillar { padding: var(--space-4) var(--space-3); }
  .pillar--mesh { transform: translateY(-18px); }
}

/* ---------- CAMPAIGN ---------- */
.campaign { padding: var(--space-5) 0; overflow: hidden; }
.campaign__strip {
  list-style: none; margin: var(--space-4) 0 0; padding: 0 1.25rem 1rem;
  display: flex; gap: 1rem; overflow-x: auto; scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
}
.campaign__strip li { flex: 0 0 min(76%, 340px); scroll-snap-align: center; }
.campaign__strip img { border-radius: var(--radius-md); width: 100%; }
.campaign__strip li:nth-child(1) { transform: rotate(-1.5deg); }
.campaign__strip li:nth-child(3) { transform: rotate(1.5deg); }

@media (min-width: 1000px) {
  .campaign__strip { justify-content: center; overflow: visible; padding-inline: 0; }
  .campaign__strip li { flex-basis: 330px; }
  .campaign__strip li:nth-child(2) { transform: translateY(-20px); }
}

/* ---------- INSTITUCIONES ---------- */
.inst { padding: var(--space-5) 0; background: var(--setu-white); border-top: 3px solid var(--setu-blue); }
.inst__grid { display: grid; gap: var(--space-2); margin-top: var(--space-4); }
.role { padding: var(--space-3); border-left: 6px solid var(--setu-blue); }
.role h3 { font-size: var(--fs-lg); color: var(--setu-blue); margin-bottom: 0.5rem; }
.role--accent { border-left-color: var(--setu-magenta); }
.role--accent h3 { color: var(--setu-magenta); }

.kit {
  margin-top: var(--space-4);
  display: grid; gap: var(--space-3); align-items: center;
  background: var(--setu-yellow); border-radius: var(--radius-lg); padding: var(--space-3);
}
.kit h3 { font-size: var(--fs-lg); }
.kit p { margin: 0.5rem 0 var(--space-3); max-width: 58ch; }
.kit__art { width: 150px; justify-self: center; }

@media (min-width: 860px) {
  .inst__grid { grid-template-columns: repeat(3, 1fr); }
  .kit { grid-template-columns: 200px 1fr; padding: var(--space-4); }
  .kit__art { width: 170px; }
}

/* ---------- FAQ ---------- */
.faq { padding: var(--space-5) 0; background: var(--setu-white); }
.faq__list { max-width: 820px; margin-top: var(--space-3); display: grid; gap: 0.75rem; }
.faq details { border: 2px solid var(--setu-blue); border-radius: var(--radius-md); background: var(--setu-white); }
.faq details[open] { border-color: var(--setu-magenta); }
.faq summary {
  list-style: none; cursor: pointer;
  display: flex; justify-content: space-between; align-items: center; gap: 1rem;
  padding: 1rem 1.15rem; font-weight: 600; font-size: var(--fs-md);
}
.faq summary::-webkit-details-marker { display: none; }
.faq summary::after {
  content: "+"; flex: none;
  width: 32px; height: 32px; border-radius: 50%;
  display: grid; place-items: center;
  background: var(--setu-blue); color: var(--setu-white); font-size: 1.3rem; line-height: 1;
  transition: transform 0.2s ease;
}
.faq details[open] summary::after { content: "−"; background: var(--setu-magenta); }
.faq details p { padding: 0 1.15rem 1.15rem; max-width: 66ch; }

/* ---------- SOS ---------- */
.sos { background: var(--setu-magenta); color: var(--setu-white); padding: var(--space-4) 0; }
.sos__inner { display: grid; gap: 0.5rem; }
.sos h2 { font-size: var(--fs-lg); }
.sos a { font-weight: 700; color: var(--setu-white); text-decoration-thickness: 2px; text-underline-offset: 3px; }
@media (min-width: 860px) { .sos__inner { grid-template-columns: auto 1fr; gap: var(--space-4); align-items: center; } }

/* ---------- FOOTER ---------- */
.footer { background: var(--setu-blue); color: var(--setu-white); padding: var(--space-5) 0 var(--space-3); }
.footer__inner { display: grid; gap: var(--space-4); }
.footer h2 { font-size: var(--fs-md); margin-bottom: 0.75rem; }
.footer__logos { display: flex; align-items: center; flex-wrap: wrap; gap: 1.75rem; margin-bottom: var(--space-3); }
.footer__logos img:first-child { height: 76px; width: auto; }
.footer__logos img:nth-child(2) { height: 32px; width: auto; }
.footer__mined { font-weight: 700; font-size: 1.4rem; letter-spacing: 0.02em; }
.footer__brand p { max-width: 48ch; font-size: var(--fs-sm); }
.footer__links { display: grid; gap: 0.35rem; align-content: start; }
.footer__links a { text-decoration: none; padding: 0.2rem 0; }
.footer__links a:hover { text-decoration: underline; }
.footer__team ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 0.25rem; font-size: var(--fs-sm); }
.footer__legal { margin-top: var(--space-4); padding-top: var(--space-3); border-top: 2px solid var(--setu-white); font-size: var(--fs-sm); }

@media (min-width: 900px) {
  .footer__inner { grid-template-columns: 1.5fr 1fr 1fr; }
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { transition: none !important; animation: none !important; }
}
