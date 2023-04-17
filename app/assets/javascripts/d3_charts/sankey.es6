//= require ./namespace

// Copyright 2021 Observable, Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/sankey-diagram
App.D3Chart.Sankey = class Sankey {

 constructor(
    chart_selector,
    {
      nodeGroup,
      targetColors,
      nodeWeights,
      width,
      height,
      detail_path,
    },
  ) {
    //this._build_chart = this._build_chart.bind(this);
    this.d3Sankey = d3;
    this.chart_selector = chart_selector;
    this.nodeGroup = nodeGroup;
    this.targetColors = targetColors;
    this.nodeWeights = nodeWeights;
    this.width = width;
    this.height = height;
    this.detail_path = detail_path;
    this.wrapper = this.d3Sankey.select(chart_selector);
    this.sankey = this.d3Sankey.sankey();
  }

  prepare() {
    const width = this.width;
    const height = this.height;
    this.chart = d3.create('svg')
      .attr('viewBox', `0 0 ${width} ${height}`)
      .attr('viewBox', [0, 0, width, height])
      .attr('style', 'max-width: 100%; height: auto; height: intrinsic;');
    this.Tooltip = this.wrapper
      .append('div')
      .style('opacity', 0)
      .attr('class', 'tooltip')
      .style('background-color', 'white')
      .style('box-shadow', '5px 5px 10px 1px #ABABAB');
  }

  draw(links) {
    let nodeId = d => d.id; // given d in nodes, returns a unique identifier (string)
    let nodeGroup = d => d.id; //.split(/\W/)[0]; // take first word for color
    // let nodeTitle = d => `${d.id}\n${format(d.value)}`; // given d in (computed) nodes, hover text
    let nodeWidth = 25; // width of node rects
    let nodePadding = 40; // vertical separation between adjacent nodes
    let nodeLabelPadding = 0; // horizontal separation between node and label
    let nodeStroke = 'currentColor'; // stroke around node rects
    let nodeStrokeWidth = 0; // width of stroke around node rects, in pixels
    let linkSource = ({ source }) => source; // given d in links, returns a node identifier string
    let linkTarget = ({ target }) => target; // given d in links, returns a node identifier string
    let linkValue = ({ value }) => value; // given d in links, returns the quantitative value
    let targetColors = {};
    let linkPath = this.d3Sankey.sankeyLinkHorizontal(); // given d in (computed) links, returns the SVG path
    // let linkTitle = d => `${d.source.id} → ${d.target.id}\n${format(d.value)}`; // given d in (computed) links
    let linkColor = 'source-target'; // source, target, source-target, or static color
    let linkStrokeOpacity = 0.5; // link stroke opacity
    let linkMixBlendMode = 'multiply'; // link blending mode
    let colors = d3.schemeTableau10; // array of colors
    let width = this.width;
    let height = this.height;
    let marginTop = 5; // top margin, in pixels
    let marginRight = 1; // right margin, in pixels
    let marginBottom = 5; // bottom margin, in pixels
    let marginLeft = 1; // left margin, in pixels

    let d3Sankey = this.d3Sankey;
    // Convert nodeAlign from a name to a function (since d3-sankey is not part of core d3).
    let nodeAlign = d3Sankey.sankeyLeft;
    // let nodeAlign = {
    //   left: d3Sankey.sankeyLeft,
    //   right: d3Sankey.sankeyRight,
    //   center: d3Sankey.sankeyCenter
    // }[align] || d3Sankey.sankeyJustify;

    // Compute values.
    const LS = d3.map(links, linkSource).map(this.intern);
    const LT = d3.map(links, linkTarget).map(this.intern);
    const LV = d3.map(links, linkValue);
    let nodes = Array.from(d3.union(LS, LT), id => ({ id }));
    const N = d3.map(nodes, nodeId).map(this.intern);
    const G = d3.map(nodes, nodeGroup).map(this.intern);

    // Replace the input nodes and links with mutable objects for the simulation.
    nodes = d3.map(nodes, (_, i) => ({ id: N[i] }));
    links = d3.map(links, (_, i) => ({ source: LS[i], target: LT[i], value: LV[i] }));

    // Ignore a group-based linkColor option if no groups are specified.
    if (!G && ['source', 'target', 'source-target'].includes(linkColor)) linkColor = 'currentColor';

    // Compute default domains.
    let nodeGroups = G;

    // Construct the scales.
    this.color = d3.scaleOrdinal(nodeGroups, colors);

    // Compute the Sankey layout.
    this.sankey
      .nodeId(({ index: i }) => N[i])
      .nodeAlign(nodeAlign)
      .nodeWidth(nodeWidth)
      .nodePadding(nodePadding)
      .nodeSort((a, b) => this.node_sorter(a, b))
      .extent([[marginLeft, marginTop], [width - marginRight, height - marginBottom]])
    this.sankey({ nodes, links });

    // Compute titles and labels using layout nodes, so as to access aggregate values.
    // if (typeof format !== 'function') format = d3.format(format);
    const Tl = N;
    // const Tt = nodeTitle == null ? null : d3.map(nodes, nodeTitle);
    // const Lt = linkTitle == null ? null : d3.map(links, linkTitle);

    // A unique identifier for clip paths (to avoid conflicts).
    const uid = `O-${Math.random().toString(16).slice(2)}`;

    const svg = this.chart;

    const node = svg.append('g')
      .attr('stroke', nodeStroke)
      .attr('stroke-width', nodeStrokeWidth)
      .selectAll('rect')
      .data(nodes)
      .join('rect')
      .attr('x', d => d.x0)
      .attr('y', d => {
        d = this.tranlate_location(d)
        return d.y0
      })
      .attr('height', d => d.y1 - d.y0)
      .attr('width', d => d.x1 - d.x0);

    if (G) node.attr('fill', ({ index: i }) => this.color_for_target(G[i]))
    //if (Tt) node.append('title').text(({ index: i }) => Tt[i]);
    node
      .on('mouseover', (d, i) => {
        this.over(d, i, 'node')
      })
      .on('mouseout', (d, i) => {
        this.out(d, i, 'node')
      })
      .on('mousemove', (d, i) => {
        this.move(d, i, 'node')
      })
      .on('click', (e, d) => {
        let url = new URL(this.detail_path);
        url.searchParams.append('node', d.id);
        window.open(url.toString(), '_blank')
      })

    let return_link = links.find(link => link.target.id == 'Returns to Homelessness')
    if (return_link) {
      return_link.y1 = height - 50
    }

    const link = svg.append('g')
      .attr('fill', 'none')
      .attr('stroke-opacity', linkStrokeOpacity)
      .selectAll('g')
      .data(links)
      .join('g')
      .style('mix-blend-mode', linkMixBlendMode);
    if (linkColor === 'source-target') link.append('linearGradient')
      .attr('id', d => `${uid}-link-${d.index}`)
      .attr('gradientUnits', 'userSpaceOnUse')
      .attr('x1', d => d.source.x1)
      .attr('x2', d => d.target.x0)
      .call(gradient => gradient.append('stop')
        .attr('offset', '0%')
        .attr('stop-color', ({ source: { index: i } }) => this.color_for_target(G[i])))
      .call(gradient => gradient.append('stop')
        .attr('offset', '100%')
        .attr('stop-color', ({ target: { index: i } }) => this.color_for_target(G[i])));
    // Target specific node and link
    // move it
    // d3.select(‘#id’).node().__datum___
    link.append('path')
      .attr('d', linkPath)
      .attr('stroke', linkColor === 'source-target' ? ({ index: i }) => 'url(#' + uid + '-link-' + i + ')'
        : linkColor === 'source' ? ({ source: { index: i } }) => color(G[i])
          : linkColor === 'target' ? ({ target: { index: i } }) => color(G[i])
            : linkColor)
      .attr('stroke-width', ({ width }) => Math.max(1, width))
      // .call(Lt ? path => path.append('title').text(({ index: i }) => Lt[i]) : () => { });
    link
      .on('mouseover', (d, i) => {
        this.over(d, i, 'link')
      })
      .on('mouseout', (d, i) => {
        this.out(d, i, 'link')
      })
      .on('mousemove', (d, i) => {
        this.move(d, i, 'link')
      })
      .on('click', (e, d) => {
        let url = new URL(this.detail_path);
        url.searchParams.append('source', d.source.id);
        url.searchParams.append('target', d.target.id);
        window.open(url, '_blank')
      })
    // Text
    if (Tl) svg.append('g')
      .attr('font-family', 'sans-serif')
      .attr('font-size', 14)
      .selectAll('text')
      .data(nodes)
      .join('text')
      .attr('x', d => d.x0 < width / 2 ? d.x1 + nodeLabelPadding : d.x0 - nodeLabelPadding)
      .attr('y', d => (d.y1 + d.y0) / 2)
      .attr('dy', '0.35em')
      .attr('text-anchor', d => d.x0 < width / 2 ? 'start' : 'end')
      //.attr('transform', 'rotate(90)')
      .attr('style', 'font-weight:600;fill:black;stroke:white;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:0.5;')
      .html(({ index: i }) => {
        //let words = [];
        //Tl[i].split(/\b/).forEach(item => words.push('<tspan dx='0' dy='1.2em'>' + item + '</tspan>'))
        //console.log(words.josvin(''))
        return Tl[i]
      });
    let color = this.color
    this.wrapper.node().appendChild(Object.assign(svg.node(), { scales: { color } }))
    // return Object.assign(svg.node(), { scales: { color } });
  } // end draw

  intern(value) {
    return value !== null && typeof value === 'object' ? value.valueOf() : value;
  }

  color_for_target(id, color) {
    return this.targetColors[id] == null ? this.color(id) : this.targetColors[id]
  }

  tranlate_location(d) {
    if (d.id == 'Returns to Homelessness') {
      let diff = d.y1 - d.y0
      d.y0 = this.height - 50 - diff * .5
      d.y1 = this.height - 50 + diff * .5
    } else {
      d.y0
    }
    return d
  }

  node_sorter(a, b) {
    a_weight = this.nodeWeights[a.id] || 0
    b_weight = this.nodeWeights[b.id] || 0
    return a_weight > b_weight
  }

  over(event, node, type) {
    // console.log('over', node)
    // Reset container
    this.Tooltip.html('');
    // Append tooltip contents
    let table = this.Tooltip
      .style('opacity', 1)
      .append('table')
      .attr('class', 'table');

    table.append('thead')
      .append('tr')
      .append('th')
      .attr('colspan', '2')
      .style('background', this.background(node))
      .style('color', 'white')
      .text(this.title(node));
    this.tooltip_details(node, table.append('tbody'))
  }

  tooltip_details(node, tbody) {
    let count_tr = tbody
      .append('tr');
    count_tr
      .append('td')
      .text('Households')
    count_tr
      .append('td')
      .text(d3.format(",.1~f")(node.value))
    if(node.id) {
      return
    } else {
      let percent_tr = tbody
        .append('tr')
      percent_tr
        .append('td')
        .text(`Percent ${node.source.id}`)
      let percent = node.value / node.source.value
      percent_tr
        .append('td')
        .text(d3.format(".0%")(percent))
    }
  }

  background(node) {
    if (node.id) {
      return this.color_for_target(node.id)
    } else {
      return `linear-gradient(0.25turn, ${this.color_for_target(node.source.id)}, ${this.color_for_target(node.target.id)})`
    }
  }

  title(node) {
    if(node.id) {
      return node.id
    } else {
      return `${node.source.id} → ${node.target.id}`
    }
  }

  move(event, node) {
    this.Tooltip
      .style('left', (this.d3Sankey.pointer(event)[0] + 10) + 'px')
      .style('top', (this.d3Sankey.pointer(event)[1]) + 'px');
  }

  out(event, node) {
    // console.log('out', event, node)
    // sankey.dflows(d.flows);
    // drawDLink(sankey.dlinks());
    // updateTooltip(d);
    this.Tooltip
      .style('opacity', 0);
    this.Tooltip.html('');
  }
};
