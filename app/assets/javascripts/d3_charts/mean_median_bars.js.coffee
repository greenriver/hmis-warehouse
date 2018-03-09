class App.D3Chart.MeanMedianBars extends App.D3Chart.Base
  constructor: (container_selector, legend_selector, margin, data) ->
    @data = data
    @container_selector = container_selector
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    @barHeight = @scale.y.bandwidth()/2

    if legend_selector
      @legend = new App.D3Chart.StackedLegend(legend_selector, ['Comparison Period', 'Report Period'], ['rgba(0,84,158,0.5)', 'rgba(0,84,158,1)'])

  _resizeContainer: ->
    container = d3.select(@container_selector)
    height = @data.types.length * 40
    container.node().style.height = height+'px'
    console.log(height)

  _loadDomain: () ->
    {
      x: [0, d3.max(@data.values)],
      y: @data.types
    }

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0]
    }

  _loadScale: () ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y).paddingInner(0.2)
    }

  _drawAxis: () ->
    xAxis = d3.axisBottom().scale(@scale.x)
    yAxis = d3.axisLeft().scale(@scale.y)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+@dimensions.height+')')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'yAxis')
      .call(yAxis)

  _drawBackgroundBars: () ->
    @chart.selectAll('rect.background-bars')
      .data(@data.types)
      .enter()
      .append('rect')
        .attr('class', 'background-bars')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d))
        .attr('height', (d) => @scale.y.bandwidth())
        .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
        .attr('fill', (d) => '#f9f9f9')

  _drawBars: (opts) ->
    console.log('draw bars!')
    @chart.selectAll('rect.'+opts.classes)
      .data(opts.data)
      .enter()
      .append('rect')
        .attr('class', opts.classes)
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => 
          @scale.y(d[0]) + (@barHeight*opts.order)
        )
        .attr('height', (d) => @barHeight)
        .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
        .attr('fill', '#00549E')
        .attr('opacity', (d) =>
          if (opts.order == 0) then 1 else 0.5
        )


  draw: ->
    @_drawAxis()
    @_drawBackgroundBars()
    @_drawBars({classes: 'report-bars', data: @data.data.report, order: 0})
    @_drawBars({classes: 'comparison-bars', data: @data.data.comparison, order: 1})
    if @legend
      @legend.draw()



