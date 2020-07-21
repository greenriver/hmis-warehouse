//= require ./namespace

const truncate = (str, limit) => (str.length > limit ? str.slice(0, 30) + '…' : str);

const barPaddingInner = 0.75;
const barPaddingOuter = 0.25;
const plotHeight = 30;
const legend = {
  padding: 0.5,
  rowHeight: 35,
};

App.WarehouseReports.clientDemographicsRollupChart = (options) => {
  const legendHeight = options.categories.length * legend.rowHeight;
  const margin = { top: 0, bottom: 20, left: 0, right: 0 };
  const wrapper = document.querySelector(options.rootSelector);
  const { width } = wrapper.getBoundingClientRect();
  const height = plotHeight + margin.bottom + margin.top + legendHeight;
  const plotWidth = width - (margin.left + margin.right);
  const xScale = d3.scaleLinear().domain(options.domain).rangeRound([0, plotWidth]);

  const svg = d3
    .select(options.rootSelector)
    .append('svg')
    .attr('width', width)
    .attr('height', height);

  const z = d3.scaleOrdinal(d3.schemeCategory10);

  const layers = d3
    .stack()
    .keys(options.categories)([options.values])
    .map((d) => d[0]);
  svg
    .append('g')
    .attr('class', 'chart')
    .attr('transform', `translate(${margin.left},${margin.top})`)
    .selectAll('rect')
    .data(layers)
    .enter()
    .append('rect')
    .attr('x', (d) => xScale(d[0]))
    .attr('width', (d) => xScale(d[1]) - xScale(d[0]))
    .attr('height', plotHeight)
    .attr('title', (d, i) => d[1]-d[0]+' '+options.categories[i])
    .attr('data-toggle', 'tooltip')
    .style('fill', (_, i) => z(i));

  /*
  svg
    .append('g')
    .attr('class', 'axis')
    .attr('transform', `translate(${margin.left},${margin.top + plotHeight})`)
    .call(d3.axisBottom(xScale))
    .selectAll('text')
    .each(function (d, i) {
      console.info(i, d);
      if (i === 0) {
        d3.select(this).attr('dx', '0.25em');
      }
    });
  */
  const legendBox = svg
    .append('g')
    .attr('class', 'legend')
    .attr('transform', `translate(${margin.left},${margin.top + plotHeight + margin.bottom})`);

  const legendYScale = d3
    .scaleBand()
    .domain(options.categories.reverse())
    .range([legendHeight, 0])
    .padding(legend.padding);

  legendBox
    .selectAll('rect')
    .data(options.categories.reverse())
    .enter()
    .append('rect')
    .attr('x', 0)
    .attr('y', (d) => legendYScale(d))
    .attr('width', legendYScale.bandwidth())
    .attr('height', legendYScale.bandwidth())
    .style('fill', (d, i) => z(i));

  legendBox
    .selectAll('text')
    .data(options.categories.reverse())
    .enter()
    .append('text')
    .attr('x', (1 + legend.padding) * legendYScale.bandwidth())
    .attr('y', (d) => legendYScale(d))
    .attr('dy', '0.5em')
    .text(function (d, i) {
      return options.values[d] + ' - ' + d
    })
    .style('alignment-baseline', 'middle');
};
