#= require ./namespace

class App.D3Chart.Base
  constructor: (container_selector, margin, viewBoxSizing=false) ->
    @viewBoxSizing = viewBoxSizing
    @margin = margin
    @container_selector = container_selector
    @container = d3.select(container_selector)
    if ! @container.node()?
      return
    @dimensions = @_loadDimensions()
    @chart = @_drawChart()

  _loadDimensions: ->
    # margin = @margin
    cBox = @container.node().getBoundingClientRect()
    width = cBox.width
    height = cBox.height
    return {
      width: width - @margin.left - @margin.right,
      height: height - @margin.top - @margin.bottom,
      chartWidth: width,
      chartHeight: height,
      chartTransform: 'translate('+@margin.left+','+@margin.top+')'
    }

  _loadMonthName: (date) ->
    months = [
      "January", "February", "March",
      "April", "May", "June", "July",
      "August", "September", "October",
      "November", "December"
    ]
    months[date.getMonth()]

  _drawChartBackground: () ->
    @chart.append('rect')
      .attr('x', 0)
      .attr('y', 0)
      .attr('width', @dimensions.width)
      .attr('height', @dimensions.height)
      .attr('fill', '#f1f1f1')

  _drawChart: ->
    dimensions = @dimensions
    if @viewBoxSizing
      @svg = @container.append('svg')
        .attr('viewBox', "0 0 #{dimensions.chartWidth} #{dimensions.chartHeight}")
    else
      @svg = @container.append('svg')
        .attr('width', dimensions.chartWidth)
        .attr('height', dimensions.chartHeight)
    chart = @svg.append('g')
      .attr('transform', dimensions.chartTransform)
    return chart
