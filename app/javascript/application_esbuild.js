// Import Sentry for error tracking
import Sentry from './sentry';
// Uncomment the next line to expose Sentry to the window for manual error reporting and debugging in the browser console.
// window.Sentry = Sentry;

// Always include the following
import * as bootstrap from "bootstrap"
import * as Popper from "@popperjs/core"

function initializeControllers() {
  // Dynamically import and register all your Stimulus controllers
  import("./controllers")
}

function waitForJQuery() {
  if (window.jQuery && window.$) {
    initializeControllers();
  } else {
    // Poll for jQuery to be loaded by Sprockets.
    setTimeout(waitForJQuery, 50);
  }
}

// Make both Bootstrap and Popper globally available for legacy scripts.
window.bootstrap = bootstrap
window.Popper = Popper

waitForJQuery();
