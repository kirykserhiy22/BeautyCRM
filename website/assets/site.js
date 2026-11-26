/* Beauty Base — сайт. Мова (UA/EN), шкала дня й «прильоти» карток під час гортання.
   Без бібліотек і без трекерів. */

(function () {
  "use strict";

  // ---------- Мова ----------

  var EN = {
    "cta.beta": "Join the beta",
    "hero.title": "Everything in its <em>place.</em>",
    "hero.lead": "Appointments, clients with visit history, references and reminders — one app instead of notes, chats and memory.",
    "hero.how": "See how it works",
    "hero.scroll": "Scroll — the day begins",
    "day.title": "One day of a beauty pro.",
    "day.lead": "Scroll and watch everything fall into place.",
    "h1.title": "Open the app — the whole day at a glance.",
    "h1.text": "A day timeline, like the iPhone calendar. Who, when, what and for how much — no scrolling through chats.",
    "h1.c1": "Root colour · Toning",
    "h1.c2": "Haircut · Styling",
    "h2.title": "“What did we do last time?”",
    "h2.text": "The client’s whole visit history: colour formula, planned vs paid. “Book the same” — and just pick a date.",
    "h2.date": "8 October",
    "h2.note": "Colour 6.1 + 30 g lightener, 35 min",
    "h2.repeat": "↻ Book the same",
    "h3.title": "The client sent a reference.",
    "h3.text": "Photos of the desired result go straight into the appointment and live in the client’s profile in their own tab — next to your before/after work.",
    "h3.badge": "References · 3",
    "h3.tabs": "Work · <b style=\"color:#fff\">References</b>",
    "h3.saved": "in profile",
    "h4.title": "Remind about tomorrow — one tap.",
    "h4.text": "A ready text with date, time and address. Pick a tone — warm, neutral or formal — and send via Telegram, Viber, WhatsApp or SMS.",
    "h4.warm": "Warm",
    "h4.neutral": "Neutral",
    "h4.formal": "Formal",
    "h4.msg": "Hi! 😊 Can’t wait to see you tomorrow at 10:00: Root colour. See you! 💕",
    "h4.sent": "Reminder sent",
    "h5.title": "Feeling ill? Postpone two days in a minute.",
    "h5.text": "Pick the dates — appointments join the “Waiting to reschedule” list, the days become days off. Notify clients with a ready reason or your own words.",
    "h5.r1": "Olena · Fri, 10:00",
    "h5.r2": "Maryna · Fri, 12:30",
    "h5.r3": "Yulia · Sat, 11:00",
    "h5.dayoff": "Make these days off",
    "h5.queue": "Waiting to reschedule",
    "h6.title": "How much did I earn today?",
    "h6.text": "Finish an appointment — enter the actual price. Income, average ticket and top services add up by themselves.",
    "h6.week": "This week",
    "close.title": "Day <em>done.</em>",
    "close.text": "No forgotten appointment, no lost formula. Beauty Base is in a private beta — join and help make it even better.",
    "close.s1": "clients",
    "close.s2": "forgotten bookings",
    "close.s3": "per reminder",
    "close.ig": "Instagram",
    "close.soon": "Coming soon to the App Store · iPhone · 5 languages",
    "foot.privacy": "Privacy Policy",
    "foot.terms": "Terms of Use",
    "foot.support": "Support",
    "doc.back": "← Beauty Base"
  };

  var UK = {};
  document.querySelectorAll("[data-i18n]").forEach(function (el) {
    UK[el.getAttribute("data-i18n")] = el.innerHTML;
  });

  function readLang() {
    try {
      var saved = localStorage.getItem("bb-lang");
      if (saved === "uk" || saved === "en") return saved;
    } catch (e) {}
    var nav = (navigator.language || "uk").toLowerCase();
    return nav.indexOf("uk") === 0 || nav.indexOf("ru") === 0 ? "uk" : "en";
  }

  function setLang(lang) {
    document.documentElement.lang = lang;
    var dict = lang === "en" ? EN : UK;
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (dict[key] !== undefined) el.innerHTML = dict[key];
    });
    document.querySelectorAll("[data-set-lang]").forEach(function (b) {
      b.setAttribute("aria-pressed", String(b.getAttribute("data-set-lang") === lang));
    });
    try { localStorage.setItem("bb-lang", lang); } catch (e) {}
  }

  document.querySelectorAll("[data-set-lang]").forEach(function (b) {
    b.addEventListener("click", function () { setLang(b.getAttribute("data-set-lang")); });
  });
  setLang(readLang());

  // ---------- Шапка ----------

  var top = document.getElementById("top");
  var closeSection = document.querySelector(".close");
  var docPage = document.body.classList.contains("doc-page");

  // ---------- День ----------

  var root = document.documentElement;
  var hours = Array.prototype.slice.call(document.querySelectorAll(".hour"));
  var hourLabels = Array.prototype.slice.call(document.querySelectorAll(".rail-hours span"));
  var dayGrid = document.querySelector(".day-grid");

  if ("IntersectionObserver" in window && hours.length) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) e.target.classList.add("in");
      });
    }, { threshold: 0.35, rootMargin: "0px 0px -10% 0px" });
    hours.forEach(function (h) { io.observe(h); });
  } else {
    hours.forEach(function (h) { h.classList.add("in"); });
  }

  var ticking = false;
  function onScroll() {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(function () {
      ticking = false;
      var y = window.scrollY;
      if (top) {
        top.classList.toggle("solid", y > 40 || docPage);
        var light = docPage || (closeSection && closeSection.getBoundingClientRect().top < 60);
        top.classList.toggle("light", !!light);
      }
      if (dayGrid) {
        var r = dayGrid.getBoundingClientRect();
        var vh = window.innerHeight;
        var p = (vh * 0.5 - r.top) / Math.max(1, r.height - vh * 0.3);
        p = Math.min(1, Math.max(0, p));
        root.style.setProperty("--day", p.toFixed(4));
        var passed = Math.round(p * (hourLabels.length - 1));
        hourLabels.forEach(function (s, i) { s.classList.toggle("passed", i <= passed); });
      }
    });
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onScroll);
  onScroll();
})();
