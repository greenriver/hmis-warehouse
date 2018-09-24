#= require ./namespace
#= require ./base

class App.D3Chart.RRHOutcome extends App.D3Chart.Base
  constructor: (container_selector, data) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @data = data
    console.log('outcome data:', @data)
    super(container_selector, @margin)

    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

  _loadScale: ->
    {
      color: d3.scaleOrdinal().domain(@domain.color).range(@range.color),
      arc: d3.arc().outerRadius(@range.radius - 10).innerRadius(0),
      pie: d3.pie().sort(null).value((d) -> d.count)
    }

  _loadDomain: ->
    {
      color: @data.map((d) -> d.outcome)
    }

  _loadRange: () ->
    {
      radius: @dimensions.height/2,
      color: ["#288be4", "#091f2f", "#fb4d42", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
    }

  draw: () ->
    @chart
      .attr("transform", "translate(" + @dimensions.width / 2 + "," + @dimensions.height / 2 + ")")
      .selectAll('g.arc')
      .data(@scale.pie(@data))
      .enter()
      .append('g')
        .attr('class','arc')
        .append('path')
          .attr('d', @scale.arc)
          .style('fill', (d) => @scale.color(d.data.outcome))

# class App.D3Chart.RHHBarBase extends App.D3Chart.Base
#   constructor: (container_selector, data, allData) ->
#     @margin = {top: 10, right: 0, bottom: 60, left: 30}
#     @data = data
#     @allData = allData
#     super(container_selector, @margin)

#   _loadRange: ->
#     {
#       x: [0, @dimensions.width],
#       y: [@dimensions.height, 0],
#     }

#   _loadScale: ->
#     {
#       x: d3.scaleBand().domain(@domain.x).range(@range.x).padding(0.3),
#       y: d3.scaleLinear().domain(@domain.y).range(@range.y)
#     }

class App.D3Chart.RRHReturns extends App.D3Chart.Base
  constructor: (container_selector, data, program) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @bands = data['x_bands']
    @data = data[program]
    @allData = data['both']
    console.log(@data)
    super(container_selector, @margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
    }

  _loadDomain: ->
    {
      x: @bands,
      y: [0, d3.max(@allData, (d) -> d.count)]
    }

  _loadScale: ->
    {
      x: d3.scaleBand().domain(@domain.x).range(@range.x).padding(0.3),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y)
    }

  _drawAxes: ->
    xAxis = d3.axisBottom().scale(@scale.x)
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
        .attr('fill', '#091f2f')
        .attr('x', (d) => @scale.x(d.discrete))
        .attr('y', (d) => @scale.y(d.count))
        .attr('width', (d) => @scale.x.bandwidth())
        .attr('height', (d) => @scale.y(0) - @scale.y(d.count))


class App.D3Chart.RRHOverview extends App.D3Chart.Base
  constructor: (container_selector, data, allData) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @data = @_to_date(data)
    @allData = @_to_date(allData)
    console.log('overview data:', @data)
    super(container_selector, @margin)

    @range = @_loadRange()
    @domain = @_loadDomain()
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
    yearTicks = years.filter((v, i, a) -> a.indexOf(v) == i).map((y) -> new Date(y, 1, 1))
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
        .attr('fill', '#091f2f')
        .attr('x', (d) => @scale.x(d.month_year))
        .attr('y', (d) => @scale.y(d.n_clients))
        .attr('width', (d) => @scale.x.bandwidth())
        .attr('height', (d) => @scale.y(0) - @scale.y(d.n_clients))


