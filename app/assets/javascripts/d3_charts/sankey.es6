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
      nodeColumns,
      width,
      height,
      detail_path,
      client_word,
    },
  ) {
    //this._build_chart = this._build_chart.bind(this);
    this.d3Sankey = d3;
    this.chart_selector = chart_selector;
    this.nodeGroup = nodeGroup;
    this.targetColors = targetColors;
    this.nodeWeights = nodeWeights;
    this.nodeColumns = nodeColumns;
    this.width = width;
    this.height = height;
    this.detail_path = detail_path;
    this.client_word = client_word;
    this.wrapper = this.d3Sankey.select(chart_selector);
    this.sankey = this.d3Sankey.sankey();
  }

  prepare() {
    const width = this.width;
    const height = this.height;
    this.chart = d3.create('svg')
      .attr('viewBox', `0 0 ${width} ${height}`)
      .attr('viewBox', [0, 0, width, height])
      // .attr("width", width)
      // .attr("height", height)
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

    // Compute values.
    const LS = d3.map(links, linkSource).map(this.intern);
    const LT = d3.map(links, linkTarget).map(this.intern);
    const LV = d3.map(links, linkValue);
    let nodes = Array.from(d3.union(LS, LT), id => ({ id }));
    const N = d3.map(nodes, nodeId).map(this.intern);
    const G = d3.map(nodes, nodeGroup).map(this.intern);

    // Replace the input nodes and links with mutable objects for the simulation.
    nodes = d3.map(nodes, (_, i) => ({ id: N[i], layer: nodeColumns[N[i]] }));
    links = d3.map(links, (_, i) => ({ source: LS[i], target: LT[i], value: LV[i] }));
    // Ignore a group-based linkColor option if no groups are specified.
    if (!G && ['source', 'target', 'source-target'].includes(linkColor)) linkColor = 'currentColor';

    // Compute default domains.
    let nodeGroups = G;

    // Construct the scales.
    this.color = d3.scaleOrdinal(nodeGroups, colors);

    // Make note of nodes for later
    this.nodes = nodes;

    // Compute the Sankey layout.
    this.sankey
      .nodeId(({ index: i }) => N[i])
      // Force nodes to specific horizontal locations
      .nodeAlign((node, n) => {
        return node.layer;
      })
      .nodeWidth(nodeWidth)
      .nodePadding(nodePadding)
      .nodeSort((a, b) => this.node_sorter(a, b))
      .extent([[marginLeft, marginTop], [width - marginRight, height - marginBottom]])
    this.sankey({ nodes, links });

    // Compute titles and labels using layout nodes, so as to access aggregate values.
    // if (typeof format !== 'function') format = d3.format(format);
    const Tl = N;
    // const Tt = nodeTitle == null ? null : d3.map(nodes, nodeTitle);
    let linkTitle = d => `${d.source.id} → ${d.target.id}\n${d3.format(d.value)}`;
    const Lt = d3.map(links, linkTitle);

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

    if (G) node.attr('fill', ({ index: i }) => this.color_for_target(G[i], nodes[i]))
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
        if (this.detail_path) {
          let url = new URL(this.detail_path);
          url.searchParams.append('node', d.id);
          window.open(url.toString(), '_blank')
        }
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
        .attr('stop-color', ({ source: { index: i }}, d) => this.color_for_target(G[i], links[d])))
      .call(gradient => gradient.append('stop')
        .attr('offset', '100%')
        .attr('stop-color', ({ target: { index: i }}, d) => this.color_for_target(G[i], links[d])));
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
      .call(Lt ? path => path.append('title').text(({ index: i }) => Lt[i]) : () => { });
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
        if (this.detail_path) {
          let url = new URL(this.detail_path);
          url.searchParams.append('source', d.source.id);
          url.searchParams.append('target', d.target.id);
          window.open(url, '_blank')
        }
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
        // hide items with no values
        if (nodes[i].value == 0) {
          return '';
        }
        return Tl[i]
      });
    if (Tl) svg.append('g')
      .attr('font-family', 'sans-serif')
      .attr('font-size', 14)
      .selectAll('text')
      .data(links)
      .join('text')
      // .attr('x', d => d.x0 < width / 2 ? d.x1 + nodeLabelPadding : d.x0 - nodeLabelPadding)
      .attr('x', d => (d.source.x1 + d.target.x0) / 2)
      .attr('y', d => (d.y1 + d.y0) / 2)
      .attr('dy', '0.35em')
      .attr('text-anchor', 'start')
      .attr('style', 'font-weight:600;fill:black;stroke:white;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:0.5;')
      .html(({ index: i }) => {
        let link = links[i]
        // hide items with no values
        if (link.value == 0) {
          return '';
        }

        let percent = link.value / link.source.value
        return d3.format(".0%")(percent)
      });
    let color = this.color
    this.wrapper.node().appendChild(Object.assign(svg.node(), { scales: { color } }))
    // return Object.assign(svg.node(), { scales: { color } });
  } // end draw

  intern(value) {
    return value !== null && typeof value === 'object' ? value.valueOf() : value;
  }

  color_for_target(id, item) {
    // Hide any items where the link or node value is 0
    if(item.value == 0) {
      return 'transparent'
    }
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
      .text(this.client_word)
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
      return this.color_for_target(node.id, node)
    } else {
      return `linear-gradient(0.25turn, ${this.color_for_target(node.source.id, node.source)}, ${this.color_for_target(node.target.id, node.target)})`
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
    let domain = { 'x domain': [0, $(this.chart_selector).width()], 'y domain': [0, $(this.chart_selector).height()]  }
    let range = { 'x range': [0, this.width], 'y range': [0, this.height] }
    let xScale = this.d3Sankey.scaleLinear();
    let yScale = this.d3Sankey.scaleLinear();
    xScale
      .domain([0, this.width])
      .range([0, $(this.chart_selector).width()])
    yScale
      .domain([0, this.height])
      .range([0, $(this.chart_selector).height()])
    let original_x = this.d3Sankey.pointer(event)[0];
    let original_y = this.d3Sankey.pointer(event)[1];
    let scaled_x = xScale(original_x);
    let scaled_y = yScale(original_y);
    // console.log(range, domain, [original_x, original_y], [scaled_x, scaled_y])
    this.Tooltip
      .style('left', (scaled_x + 10) + 'px')
      .style('top', (scaled_y + 30) + 'px');
      // .style('left', (this.d3Sankey.pointer(event, this.chart.node())[0] + 10) + 'px')
      // .style('top', (this.d3Sankey.pointer(event, this.chart.node())[1] + 50) + 'px');

  }

  out(event, node) {
    this.Tooltip
      .style('opacity', 0);
    this.Tooltip.html('');
  }
};
