class App.D3Chart.InitiativeBarBase extends App.D3Chart.Base
  
  constructor: (container_selector, legend_selector, margin, data) ->
    console.log('initiative bar Base')
    @data = data
    @container_selector = container_selector
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

  _resizeContainer: ()->
    container = d3.select(@container_selector)
    height = @data.types.length * 50
    container.node().style.height = height+'px'

  _loadDomain: () ->
    domain = {
      x: [0, d3.max(@data.values)],
      y: @data.types,
      rainbowFill: [0,@data.types.length+1]
    }
    console.log(domain)
    domain

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0]
    }

  _loadScale: () ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y)
      # rainbowFill: d3.scaleSequential().domain(@domain.rainbowFill).interpolator(d3.interpolateRainbow)
      rainbowFill: d3.scaleSequential().domain(@domain.rainbowFill).interpolator(d3.interpolateRainbow)
      # y: d3.scaleBand().domain(@domain.y).range(@range.y).paddingInner(0.2)
    }

  _drawAxis: () ->
    xAxis = d3.axisBottom().scale(@scale.x)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+@dimensions.height+')')
      .call(xAxis)

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
        # .attr('fill', (d) => '#f1f1f1')

  _drawBarContainer: () ->
    @chart.selectAll('rect.bar-container')
      .data(@data.types)
      .enter()
      .append('rect')
        .attr('class', 'bar-container')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d)+@labelHeight)
        .attr('height', (d) => @containerHeight)
        .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
        .attr('stroke', '#D2D2D2')
        .attr('fill', 'rgba(255,255,255,0.5)')
        .attr('stroke-width', '1px')

  _drawTypeLabels: () ->
    @chart.selectAll('text.mm-bars-label')
      .data(@data.types)
      .enter()
      .append('text')
        .attr('class', 'mm-bars-label')
        .attr('x', (d) => @scale.x(0)+3)
        .attr('y', (d) => @scale.y(d)+@labelHeight-8)
        .attr('style', (d) => 'font-size: 12px;')
        .text((d) => d)

  draw: () ->
    @_drawAxis()
    @_drawBackgroundBars()
    @_drawBarContainer()
    @_drawTypeLabels()


class App.D3Chart.InitiativeBar extends App.D3Chart.InitiativeBarBase
  
  constructor: (container_selector, legend_selector, margin, data) ->
    console.log('initiative bar')
    super(container_selector, legend_selector, margin, data)
    @labelHeight = 26
    @barHeight = (@scale.y.bandwidth()-@labelHeight)
    @containerHeight = @barHeight

  draw: () ->
    super
    @_drawBars({classes: 'bar', data: @data.data})
    @_drawValues()


  _drawValues: () ->
    @chart.selectAll('text.bar-value')
      .data(@data.data)
      .enter()
      .append('text')
        .text((d) => d[1])
        .attr('class', 'bar-value')
        .attr('x', (d) => @scale.x(d[1])+5)
        .attr('y', (d, i, j) => 
          @scale.y(d[0])+@labelHeight+@barHeight
        )
        .attr('fill', (d) =>
          # index = @data.types.indexOf(d[0])
          # @scale.rainbowFill(index)
          '#333333'
        )
        .attr('dy', '-'+(@barHeight/4)+'px')
        .attr('style','font-weight:bold;')


  _drawBars: (opts) ->
    @chart.selectAll('rect.bar')
      .data(opts.data)
      .enter()
      .append('rect')
        .attr('class', 'bar')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => 
          @scale.y(d[0]) + @labelHeight
        )
        .attr('height', (d) => @barHeight)
        .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
        .attr('fill', (d) =>
          # index = @data.types.indexOf(d[0])
          # @scale.rainbowFill(index)
          '#00549E'
        )

class App.D3Chart.InitiativeStackedBar extends App.D3Chart.InitiativeBarBase

  constructor: (container_selector, legend_selector, margin, data) ->
    super(container_selector, legend_selector, margin, data)
    @labelHeight = 26
    @barHeight = (@scale.y.bandwidth()-@labelHeight)
    @containerHeight = @barHeight
    @stackKeys = @data.keys||[]
    @range.color = @data.colors||['red', 'blue', 'green', 'purple', 'yellow', 'pink']
    @domain.color = @stackKeys
    @scale.color = d3.scaleOrdinal().domain(@domain.color).range(@range.color)

  _drawBars: () ->
    stackGenerator = d3.stack()
      .keys(@stackKeys)
      .order(d3.stackOrderNone)
      .offset(d3.stackOffsetNone)
    console.log('data')
    console.log(@data)
    # console.log(@data.data)
    console.log('stack data')
    console.log(stackGenerator(@data.data))
    @chart.selectAll('g.gb-bar')
      .data(stackGenerator(@data.data))
      .enter()
      .append('g')
        .attr('class', 'gb-bar')
        # .attr('fill', (d, i) => if i == 0 then '#F6C9CA' else '#96ADD4')
        .attr('fill', (d) => @scale.color(d.key))
        .selectAll('rect')
          .data((d) => d)
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(d[0]))
            .attr('y', (d) => @scale.y(d.data.type) + @labelHeight)
            .attr('width', (d) => @scale.x(d[1])-@scale.x(d[0]))
            .attr('height', (d) => @barHeight)

  draw: () ->
    super
    @_drawBars()



