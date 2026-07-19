/* Page behaviour — vanilla JS, no dependencies.
   - scroll-spy table of contents (IntersectionObserver)
   - mobile TOC drawer with backdrop
   - back-to-top button
   - heading-anchor deep links (copy URL on click)
*/
(function () {
  "use strict";

  var toc = document.getElementById("toc");
  var toggle = document.getElementById("toc-toggle");
  var backToTop = document.getElementById("back-to-top");

  /* ---- mobile TOC drawer ---- */
  var backdrop = null;
  function setDrawer(open) {
    if (!toc || !toggle) return;
    toc.classList.toggle("open", open);
    toggle.setAttribute("aria-expanded", String(open));
    toggle.textContent = open ? "×" : "☰";
    if (open && !backdrop) {
      backdrop = document.createElement("div");
      backdrop.className = "toc-backdrop";
      backdrop.addEventListener("click", function () { setDrawer(false); });
      document.body.appendChild(backdrop);
    } else if (!open && backdrop) {
      backdrop.remove();
      backdrop = null;
    }
  }
  if (toggle) {
    toggle.addEventListener("click", function () {
      setDrawer(!(toc && toc.classList.contains("open")));
    });
  }
  if (toc) {
    toc.addEventListener("click", function (event) {
      if (event.target.closest("a")) setDrawer(false);
    });
  }

  /* ---- scroll-spy ---- */
  var links = toc ? Array.prototype.slice.call(toc.querySelectorAll("a[href^='#']")) : [];
  if (links.length && "IntersectionObserver" in window) {
    var byId = {};
    links.forEach(function (a) { byId[a.getAttribute("href").slice(1)] = a; });
    var current = null;
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var link = byId[entry.target.id];
        if (!link || link === current) return;
        if (current) current.classList.remove("active");
        link.classList.add("active");
        current = link;
      });
    }, { rootMargin: "-10% 0px -75% 0px", threshold: 0 });
    Object.keys(byId).forEach(function (id) {
      var el = document.getElementById(id);
      if (el) observer.observe(el);
    });
  }

  /* ---- heading anchor links: click to copy ---- */
  document.addEventListener("click", function (event) {
    var anchor = event.target.closest("a.h-anchor");
    if (!anchor) return;
    event.preventDefault();
    var url = location.href.split("#")[0] + anchor.getAttribute("href");
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url);
      anchor.classList.add("copied");
      setTimeout(function () { anchor.classList.remove("copied"); }, 900);
    }
    history.replaceState(null, "", anchor.getAttribute("href"));
  });

  /* ---- back to top ---- */
  function onScroll() {
    if (!backToTop) return;
    backToTop.classList.toggle("visible", window.scrollY > 600);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  if (backToTop) {
    backToTop.addEventListener("click", function () {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
    onScroll();
  }
})();
