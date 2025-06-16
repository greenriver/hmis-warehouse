// entry new point
console.debug('esbuild included')

import * as bootstrap from "bootstrap"
import * as Popper from "@popperjs/core"

// Import and register all your Stimulus controllers
import "./controllers"

// Make both Bootstrap and Popper globally available for legacy scripts.
window.bootstrap = bootstrap
window.Popper = Popper
