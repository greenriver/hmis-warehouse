#!/usr/bin/env node

const esbuild = require("esbuild");
const expand = require('glob-expand')
let entrypoints = expand("app/javascript/**/*.js")
function watch() {
  esbuild.build({
    logLevel: "info",
    entryPoints: entrypoints,
    outdir: "app/assets/builds",
    bundle: true,
  });
}
setInterval(watch, 15000)
