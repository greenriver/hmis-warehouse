// entry new point
console.debug('esbuild included')

import * as bootstrap from "bootstrap"
import * as Popper from "@popperjs/core"

// Make both Bootstrap and Popper globally available for legacy scripts.
window.bootstrap = bootstrap
window.Popper = Popper
