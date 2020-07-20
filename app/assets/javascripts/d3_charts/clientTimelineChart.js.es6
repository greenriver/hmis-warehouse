//= require ./namespace

function wrap(text, width, padding) {
  text.each(function () {
    const paddingV = width * padding;
    const widthV = width - paddingV;
    var text = d3.select(this),
      words = text.text().split(/\s+/).reverse(),
      word,
      line = [],
      lineHeight = 1.2, // ems
      y = text.attr('y'),
      //dy = parseFloat(text.attr('dy')),
      dy = 0,
      tspan = text
        .text(null)
        .append('tspan')
        .attr('x', -paddingV)
        .attr('y', y)
        .attr('dy', dy + 'em');
    while ((word = words.pop())) {
      line.push(word);
      tspan.text(line.join(' '));
      if (tspan.node().getComputedTextLength() > widthV) {
        line.pop();
        tspan.text(line.join(' '));
        line = [word];
        tspan = text
          .append('tspan')
          .attr('x', -paddingV)
          .attr('y', y)
          .attr('dy', lineHeight + dy + 'em')
          .text(word);
      }
    }
  });
}

const barSize = 30;
const barPaddingInner = 0.75;
const barPaddingOuter = 0.25;
App.WarehouseReports.ClientTimelineChart = (options) => {
  const wrapper = document.querySelector(options.rootSelector);
  const { width } = wrapper.getBoundingClientRect();
  const margin = { top: 0, bottom: 20, left: 200, right: 0 };
  const height = options.enrollments.length * barSize + margin.bottom + margin.top;
  const plotWidth = width - (margin.left + margin.right);
  const plotHeight = height - (margin.top + margin.bottom);
  const cocCodes = options.cocs.map((d) => d.code)

  const domain = options.domain.map((s) => d3.isoParse(s));
  const enrollments = options.enrollments.map((enrollment, idx) => ({
    ...enrollment,
    id: idx,
    history: enrollment.history.map((evt) => ({
      cocCode: enrollment.coc,
      from: d3.isoParse(evt.from),
      to: d3.isoParse(evt.to),
    })),
  }));

  const xScale = d3.scaleTime().domain(domain).rangeRound([0, plotWidth]);
  const yScale = d3
    .scaleBand()
    .domain(enrollments.map((d) => d.id))
    .range([plotHeight, 0])
    .paddingInner(barPaddingInner)
    .paddingOuter(barPaddingOuter);

  const svg = d3
    .select(options.rootSelector)
    .append('svg')
    .attr('width', width)
    .attr('height', height);

  const chart = svg
    .append('g')
    .attr('class', 'chart')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  chart
    .selectAll('g')
    .data(enrollments)
    .enter()
    .append('g')
    .attr('transform', function (d, i) {
      return `translate(0,${yScale(d.id)})`;
    })
    .selectAll('rect')
    .data((d) => d.history)
    .enter()
    .append('rect')
    .attr('x', (d) => xScale(d.from))
    .attr('width', (d) => xScale(d.to) - xScale(d.from))
    .attr('height', yScale.bandwidth())
    .attr('class', (d) => `c-swatch__display--fill-${cocCodes.indexOf(d.cocCode)}`)
    .attr('fill-opacity', 0.8);

  svg
    .append('g')
    .attr('class', 'axis')
    .attr('transform', `translate(${margin.left},${margin.top + plotHeight})`)
    .call(d3.axisBottom(xScale).tickFormat(d3.timeFormat('%m/%y')));

  svg
    .append('g')
    .attr('class', 'axis')
    .attr('transform', `translate(${margin.left},${margin.top})`)
    .call(
      d3
        .axisLeft(yScale)
        .tickSize(0)
        .tickFormat((d, i) => {
          const { coc, project_name } = enrollments[i];
          return `${coc} - ${project_name}`;
        }),
    )
    .selectAll('.tick text')
    .call(wrap, margin.left, 0.1);
};
