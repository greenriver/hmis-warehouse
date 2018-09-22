#= require ./namespace
#= require ./base

class App.D3Chart.RapidRehousingChart extends App.D3Chart.Base
  constructor: (container_selector, data, allData) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @data = @_to_date(data)
    @allData = @_to_date(allData)
    console.log(@data)
    super(container_selector, @margin)
    @range = @_loadRange()
    @domain = @_loadDomain()

    console.log('range', @range)
    console.log('domain', @domain)

    @scale = @_loadScale()

  _to_date: (data)->
    parseTime = d3.timeParse("%Y-%m-%d")
    data.map((d) ->
      d.month_year = parseTime(d.month_year)
      d
    )

  _loadScale: ->
    {
      x: d3.scaleBand().domain(@domain.x).range(@range.x).padding(0.3),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y)
    }

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
    }

  _loadDomain: ->
    {
      x: @allData.map((d) -> d.month_year),
      y: [0, d3.max(@allData, (d) -> d.n_clients)]
    }

  _drawAxes: ->
    years = @domain.x.map((d) -> d.getFullYear())
    console.log('years', years)
    yearTicks = years.filter((v, i, a) -> a.indexOf(v) == i).map((y) -> new Date(y, 1, 1))
    console.log('yearTicks', yearTicks)
    xAxis = d3.axisBottom().scale(@scale.x)
      .tickFormat(d3.timeFormat('%Y'))
      .tickValues(yearTicks)
    yAxis = d3.axisLeft().scale(@scale.y)
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)

  draw: ->
    @_drawAxes()
    @chart.selectAll('rect.bar')
      .data(@data)
      .enter()
      .append('rect')
        .attr('class', 'bar')
        .attr('fill', 'red')
        .attr('x', (d) => @scale.x(d.month_year))
        .attr('y', (d) => @scale.y(d.n_clients))
        .attr('width', (d) => @scale.x.bandwidth())
        .attr('height', (d) => @scale.y(0) - @scale.y(d.n_clients))


