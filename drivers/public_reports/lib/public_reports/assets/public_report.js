(function () {
  "use strict";

  // Embedding pages size the iframe from this message; see
  // StateLevelHomelessness#generate_embed_code_for for the listener.
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
  function openTargetDetails() {
    var target = window.location.hash && document.getElementById(window.location.hash.slice(1));
    var details = target && target.closest("details");
    if (details) details.open = true;
  }
  window.addEventListener("hashchange", openTargetDetails);
  openTargetDetails();
})();
