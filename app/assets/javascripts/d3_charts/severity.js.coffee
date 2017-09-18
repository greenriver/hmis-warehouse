#= require ./namespace
#= require ./stacked

class App.D3Chart.Severity extends App.D3Chart.VerticalStackedBar
  constructor: (container_selector, claims, attrs) ->
    # @styleTooltip = @_styleTooltip
    super(container_selector, attrs.margin, attrs.keys, 'group')
    @keyLabels = attrs.keys.slice()
    @keyLabels[3] = "Emerg, not prev/ avoid (ED Visits that did not result in IP Admissions"
    @legend = new App.D3Chart.StackedLegend(attrs.legend, @keyLabels, attrs.colors)
    @claims = @_loadClaims(claims)
    @colors = attrs.colors
    @range = @_loadRange()
    @domain = @_loadDomain()

    @scale = @_loadScale()
    @scale.xColor = d3.scaleOrdinal().domain(@domain.xColor).range(@range.xColor)
    @scale.icon = d3.scaleOrdinal().domain(@domain.icon).range(@range.icon)
    @stackData = @claims

  _showTooltip: (data) ->
    keys = @keys.slice().reverse()
    keys.unshift('group')
    labels = ['group']
    super(data, keys, labels)
    @tooltip.selectAll('.d3-tooltip__item')
      .append('span')
      .text((d) =>
        if d == 'group' then data[d] else Math.round(data[d])+'%'
      )
    @_positionTooltip()

  _loadClaims: (claims)->
    result = []
    claims.forEach((claim) =>
      group = if claim.group == 'SDH Pilot' then claim.group else 'Current Patient'
      r = {group: group}
      @keys.forEach((key) =>
        r[key] = claim[key]*100
      )
      result.push(r)
    )
    result

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: @colors,
      xColor: ['#00549E', '#777777'],
      icon: ['icon-user', 'icon-users']
    }

  _loadDomain: ->
    labels = ['Current Patient', 'SDH Pilot']
    {
      x: @claims.map((claim) -> claim.group),
      y: [0, 100],
      color: @keys,
      xColor: labels,
      icon: labels
    }

  _styleAxisText: ->
    @chart.selectAll('g.tick text')
      .attr('fill', '#777777')
      .style('font-family', "'Open Sans Condensed', sans-serif")
      .style('font-size', '12px')


  _customizeYaxis: ->
    generateLine = d3.line()
    @chart.selectAll('g.y-axis__right .domain').remove()
    @chart.selectAll('g.y-axis__right .tick:first-child text').remove()
    @chart.selectAll('g.y-axis__right g.tick line').remove()
    
    @chart.selectAll('g.y-axis .domain').remove()
    @chart.selectAll('g.y-axis .tick:first-child text').remove()
    ticks = @chart.selectAll('g.y-axis g.tick')
    that = @
    step = @scale.x.step()
    width = @scale.x.bandwidth()
    x1 = @scale.x('Current Patient') - (step-width) + 5
    x22 = @scale.x('SDH Pilot') + (width+(step-width)) - 5 
    ticks.each((tick) ->
      tickEle = d3.select(this)
      tickEle.selectAll('line').remove()
      tickEle.selectAll('text')
        .attr('x', 0)
      tickEle.append('path')
        .attr('d', generateLine([[x1, 0], [x22, 0]]))
        .attr('stroke', '#d2d2d2')
        .attr('stroke-width', '0.5px')
    )

  _customizeXaxis: ->
    @chart.selectAll('g.x-axis .domain').remove()
    ticks = @chart.selectAll('g.x-axis g.tick line').remove()
    ticks = @chart.selectAll('.x-axis')
      .selectAll('.tick')
    @container.selectAll('i')
      .data(ticks.nodes())
      .enter()
      .append('i')
        .attr('class', (tick) =>
          text = d3.select(tick).select('text').text()
          @scale.icon(text)
        )
        .style('position', 'absolute')
        .style('bottom', '0px')
        .style('font-size', '30px')
        .style('color', (tick) =>
          text = d3.select(tick).select('text').text()
          @scale.xColor(text)
        )
        .style('left', (tick) =>
          translate = +d3.select(tick).attr('transform').split(',')[0].replace('translate(', '')
          translate + @margin.left - 15 + 'px'
        )
    ticks.remove()

  _drawAxes: ->
    xAxis = d3.axisBottom().scale(@scale.x)
    yAxis = d3.axisLeft().scale(@scale.y).ticks(5).tickFormat((d) => d+'%')
    yAxisRight = d3.axisRight().scale(@scale.y).ticks(5).tickFormat((d) => d+'%')
    @chart.append('g')
      .attr('transform', 'translate(0, '+@dimensions.height+')')
      .attr('class', 'x-axis')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    @chart.append('g')
      .attr('transform', 'translate('+(@dimensions.width-8)+', 0)')
      .attr('class', 'y-axis__right')
      .call(yAxisRight)
    @_customizeYaxis()
    @_customizeXaxis()

  _drawConnectors: ->
    stackGenerator = d3.stack()
      .keys(this.keys)
      .order(d3.stackOrderNone)
      .offset(d3.stackOffsetNone)
    lineGenerator = d3.line()
    connectorSize = 2
    @chart.selectAll('path.connect')
      .data(stackGenerator(@stackData))
      .enter()
      .append('path')
        .attr('class', 'connect')
        .attr('d', (d, i) =>
          if (@scale.y(d[0][0])-@scale.y(d[0][1])) >= connectorSize
            x1 = @scale.x(d[0].data.group) + @scale.x.bandwidth()
            x2 = @scale.x(d[1].data.group)
            y1 = @scale.y(d[0][1])
            y2 = @scale.y(d[1][1])
            line = [[x1-0.5, y1+connectorSize], [x2+0.5, y2+connectorSize]]
            lineGenerator(line)
          else
            ''
        )
        .attr('stroke-width',connectorSize+'px')
        .attr('stroke', (d) => @scale.color(d.key))
        .attr('fill', 'none')

  _styleTooltip: ->
    # custom styles for tooltips go here

  draw: ->
    @_drawAxes()
    @_styleAxisText()
    super
    @_drawConnectors()
    @legend.draw()




