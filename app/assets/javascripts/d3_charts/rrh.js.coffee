#= require ./namespace
#= require ./base

class App.D3Chart.RRHCharts
  constructor: (container, program_1_selector, program_2_selector, data) ->
    @container = $(container)
    @program_1 = $(program_1_selector)
    @program_2 = $(program_2_selector)
    @chartTypes = ['overview', 'outcomes', 'shelter_returns', 'demographics']
    @data = data
    @charts = {}

  load: -> @_getProgramData()

  listen: ->
    @program_1.change((e) => @_getProgramData())
    @program_2.change((e) => @_getProgramData())

  draw: () -> 
    @_loadCharts()
    @_drawCharts() 

  _loadCharts: () ->
    for type, index in @chartTypes
      @charts[type] = []
      for selector, i in @data[type].selectors
        d = $.extend(true, {}, @data)
        if type == 'overview'
          @charts[type].push(new App.D3Chart.RRHOverview(selector, d.overview.data['program_'+(i+1)], d.overview.data.both))
        else if type == 'outcomes'
          @charts[type].push(new App.D3Chart.RRHOutcome(selector, d.outcomes.data['program_'+(i+1)]))
        else if type == 'shelter_returns'
          @charts[type].push(new App.D3Chart.RRHReturns(selector, d.shelter_returns.data, 'program_'+(i+1)))
        else if type == 'demographics'
          @charts[type].push(new App.D3Chart.RRHDemographics(selector, d.demographics.data['program_'+(i+1)], d.demographics.data.both))

  _drawCharts: () ->
    for type, index in @chartTypes
      if @charts[type]
        for chart, i in @charts[type]
          chart.draw()

  _getProgramData: () ->
    path = @program_1.data('path')
    @container.html('Loading...')
    $.get(path, {program_1_id: @program_1.val(), program_2_id: @program_2.val()}, (response) =>
      console.log('Loading charts')
    )

class App.D3Chart.RRHOverview extends App.D3Chart.Base
  constructor: (container_selector, data, allData) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @_initData(data, allData)
    super(container_selector, @margin)
    @_initScale()
    @tooltip = d3.select('#d3-tooltip')

  _initData: (data, allData) ->
    @data = @_to_date(data)
    @allData = @_to_date(allData)

  _initScale: () ->
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

  _customizeYAxis: ->
    step1 = @scale.x.step()-@scale.x.bandwidth()
    step2 = @scale.x.step()+@scale.x.bandwidth()
    generateLine = d3.line()
    @chart.selectAll('g.y-axis .domain').remove()
    @chart.selectAll('g.y-axis .tick:first-child text').remove()
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
        .attr('d', generateLine([[(scale.x(domain.x[0])-step1), 0], [scale.x(domain.x[domain.x.length-1])+step2, 0]]))
        .attr('stroke', '#d2d2d2')
        .attr('stroke-width', '0.5px')
    )

  _customizeXAxis: ->
    @chart.selectAll('g.x-axis .domain').remove()
    ticks = @chart.selectAll('g.x-axis g.tick text')
    ticks.each((tick) ->
      tickEle = d3.select(this)
      tickEle.style('font-family', "'Open Sans Condensed', sans-serif")
        .style('font-weight', '700')
        .style('font-size', '12px')
        .attr('fill', '#777777')
        .style("text-anchor", "end")
        .attr("dx", "-.8em")
        .attr("dy", ".15em")
        .attr("transform", "rotate(-65)");  
    )


  _drawAxes: ->
    xAxis = d3.axisBottom()
      .tickFormat(d3.timeFormat("%m-%Y")).scale(@scale.x)
    yAxis = d3.axisLeft().scale(@scale.y)
      .ticks(@domain.y[1])
      .tickFormat(d3.format('d'))
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    @_customizeYAxis()
    @_customizeXAxis()

  _drawBackground: () ->
    @chart.append('rect')
      .attr('x', @scale.x(@domain.x[0]) - (@scale.x.step()-@scale.x.bandwidth()))
      .attr('y', @scale.y(@domain.y[1]))
      .attr('width', @dimensions.width)
      .attr('height', @dimensions.height)
      .attr('fill', '#f1f1f1')

  _showTooltip: (data) ->
    console.log('tooltip data: ', data)
    event = d3.event
    @tooltip
      .style('left', event.pageX+'px')
      .style('top', event.pageY+'px')
      .style('display', 'block')
    date = @_loadMonthName(data.month_year)+' '+data.month_year.getFullYear()
    n_clients = data.n_clients + ' clients'
    currentItems = @tooltip
      .selectAll('.d3-tooltip__item')
      .data([date, n_clients])
    currentItems.exit().remove()
    newItems = currentItems.enter()
      .append('div')
      .attr('class', 'd3-tooltip__item d3-tooltip__label')
    items = newItems.merge(currentItems)
      .text((d) => d)
    @tooltip.transition()
      .duration(50)
      .style('opacity', 1)


  _removeTooltip: (data) ->
    @tooltip.transition()
      .duration(500)
      .style('opacity', 0)
      .on('end', () ->
        d3.select(@)
          .style('display', 'none')
      )

  _draw: (chart) ->
    chart.enter()
      .append('rect')
      .attr('class', 'bar')
      .attr('fill', '#091f2f')
      .attr('opacity', 0.8)
      .attr('x', (d) => @scale.x(d.month_year))
      .attr('y', (d) => @scale.y(d.n_clients))
      .attr('width', (d) => @scale.x.bandwidth())
      .attr('height', (d) => @scale.y(0) - @scale.y(d.n_clients))
      .on('mouseover', (d) => @_showTooltip(d))
      .on('mouseout', (d) => @_removeTooltip(d))

  draw: ->
    @_drawBackground()
    @_drawAxes()
    chart = @chart.selectAll('rect.bar')
      .data(@data)
    @_draw(chart)


class App.D3Chart.RRHOutcome extends App.D3Chart.Base
  constructor: (container_selector, data) ->
    # @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @margin = {top: 0, right: 0, bottom: 40, left: 0}
    @data = data
    super(container_selector, @margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    @tooltip = d3.select('#d3-tooltip')

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

  _showTooltip: (data) ->
    console.log('tooltip data: ', data)
    event = d3.event
    @tooltip
      .style('left', event.pageX+'px')
      .style('top', event.pageY+'px')
      .style('display', 'block')
    currentItems = @tooltip
      .selectAll('.d3-tooltip__item')
      .data([data.data.outcome, data.data.count+' clients'])
    currentItems.exit().remove()
    newItems = currentItems.enter()
      .append('div')
    items = newItems.merge(currentItems)
      .text((d) => d)
      .attr('class', (d, i) ->
        if i == 0
          'd3-tooltip__item'
        else
          'd3-tooltip__item d3-tooltip__label'
      ).append('div')
        .attr('class', 'd3-tooltip__swatch')
        .style('background-color', (d, i) =>
          console.log('d', d)
          console.log('i', i)
          if i == 0 then @scale.color(d) else 'transparent'  
        )
    @tooltip.transition()
      .duration(50)
      .style('opacity', 1)

  _removeTooltip: (data) ->
    @tooltip.transition()
      .duration(500)
      .style('opacity', 0)
      .on('end', () ->
        d3.select(@)
          .style('display', 'none')
      )

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
          .on('mouseover', (d) => @_showTooltip(d))
          .on('mouseout', (d) => @_removeTooltip(d))

class App.D3Chart.RRHDemographics extends App.D3Chart.Base
  constructor: (container_selector, data, allData) ->
    @margin = {top: 10, right: 0, bottom: 60, left: 30}
    @data = data
    @allData = allData
    console.log('demo graphics: ', @data)
    super(container_selector, @margin)

    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

    console.log('range', @range)
    console.log('domain', @domain)
    console.log('scale', @scale)

  _loadScale: ->
    {
      color: d3.scaleOrdinal().domain(@domain.color).range(@range.color),
      x: d3.scaleBand().domain(@domain.x).range(@range.x).padding(0.3),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y)
    }

  _loadDomain: ->
    test = d3.set(@allData.map((d) -> d.race))
    console.log(test)
    {
      x: @allData.map((d) -> d.race),
      y:[0, d3.max(@allData, (d) -> d.freq)],
      color: ['full-population', 'housed']
    }

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: ["#091f2f", "#288be4"]
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
        .attr('fill', (d) => @scale.color(d.type))
        .attr('x', (d) => 
          if(d.type == 'full-population')
            @scale.x(d.race)
          else
            @scale.x(d.race) + (@scale.x.bandwidth()/2)
        )
        .attr('y', (d) => @scale.y(d.freq))
        .attr('width', (d) => 
          @scale.x.bandwidth()/2
        )
        .attr('height', (d) => @scale.y(0) - @scale.y(d.freq))


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





