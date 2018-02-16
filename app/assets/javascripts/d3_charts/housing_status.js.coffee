#= require ./namespace
#= require ./base

class App.D3Chart.PatientCharts
  constructor: (charts) ->
    charts.forEach((chart) =>
      attrs = {
        margin: chart.margin,
        viewBoxSizing: chart.viewBoxSizing or false,
        dates_container: $(chart.selector).data('dates')
      }
      if chart.type == 'hs'
        chartToDraw = new App.D3Chart.HousingStatus(chart.selector, chart.data, attrs)
      else if chart.type == 'mi'
        chartToDraw = new App.D3Chart.MonthlyIncome(chart.selector, chart.data, attrs)
      else if chart.type == 'ss'
        chartToDraw = new App.D3Chart.SSMatrix(chart.selector, chart.data, attrs)
      if chartToDraw
        chartToDraw.draw()
    )

class App.D3Chart.PatientChartBase extends App.D3Chart.Base
  constructor: (container_selector, data, attrs) ->
    super(container_selector, attrs.margin, attrs.viewBoxSizing)
    @data = @_loadData(data)
    if @data.length > 0
      @range = @_loadRange()
      @domain = @_loadDomain()
      @scale = @_loadScale()
      @datesContainer = @container.selectAll(attrs.dates_container)

  _loadData: (data)->
    keys = Object.keys(data)
    newData = keys.map((key) =>
      {date: new Date(key), status: data[key]}
    )
    if newData.length != 0
      newData.sort((a, b) =>
        a.date - b.date
      )
    else
      []

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0]
    }

  _loadScale: ->
    {
      x: d3.scaleTime().domain(@domain.x).range(@range.x),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y)
    }

  _customizeYAxis: () ->
    generateLine = d3.line()
    @chart.selectAll('g.y-axis .domain').remove()
    ticks = @chart.selectAll('g.y-axis g.tick')
    scale = @scale
    domain = @domain
    ticks.each((tick) ->
      tickEle = d3.select(this)
      tickEle.selectAll('line').remove()
      tickEle.selectAll('text')
        .style('font-family', "'Open Sans Condensed', sans-serif")
        .style('font-weight', '500')
        .style('font-size', '12px')
        .attr('fill', '#777777')
      tickEle.append('path')
        .attr('d', generateLine([[scale.x(domain.x[0]), 0], [scale.x(domain.x[1]), 0]]))
        .attr('stroke', '#d2d2d2')
        .attr('stroke-width', '0.5px')
    )

  _customizeXAxis: () ->
    @chart.selectAll('g.x-axis .domain').remove()
    ticks = @chart.selectAll('g.x-axis g.tick')
    ticks.each((tick) ->
      tickEle = d3.select(this)
      tickEle.selectAll('text')
        .style('font-family', "'Open Sans Condensed', sans-serif")
        .style('font-weight', '700')
        .style('font-size', '12px')
        .attr('fill', '#777777')
    )

  _drawAxes: () ->
    xAxis = d3.axisBottom().scale(@scale.x)
    yAxis = d3.axisLeft().scale(@scale.y)
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    @_customizeYAxis()
    @_customizeXAxis()

  _draw: ->
    @_drawChartBackground()
    lineGenerator = d3.line()
    path = []
    @data.forEach((d) =>
      path.push([@scale.x(d.date), @scale.y(d.status)])
    )
    d = lineGenerator(path)
    @chart.append('path')
      .attr('d', d)
      .attr('fill', 'none')
      .attr('stroke', '#00549E')
      .attr('stroke-width', '2px')

    @chart.selectAll('circle')
      .data(@data)
      .enter()
      .append('circle')
        .attr('cx', (d) => @scale.x(d.date))
        .attr('cy', (d) => @scale.y(d.status))
        .attr('r', '4px')
        .attr('fill', '#00549E')

  draw: () ->
    if @data.length > 0
      dateString = ' ('+@._loadMonthName(@domain.x[0])+' '+@domain.x[0].getFullYear()+' - '+@._loadMonthName(@domain.x[1])+' '+@domain.x[1].getFullYear()+') '
      @datesContainer.text(dateString)
      @_draw()
      @_drawAxes()
    else
      @container.selectAll('svg').remove()
      @container
        .style('height', 'auto')
        .append('p')
          .text('None on file')

class App.D3Chart.SSMatrix extends App.D3Chart.PatientChartBase
  constructor: (container_selector, data, attrs) ->
    super(container_selector, data, attrs)

  _loadDomain: ->
    {
      x: d3.extent(@data, (d) => d.date)
          .map((d, i) =>
            month = if i == 0 then d.getMonth() else d.getMonth()+1
            day = if i == 0 then 1 else 0
            new Date(d.getFullYear(), month, day)
          )
      y: [0, d3.max(@data, (d) => d.status)+10]
    }

  draw: ->
    super

class App.D3Chart.MonthlyIncome extends App.D3Chart.PatientChartBase
  constructor: (container_selector, data, attrs) ->
    super(container_selector, data, attrs)

  _loadDomain: ->
    {
      x: d3.extent(@data, (d) => d.date)
          .map((d, i) =>
            month = if i == 0 then d.getMonth() else d.getMonth()+1
            day = if i == 0 then 1 else 0
            new Date(d.getFullYear(), month, day)
          )
      y: [0, d3.max(@data, (d) => d.status)+10]
    }

  _drawAxes: () ->
    xAxis = d3.axisBottom().scale(@scale.x)
    yAxis = d3.axisLeft()
      .tickFormat(d3.format('$.2s'))
      .scale(@scale.y)
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    @_customizeYAxis()
    @_customizeXAxis()

  draw: ->
    super

class App.D3Chart.HousingStatus extends App.D3Chart.PatientChartBase
  constructor: (container_selector, data, attrs) ->
    @lineColor = '#CCCCCC'
    @statusColors = [
      circle: '#ff4d4d'
      band: '#fff5f5'
    ,
      circle: '#eba652'
      band: '#fefaf5'
    ,
      circle: '#c0d43f'
      band: '#fcfdf4'
    ,
      circle: '#71cc49'
      band: '#f7fcf5'
    ,
      circle: '#43a85e'
      band: '#f4faf6'
    ]
    @stati = [ 'Street', 'Shelter', 'Doubling Up', 'Temporary', 'Permanent' ]

    super(container_selector, data, attrs)
    @tooltip = d3.select('#d3-tooltip')

  _loadData: (data)->
    data?.forEach (d) ->
      d.date = new Date(d.date)

    if data.length != 0
      data.sort (a, b) =>
        a.date - b.date
    else
      []

  _circleColors: ->
    @statusColors.map (c) -> c.circle

  _bandColors: ->
    @statusColors.map (c) -> c.band

  _formatDate: (date) ->
    date.toDateString()

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: @_circleColors()
    }

  _loadDomain: ->
    {
      x: d3.extent(@data, (d) => d.date)
          .map((d, i) =>
            month = if i == 0 then d.getMonth() else d.getMonth()+1
            day = if i == 0 then 1 else 0
            new Date(d.getFullYear(), month, day)
          )
      y: d3.extent([0, 1, 2, 3, 4, 5])
      color: [false, true]
    }

  _loadScale: ->
    {
      x: d3.scaleTime().domain(@domain.x).range(@range.x)
      y: d3.scaleLinear().domain(@domain.y).range(@range.y)
      color: @_circleColors()
    }

  _drawYearAxis: ->
    scale = d3.scaleLinear()
      .domain(@domain.x)
      .range([0, @dimensions.width])
    xAxis = d3.axisBottom()
      .tickValues(@scale.x.domain())
      .tickSize(20)
      .tickPadding(8)
      .scale(scale)
      .tickFormat((d) => @_formatDate(d))
    @chart.append('g')
      .call(xAxis)
      .attr('transform', "translate(0, #{@dimensions.height})")
      .attr('class', 'x-axis')

  _drawStatusAxis: ->
    scale = d3.scaleLinear()
      .domain([0, 5])
      .range([@dimensions.height, 0])
    yAxis = d3.axisLeft()
      .ticks(4)
      .tickSize(@dimensions.width)
      .tickFormat('')
      .scale(scale)
    yAxisGroup = @chart.append('g')
      .call(yAxis)
      .attr('transform', "translate(#{@dimensions.width}, 0)")
      .attr('class', 'y-axis')
    # Add vertical axis line on left
    yAxisGroup.append('line')
      .attr('y1', 0)
      .attr('y2', @dimensions.height)
      .attr('x1', 0)
      .attr('x2', .5)
      .attr('stroke', @lineColor)
      .attr('stroke-width', 1)
      .attr('transform', "translate(#{@dimensions.width * -1}, 0)")

  _drawBands: ->
    band = d3.scaleBand().domain(@stati).range([0, @dimensions.height])
    bandHeight = band.bandwidth()
    bands = @chart.append('g').attr('class', 'status__bands')
    @stati.reverse().forEach (status, i) =>
      bands.append('rect')
        .attr('height', bandHeight)
        .attr('width', @dimensions.width)
        .attr('x', 0)
        .attr('y', bandHeight * i)
        .attr('fill', @_bandColors().reverse()[i])
      bands.append('text')
        .attr('x', -85)
        .attr('y', (bandHeight * i) + (bandHeight / 2))
        .attr('class', 'y-axis__label')
        .text(status)
      bands.append('circle')
        .attr('cx', -105)
        .attr('cy', (bandHeight * i) + (bandHeight / 2))
        .attr('fill', @_circleColors().reverse()[i])
        .attr('r', 8)
        .attr('class', 'y-axis__label-circle')

  _drawLine: ->
    line = d3.line()
      .x((d) => @scale.x(d.date))
      .y((d) => @scale.y(d.score + .5))
    @chart.append('path')
      .data([@data])
      .attr('class', 'status__line')
      .attr('d', line)
      .attr('fill', 'none')
      .attr('stroke', @lineColor)
      .attr('stroke-width', 2)

  _drawCircles: ->
    circleGroup = @chart.append('g').attr('class', 'status__circles')
    circleGroup.selectAll('circle')
      .data(@data)
      .enter()
      .append('circle')
        .attr('cx', (d) => @scale.x(d.date))
        .attr('cy', (d) => @scale.y(d.score + .5))
        .attr('r', 10)
        .attr('fill', (d) => @_circleColors()[d.score])
        .attr('stroke', (d) => @_bandColors()[d.score])
        .attr('stroke-width', 2)
        .on('mouseover', (d) => @_showTooltip(d))
        .on('mousemove', (d) => return)
        .on('mouseout', (d) => @_removeTooltip())

  _positionTooltip: ->
    rect = @tooltip.node().getBoundingClientRect()
    height = rect.bottom - rect.top
    width = rect.width/2

    @tooltip.style('top', (d3.event.pageY-height)+'px')
    @tooltip.style('left', (d3.event.pageX-width)+'px')

  _showTooltip: (data) ->
    @tooltip
      .style('left', event.pageX+'px')
      .style('top', event.pageY+'px')
      .style('display', 'block')
    @tooltip.selectAll('div').remove()
    @tooltip.append('div')
      .attr('class', 'd3-tooltip__item d3-tooltip__label')
      .text(@_formatDate(data.date))
    @tooltip.append('div')
      .attr('class', 'd3-tooltip__item d3-tooltip__item--primary')
      .text(data.status)

    @tooltip.transition()
      .duration(50)
      .style('opacity', 1)

  _removeTooltip: ->
    @tooltip.transition()
      .duration(500)
      .style('opacity', 0)
      .on 'end', () ->
        d3.select(@)
          .style('display', 'none')

  _drawAxes: ->
    @_drawYearAxis()
    @_drawStatusAxis()

  _draw: ->
    @_drawBands()
    @_drawLine()
    @_drawCircles()

  draw: ->
    super
