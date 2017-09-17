#= require ./namespace
#= require ./stacked

class App.D3Chart.Claims
  constructor: (selector) ->
    @margin = {top: 0, right: 0, bottom: 60, left: 30}
    @keys = ['ip', 'emerg', 'respite', 'op', 'rx', 'other']
    @keyLabels = ['IP', 'Emerg', 'Respite', 'OP', 'Rx', 'Other']
    @colors = ['#002A45', '#2C9CFF', '#B9DEFF', '#32DEFF', '#008DA8', '#B9B098']
    
    @container = d3.select('#'+selector)
    @legendSelector = '.'+selector+'__legend'
    @legend = new App.D3Chart.StackedLegend(@legendSelector, @keyLabels, @colors)
    @charts = @container.selectAll('.'+selector+'__chart')
    @date = @container.select('.'+selector+'__dates')

    @scale = @_loadScale()
  
  _loadTickFormat: (id) ->
    if id == '#claims__amount_paid' 
      '$.2s'
    else
      '.2s'

  _loadScale: () ->
    keyLabel = (d) ->
      keyLabels = {ip: 'IP', emerg: 'Emerg', respite: 'Respite', op: 'OP', rx: 'Rx', other: 'Other'}
      keyLabels[d]
    {
      color: d3.scaleOrdinal().domain(@keys).range(@colors),
      keyLabel: keyLabel
    }

  _loadMonthName: (date) ->
    months = [
      "January", "February", "March",
      "April", "May", "June", "July",
      "August", "September", "October",
      "November", "December"
    ]
    months[date.getMonth()]

  _customizeLegend: () ->
    d3.select(@legendSelector)
      .selectAll('.ho-hint__swatch')
        .style('opacity', '0.6')

  draw: ->
    date = @date
    @legend.draw()
    @_customizeLegend()
    that = @
    @charts.each(() ->
      url = $(@).data('url')
      id = '#'+$(@).attr('id')
      $.get(url, (data) ->
        console.log(data)
        if date && data.length > 0
          dates = d3.extent(data, (d) -> 
            [year, month, day] = d.date.split('-')
            new Date(year, month-1, day)
          )
          date.text(' ('+that._loadMonthName(dates[0])+' '+dates[0].getFullYear()+' - '+that._loadMonthName(dates[1])+' '+dates[1].getFullYear()+') ')
          date = null  
        if data.length > 0
          attrs = {
            margin: that.margin, 
            keys: that.keys, 
            yTickFormat: that._loadTickFormat(id),
            colors: that.colors
          }
          chart = new App.D3Chart.ClaimsStackedBar(id, data, attrs)
          chart.draw()
        else
          d3.select(id)
            .style('height', 'auto')
            .append('p')
            .text('No Data')
              .style('text-align', 'center')
      )
    )


class App.D3Chart.ClaimsStackedBar extends App.D3Chart.VerticalStackedBar
  constructor: (container_selector, claims, attrs) ->  
    super(container_selector, attrs.margin, attrs.keys, 'date')
    @yTickFormat = attrs.yTickFormat
    @colors = attrs.colors
    @claims = @_loadClaims(claims)
    @domain = @_loadDomain()
    @range = @_loadRange()

    @scale = @_loadScale()
    @stackData = @claims.bars

  _loadClaims: (claims)->
    bars = claims.map((bar) => @_loadBar(bar))
    byYear = d3.nest()
      .key((d) -> d.date.getFullYear())
      .entries(bars)
    byDate = d3.nest()
      .key((d) -> d.date)
      .map(bars)
    {
      byYear: byYear,
      byDate: byDate,
      bars: bars
    }

  _loadBar: (bar) ->
    [year, month, day] = bar.date.split('-') 
    bar.date = new Date(year, month-1, day)
    bar

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: @colors
    }

  _loadDomain: -> 
    domain = {
      x: @claims.bars.map((claim) -> claim.date),
      y: [0, d3.max(@claims.bars, (d) -> d.total)], 
      color: @keys,
    }
    domain.year = {}
    @claims.byYear.forEach((year) =>
      months = d3.extent(year.values, (v) -> v.date)
      domain.year[year.key] = months
    )
    domain

  _loadYearAxesCenter: (months) ->
    start = months[0]
    end = months[1]+@scale.x.bandwidth()
    start + ((end - start)/2)

  _loadYearAxesPath: (year)->
    generateLine = d3.line()
    months = @domain.year[year.key].map((month) => @scale.x(month))
    y = @scale.y(0)
    x1 = (months[0]+(@scale.x.bandwidth()/2))
    x2 = (months[1]+(@scale.x.bandwidth()/2))
    y1 = y+25
    y2 = y+35
    d = generateLine([[x1, y1], [x1, y2], [x2, y2], [x2, y1]])


  _drawYearAxis: ->
    y = @scale.y(0)
    center = @_loadYearAxesCenter.bind(@)
    yearAxis = @chart.append('g')
      .attr('class', 'year-axis')
    @claims.byYear.forEach((year) =>
      months = @domain.year[year.key].map((month) => @scale.x(month))
      d = @_loadYearAxesPath(year)
      yearAxis.append('path')
        .attr('d', d)
        .attr('stroke-width', '1px')
        .attr('stroke', '#d2d2d2')
        .attr('fill', 'none')
      yearAxis.append('text')
        .text(year.key)
        .attr('x', center(months))
        .attr('y', y+50)
        .attr('fill', '#777777')
        .attr('text-anchor', 'middle')
        .style('font-size', '12px')
    )

  _customizeXaxis: ->
    @chart.selectAll('g.x-axis text').remove()
    @chart.selectAll('g.x-axis .domain').remove()
    ticks = @chart.selectAll('g.x-axis g.tick')
    tickR = @.scale.x.bandwidth()/2
    tickR = if tickR > 9 then 9 else tickR 
    ticks.each((tick) ->
      tickEle = d3.select(this)
      tickEle.selectAll('line').remove()
      tickEle.append('circle')
        .attr('cy', 14)
        .attr('cx', 0)
        .attr('r', tickR)
        .attr('fill', '#f1f1f1')
      tickEle.append('text')
        .text(tick.getMonth()+1)
        .attr('y', 10)
        .attr('x', 0)
        .attr('dy', '0.71em')
        .attr('text-anchor', 'middle')
        .style('font-family', "'Open Sans Condensed', sans-serif")
        .style('font-weight', '700')
        .style('font-size', '12px')
        .attr('fill', '#777777')
    )

  _customizeYaxis: ->
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
        .attr('x', 0)
        .style('font-family', "'Open Sans Condensed', sans-serif")
        .style('font-weight', '500')
        .style('font-size', '12px')
        .attr('fill', '#777777')
      tickEle.append('path')
        .attr('d', generateLine([[scale.x(domain.x[0]), 0], [scale.x(domain.x[domain.x.length-1])+scale.x.bandwidth(), 0]]))
        .attr('stroke', '#d2d2d2')
        .attr('stroke-width', '0.5px')
    )
  
  _drawAxes: ->
    xAxis = d3.axisBottom()
      .tickFormat((tick) -> 
        tick.getMonth()+1
      ).scale(@scale.x)
    yAxis = d3. axisLeft()
      .tickFormat(d3.format(@yTickFormat))
      .scale(@scale.y).ticks(5)
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    @_customizeXaxis()
    @_customizeYaxis()
    @_drawYearAxis()

  draw: ->
    @chart.append('rect')
      .attr('x', @scale.x(@domain.x[0]))
      .attr('y', @scale.y(@domain.y[1]))
      .attr('width', @scale.x(@domain.x[@domain.x.length-1]) - @scale.x(@domain.x[0]))
      .attr('height', @dimensions.height)
      .attr('fill', '#f1f1f1')
    @_drawAxes()
    super
    @chart.selectAll('g.bar rect')
      .attr('opacity', 0.6)

    
