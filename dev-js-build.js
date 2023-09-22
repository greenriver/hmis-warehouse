#!/usr/bin/env node

// NOTE: this is a hack to get around yarn build --watch not working
// at the moment, we simply rebuild the JS every 15 seconds, not ideal
const esbuild = require("esbuild");
const expand = require('glob-expand')
const entrypoints = expand("app/javascript/**/*.js")
function watch() {
  esbuild.build({
    logLevel: "info",
    entryPoints: entrypoints,
    outdir: "app/assets/builds",
    bundle: true,
  });
}
setInterval(watch, 15000)
