//= require ./namespace

const plotHeight = 30;

App.WarehouseReports.clientDemographicsRollupChart = (options) => {
  const margin = { top: 0, bottom: 0, left: 0, right: 0 };
  const wrapper = document.querySelector(options.rootSelector);
  const { width } = wrapper.getBoundingClientRect();
  const height = plotHeight + margin.bottom + margin.top;
  const plotWidth = width - (margin.left + margin.right);
  const xScale = d3.scaleLinear().domain(options.domain).rangeRound([0, plotWidth]);

  const svg = d3
    .select(options.rootSelector)
    .append('svg')
    .attr('width', width)
    .attr('height', height);

  const z = d3.scaleOrdinal(options.palette);

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
    .attr('title', (d, i) => {
      const category = options.categories[i];
      return `${category} (${d.data[category]} clients)`;
    })
    .attr('data-toggle', 'tooltip')
    .style('fill', (_, i) => z(i));
};
