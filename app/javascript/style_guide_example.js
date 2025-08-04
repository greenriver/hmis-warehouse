// This file is an example of how to use d3.
// It assumes d3 is loaded globally via sprockets.
// this file could use
// import * as d3 from 'd3'
// and add d3 to the package.json,
// except that we currently have d3 loaded via sprockets and don't want to bring two copies of d3 into the bundle.
if (window.d3) {
  const { d3 } = window;
  const div = d3.selectAll('div');
  // console.log(div)
  d3.select('.output').text(`${div.size()} divs found`);
}
