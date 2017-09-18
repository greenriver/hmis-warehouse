#= require ./namespace

class App.D3Chart.Base 
  constructor: (container_selector, margin) ->
    @margin = margin
    @container_selector = container_selector
    @container = d3.select(container_selector)
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

  _drawChart: ->
    dimensions = @dimensions
    svg = @container.append('svg')
      .attr('width', dimensions.chartWidth)
      .attr('height', dimensions.chartHeight)
    chart = svg.append('g')
      .attr('transform', dimensions.chartTransform)
    return chart

