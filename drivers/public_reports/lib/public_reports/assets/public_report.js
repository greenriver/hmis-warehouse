(function () {
  "use strict";

  // Embedding pages size the iframe from this message; see
  // StateDashboard#generate_embed_code_for for the listener.
  if (window.parent !== window) {
    var postHeight = function () {
      // The <html> box, unlike scrollHeight, can shrink below the iframe's current height.
      var height = Math.ceil(document.documentElement.getBoundingClientRect().height);
      window.parent.postMessage({ type: "public-report-height", height: height }, "*");
    };
    window.addEventListener("load", postHeight);
    if (window.ResizeObserver) new ResizeObserver(postHeight).observe(document.documentElement);
  }

  // Not every browser opens a closed <details> when a link targets something inside it.
  function openDetailsFor(hash) {
    var target = hash && document.getElementById(hash.slice(1));
    var details = target && target.closest("details");
    if (details) details.open = true;
  }
  window.addEventListener("hashchange", function () { openDetailsFor(window.location.hash); });
  document.addEventListener("click", function (event) {
    var link = event.target.closest('a[href^="#"]');
    if (link) openDetailsFor(link.hash);
  });
  openDetailsFor(window.location.hash);

  // WCAG 1.4.13: Escape hides hover/focus tooltips without moving the pointer or focus.
  var root = document.documentElement;
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") root.classList.add("tooltips-dismissed");
  });
  ["focusin", "pointerout"].forEach(function (type) {
    document.addEventListener(type, function () { root.classList.remove("tooltips-dismissed"); });
  });
})();
