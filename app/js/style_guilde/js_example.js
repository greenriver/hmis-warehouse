import * as d3 from 'd3'

const div = d3.selectAll('div')
// console.log(div)
d3.select('.output')
  .text(`${div.size()} divs found`)
console.log('test12')
// WATCH with:
// ./node_modules/.bin/esbuild app/js/**/*.js --bundle --outdir=app/assets/builds --watch
