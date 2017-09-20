#= require ./namespace
#= require ./base

# sample housed data
# data = {"Sep 18, 2017 12:00 am":false,"Sep 15, 2017 12:00 am":false,"Sep 13, 2017 12:00 am":false,"Sep 12, 2017 12:00 am":false,"Aug 29, 2017 12:00 am":false,"Aug 16, 2017 12:00 am":false,"Aug 30, 2017 12:00 am":false,"Aug 25, 2017 12:00 am":false,"Aug 21, 2017 12:00 am":false,"Aug 14, 2017 12:00 am":false,"Aug  9, 2017 12:00 am":false,"Aug  8, 2017 12:00 am":true,"Aug  1, 2017 12:00 am":true,"Sep 11, 2017 12:00 am":false,"Aug 10, 2017 12:00 am":false,"Aug 23, 2017 12:00 am":false,"Sep  1, 2017 12:00 am":false,"Aug 22, 2017 12:00 am":false,"Aug 18, 2017 12:00 am":false,"Sep  6, 2017 12:00 am":false,"Aug 24, 2017 12:00 am":false,"Aug 15, 2017 12:00 am":false,"Sep  7, 2017 12:00 am":false,"Sep  2, 2017 12:00 am":false,"Aug 11, 2017 12:00 am":false,"Aug  1, 2017  2:47 pm":true,"Aug 23, 2017  4:20 pm":false,"Aug 24, 2017  3:15 pm":false,"Aug 14, 2017  1:35 pm":false,"Aug 25, 2017  3:57 pm":false,"Aug 30, 2017  1:03 pm":false,"Aug 29, 2017  3:05 pm":false,"Aug 25, 2017  3:25 pm":false,"Aug 23, 2017  4:13 pm":false,"Aug 21, 2017 10:00 am":false,"Aug 16, 2017 10:08 am":false,"Aug 10, 2017 11:40 am":false,"Aug 23, 2017 10:59 am":false,"Aug 23, 2017 10:23 am":false,"Aug 14, 2017  1:36 pm":false,"Aug 23, 2017  4:18 pm":false,"Aug 25, 2017  3:55 pm":false,"Aug 22, 2017  1:36 pm":false,"Aug 24, 2017  3:25 pm":false,"Aug 25, 2017  3:51 pm":false,"Aug 10, 2017 11:37 am":false,"Aug 23, 2017 10:58 am":false,"Aug 21, 2017 10:27 am":false,"Aug 11, 2017  4:06 pm":false,"Aug 21, 2017  9:57 am":false,"Aug 25, 2017  3:29 pm":false,"Aug 25, 2017  9:54 am":false,"Aug 18, 2017 10:03 am":false,"Aug 22, 2017  1:43 pm":false,"Aug  8, 2017  2:45 pm":true,"Aug  9, 2017  3:16 pm":false,"Aug 16, 2017  9:35 am":false,"Aug 23, 2017  5:11 pm":false,"Aug 24, 2017  3:55 pm":false,"Aug  9, 2017  4:22 pm":false,"Sep  1, 2017  2:19 pm":false,"Aug 16, 2017  9:44 am":false,"Aug 18, 2017 10:00 am":false}

class App.D3Chart.PatientCharts
  constructor: (charts) ->
    charts.forEach((chart) =>
      attrs = {
        margin: chart.margin,
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
    super(container_selector, attrs.margin)
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
    yAxis = d3. axisLeft().scale(@scale.y)
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
          .text('No Data')

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
    yAxis = d3. axisLeft()
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
    super(container_selector, data, attrs)

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: ['#57CC9B', '#FFBC86']
    }

  _loadDomain: ->
    {
      x: d3.extent(@data, (d) => d.date)
          .map((d, i) =>
            month = if i == 0 then d.getMonth() else d.getMonth()+1
            day = if i == 0 then 1 else 0
            new Date(d.getFullYear(), month, day) 
          )
      y: ['status'],
      color: [true, false]
    }

  _loadScale: ->
    {
      x: d3.scaleTime().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y),
      color: d3.scaleOrdinal().domain(@domain.color).range(@range.color)
    }

  _yearAxesPoints: (d)->
    generateLine = d3.line()
    date1 = new Date(d, 0, 1)
    date2 = new Date(d, 12, 0)
    date1 = if date1 < @domain.x[0] then @domain.x[0] else date1
    date2 = if date2 > @domain.x[1] then @domain.x[1] else date2
    x1 = @scale.x(date1)
    x2 = @scale.x(date2)
    y1 = @scale.y.bandwidth()+25
    y2 = @scale.y.bandwidth()+35
    center = x1 + ((x2-x1)/2)
    line = generateLine([[x1, y1], [x1, y2], [x2, y2], [x2, y1]])
    {
      x1: x1,
      x2: x2,
      y1: y1,
      y2: y2,
      center: center,
      line: line
    }

  _drawYearAxis: ->
    years = d3.nest()
      .key((d) =>
        +d.date.getFullYear()
      ).entries(@data).map((d) => d.key)
    yearAxis = @chart.append('g')
      .attr('class', 'year-axis')
    yearAxis.selectAll('.year')
      .data(years)
      .enter()
      .append('path')
        .attr('class', 'year')
        .attr('d', (d) =>
          @_yearAxesPoints(d).line
        ).attr('fill', 'none')
        .attr('stroke-width', '1px')
        .attr('stroke', '#d2d2d2')
    yearAxis.selectAll('.year-text')
      .data(years)
      .enter()
      .append('text')
        .attr('class', 'year-text')
        .attr('x', (d) => @_yearAxesPoints(d).center)
        .attr('y', @scale.y.bandwidth()+50)
        .attr('text-anchor', 'middle')
        .attr('font-size', '12px')
        .text((d) => d)

  _drawMonthBox: (xAxis, months)->
    xAxis.selectAll('.month')
      .data(months)
      .enter()
      .append('rect')
        .attr('class', 'month')
        .attr('x', (d) => 
          [month, year] = d.split(',')
          date = new Date(+year, +month, 1)
          @scale.x(date)
        )
        .attr('y', 0+@scale.y.bandwidth())
        .attr('width', (d) =>
          [month, year] = d.slice().split(',')
          date1 = new Date(+year, +month, 1)
          date2 = new Date(+year, +month+1, 1)
          if date2 > @domain.x[1]
            (@scale.x(@domain.x[1]) - @scale.x(date1))+'px'
          else
            (@scale.x(date2) - @scale.x(date1))+'px'
        )
        .attr('height', '20px')
        .attr('stroke', '#FFFFFF')
        .attr('stroke-width', '1px')
        .attr('fill', '#f1f1f1')
  
  _drawMonthText: (xAxis, months) ->
    xAxis.selectAll('.month-text')
      .data(months)
      .enter()    
      .append('text')
        .attr('class', 'month-text')
        .attr('x', (d) =>
          [month, year] = d.slice().split(',')
          date1 = new Date(+year, +month, 1)
          date2 = new Date(+year, +month+1, 0)
          half = (@scale.x(date2) - @scale.x(date1))/2
          @scale.x(date1) + half
        )
        .attr('y', 0+@scale.y.bandwidth()+13)
        .attr('text-anchor', 'middle')
        .style('font-size', '12px')
        .style('font-family', "'Open Sans Condensed', sans-serif")
        .style('fill', '#777777')
        .text((d) =>
          [month, year] = d.slice().split(',')
          date1 = new Date(+year, +month, 1)
          date1.getMonth() + 1
        )

  _drawAxes: ->
    @_drawYearAxis()
    months = d3.nest()
      .key((d) => 
        d.date.getMonth()+','+d.date.getFullYear()
      ).entries(@data).map((d) => d.key)
    xAxis = @chart.append('g')
      .attr('class', 'x-axis')
    @_drawMonthBox(xAxis, months)
    @_drawMonthText(xAxis, months)

  _draw: ->
    @chart.append('rect')
      .attr('x', @scale.x(@domain.x[0]))
      .attr('y', 0)
      .attr('height', @scale.y.bandwidth())
      .attr('width', @scale.x(@domain.x[1]-@scale.x(@domain.x[0])))
      .attr('fill', '#f1f1f1')
      .attr('opacity', '0.3')
    @chart.selectAll('.status')
      .data(@data)
      .enter()
      .append('rect')
        .attr('class', 'status')
        .attr('x', (d) => @scale.x(d.date))
        .attr('y', @scale.y('status'))
        .attr('height', (d) => @scale.y.bandwidth())
        .attr('width', (d) =>
          date = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate()+1)
          dayWidth = @scale.x(date) - @scale.x(d.date) - 1 
          if dayWidth < 5
            if dayWidth > 1 then dayWidth else 1
          else
            5
        )
        .attr('fill', (d) => @scale.color(d.status))

  draw: ->
    super



