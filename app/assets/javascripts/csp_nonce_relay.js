// CSP uses a fresh random nonce per request. jQuery's own script
// execution paths don't automatically reuse the current page's nonce for
// content that arrives via a separate AJAX response (a different request,
// therefore a different nonce) - without this, any inline <script> in
// AJAX-loaded content (ajax_modal_rails modals, jquery-ujs remote-form .js
// responses) fails CSP. This relays the CURRENT page's nonce (exposed as
// window.CSP_NONCE by an inline script in the layout, sharing this same
// request/nonce) into both jQuery execution paths that need it explicitly.
(function ($) {
  'use strict';

  if (!window.CSP_NONCE) {
    return;
  }

  // Path 1: jquery-ujs's `.js`-format remote-form/link responses (and any
  // dataType: 'script' ajax response) go through jQuery's "text script"
  // converter, which calls jQuery.globalEval(text) with NO options argument
  // at all - unlike the separate `_evalUrl` mechanism used for <script src>
  // sub-resources found during .html() injection, which does thread options
  // through. Patching globalEval itself covers every caller regardless of
  // whether it happens to pass an options object, and still respects an
  // explicit nonce if one is ever provided.
  var originalGlobalEval = $.globalEval;
  $.globalEval = function (code, options, doc) {
    options = options || {};
    if (options.nonce === undefined) {
      options.nonce = window.CSP_NONCE;
    }
    return originalGlobalEval.call(this, code, options, doc);
  };

  // Path 2: $.fn.html() (used by ajax_modal_rails'
  // `content.html(xhr.responseText)`, and any other AJAX-fragment injection)
  // parses the HTML string into real DOM nodes and reads the `nonce`
  // attribute directly off any <script> node found there via domManip's own
  // internal DOMEval call, never through globalEval at all - the patch above
  // doesn't apply here. Rewriting the nonce in the raw string to the current
  // page's value, before jQuery parses/executes it, is the only reliable
  // interception point.
  var originalHtml = $.fn.html;
  $.fn.html = function (value) {
    if (typeof value === 'string' && value.indexOf('nonce=') !== -1) {
      var rewritten = value.replace(/nonce=(["'])[^"']*\1/g, 'nonce="' + window.CSP_NONCE + '"');
      return originalHtml.call(this, rewritten);
    }
    return originalHtml.apply(this, arguments);
  };
})($);
