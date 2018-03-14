class App.D3Chart.InitiativeStackedBar extends App.D3Chart.Base
  
  constructor: (container_selector, legend_selector, margin, data) ->
    @data = data
    console.log(@data)
    @container_selector = container_selector
    @margin = margin
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

  _resizeContainer: ()->
    @labelHeight = 22
    @barHeight = 12
    container = d3.select(@container_selector)
    # height = @data.types.length * ((@data.types.length*14)+@labelHeight) + @margin.top + @margin.bottom
    height = @data.keys.length * ((@data.types.length*@barHeight)+@labelHeight) + @margin.top + @margin.bottom
    container.node().style.height = height+'px'

  _loadDomain: () ->
    domain = {
      x: [0, d3.max(@data.values)],
      y: @data.keys,
      rainbowFill: [0, @data.types.length]
    }
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
      rainbowFill: d3.scaleSequential().domain(@domain.rainbowFill).interpolator(d3.interpolateRainbow)
    }

  _drawAxis: () ->
    xAxisTop = d3.axisTop()
      .scale(@scale.x)
      .ticks(@domain.x[1])
      .tickFormat(d3.format(",d"))
    xAxisBottom = d3.axisBottom()
      .scale(@scale.x)
      .ticks(@domain.x[1])
      .tickFormat(d3.format(",d"))
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,-1)')
      .call(xAxisTop)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+(@dimensions.height+1)+')')
      .call(xAxisBottom)

  _groupData: (d, i) ->
    data = []
    Object.keys(d).forEach((x) =>
      if x != 'type'
        data.push([x, d[x]])
    )
    data.type = d.type
    data.index = i
    data

  _transformGroup: (d, i) ->
    t = if i == 0 then @labelHeight else (@labelHeight + (@barHeight*i))
    'translate(0,'+t+')'
  
  _drawOutlines: () ->
    @chart.selectAll('g.outlines')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'outlines')
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
            .attr('height', (d) => @barHeight)
            .attr('stroke', '#d2d2d2')
            .attr('stroke-width', '1px')
            .attr('fill', '#ffffff')

  _drawBars: () ->
    @chart.selectAll('g.bars')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'bars')
        .attr('fill', (d) => @scale.rainbowFill(@data.types.indexOf(d.type)))
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
            .attr('height', (d) => @barHeight)

  _drawValues: () ->
    @chart.selectAll('g.values')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'values')
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('text')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('text')
            .attr('x', (d) => @scale.x(d[1])+3)
            .attr('y', (d) => @scale.y(d[0])+(@barHeight/2))
            .attr('style', 'font-size:10px;')
            .attr('alignment-baseline', 'central')
            .text((d) => d[1])

  _drawMarker: () ->
    @chart.selectAll('g.markers')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'markers')
        .attr('fill', (d) => @scale.rainbowFill(@data.types.indexOf(d.type)))
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('rect')
            .attr('transform', 'translate(-'+(@barHeight/2)+', 0)')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @barHeight/2)
            .attr('height', (d) => @barHeight)          

  _drawLabels: () ->
    @chart.selectAll('text.label')
      .data(@data.keys)
      .enter()
      .append('text')
        .attr('class', 'label')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d))
        .attr('transform', (d, i) => 'translate(0,'+(@labelHeight/2)+')')
        .attr('alignment-baseline', 'central')
        .text((d) => d)

  _drawBands: () ->
    @chart.selectAll('rect.band')
      .data(@data.keys)
      .enter()
      .append('rect')
        .attr('class', 'band')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d))
        .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
        .attr('height', (d) => @scale.y.bandwidth())
        .attr('fill', '#f2f2f2')  

  draw: () ->
    @_drawBands()
    @_drawAxis()
    @_drawLabels()
    @_drawMarker()
    @_drawOutlines()
    @_drawBars()
    @_drawValues()


class App.D3Chart.InitiativeBarBase extends App.D3Chart.Base
  
  constructor: (container_selector, legend_selector, margin, data) ->
    @data = data
    @container_selector = container_selector
    @margin = margin
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    

  _resizeContainer: ()->
    @labelHeight = 26

    container = d3.select(@container_selector)
    height = @data.types.length * ((@stackKeys.length*14)+@labelHeight) + @margin.top + @margin.bottom
    container.node().style.height = height+'px'

  _loadDomain: () ->
    domain = {
      x: [0, d3.max(@data.values)],
      y: @data.types,
      rainbowFill: [0,@data.types.length+1]
    }
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
    xAxis = d3.axisBottom().scale(@scale.x).tickFormat(d3.format(",d"))
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
    @stackKeys = [1]
    super(container_selector, legend_selector, margin, data)
    @labelHeight = 26
    @barHeight = (@scale.y.bandwidth()-@labelHeight)
    @containerHeight = @barHeight

  draw: () ->
    super
    @_drawBars({classes: 'bar', data: @data.data})
    @_drawValues()


  _drawValues: () ->
    barHeight = @barHeight
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
        # .attr('dy', '-'+(@barHeight/4)+'px')
        .attr('dy', (d) ->
          n = d3.select(this).node().getBBox()
          x = (n.height - barHeight)/4
          console.log(x)
          '-'+x+'px'
        )
        .attr('font-size', '12px')
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

# class App.D3Chart.InitiativeStackedBar extends App.D3Chart.InitiativeBarBase

#   constructor: (container_selector, legend_selector, margin, data) ->

#     @stackKeys = data.keys||[]
#     @colors = data.colors||['red', 'blue', 'green', 'purple', 'yellow', 'pink']
#     super(container_selector, legend_selector, margin, data)
    
#     @containerHeight = (@scale.y.bandwidth()-@labelHeight)
#     @barHeight = @containerHeight/@stackKeys.length
#     # console.log(@barHeight)
#     @range.color = @colors
#     # @range.color = ['#d73027', '#1a9850']
#     @domain.color = @stackKeys
#     @scale.color = d3.scaleOrdinal().domain(@domain.color).range(@range.color)
#     # d3.schemePaired
#     # @scale.color = d3.scaleOrdinal().domain(@domain.color).range(d3.schemePastel1)
#     if legend_selector
#       @legend = new App.D3Chart.StackedLegend(legend_selector, @stackKeys, @colors)

#   _drawBars: () ->
#     stackGenerator = d3.stack()
#       .keys(@stackKeys)
#       .order(d3.stackOrderNone)
#       .offset(d3.stackOffsetNone)
#     @chart.selectAll('g.gb-bar')
#       .data(stackGenerator(@data.data))
#       .enter()
#       .append('g')
#         .attr('class', 'gb-bar')
#         .attr('fill', (d) => @scale.color(d.key))
#         .selectAll('rect')
#           .data((d) =>
#             d.forEach((x) -> 
#               x['index'] = d.index
#               x['key'] = d.key
#             )
#             d
#           )
#           .enter()
#           .append('rect')
#             .attr('x', (d) => @scale.x(0))
#             .attr('y', (d) => 
#               @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)
#             )
#             .attr('width', (d) => 
#               return(@scale.x(d.data[d.key])-@scale.x(0))
#             )
#             .attr('height', (d) => @barHeight)

#   _drawMarkers: () ->
#     lineGenerator = d3.line()
#     stackGenerator = d3.stack()
#       .keys(@stackKeys)
#       .order(d3.stackOrderNone)
#       .offset(d3.stackOffsetNone)
#     @chart.selectAll('g.marker-container')
#       .data(stackGenerator(@data.data))
#       .enter()
#       .append('g')
#         .attr('class', 'marker-container')
#         .attr('fill', (d) => @scale.color(d.key))
#         .selectAll('path')
#         .data((d) =>
#           d.forEach((x) -> 
#             x['index'] = d.index
#             x['key'] = d.key
#           )
#           d
#         )
#         .enter()
#         .append('path')
#           .attr('d', (d) =>
#             p1 = [@scale.x(0), @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)]
#             p2 = [@scale.x(0), @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)+@barHeight]
#             p3 = [@scale.x(0)-@barHeight+4, @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)+(@barHeight/2)]
#             p4 = [@scale.x(0), @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)]
#             lineGenerator([p1, p2, p3, p4])
#           )
#           .attr('storke', (d) => @scale.color(d.key))
#           .attr('stroke-width', '1px')
#         # .enter()
#         # .selectAll('circle')
#         # .data((d) =>
#         #   d.forEach((x) -> 
#         #     x['index'] = d.index
#         #     x['key'] = d.key
#         #   )
#         #   d
#         # )
#         # .enter()
#         # .append('circle')
#         #   .attr('cx', (d) => 
#         #     @scale.x(0)
#         #   )
#         #   .attr('cy', (d) =>
#         #     @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)+(@barHeight/2)
#         #   )
#         #   .attr('r', (d) =>
#         #     @barHeight/3
#         #   )
#         # .selectAll('rect')
#         #   .data((d) =>
#         #     d.forEach((x) -> 
#         #       x['index'] = d.index
#         #       x['key'] = d.key
#         #     )
#         #     d
#         #   )
#         #   .enter()
#         #   .append('rect')
#         #     .attr('x', (d) => @scale.x(0)-(@barHeight+2))
#         #     .attr('y', (d) => @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index))
#         #     .attr('width', (d) => @barHeight)
#         #     .attr('height', (d) => @barHeight)

#   _drawValues: () ->
#     barHeight = @barHeight
#     stackGenerator = d3.stack()
#       .keys(@stackKeys)
#       .order(d3.stackOrderNone)
#       .offset(d3.stackOffsetNone)
#     @chart.selectAll('g.bar-value-container')
#       .data(stackGenerator(@data.data))
#       .enter()
#       .append('g')
#         .attr('class', 'bar-value-container')
#         .selectAll('text')
#           .data((d) => 
#             d.forEach((x) -> 
#               x['index'] = d.index+1
#               x['key'] = d.key
#             )
#             d
#           )
#           .enter()
#           .append('text')
#             .attr('x', (d) => @scale.x(d.data[d.key])+5)
#             .attr('y', (d) => @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)-(@barHeight/2))
#             .attr('font-size', '12px')
#             .attr('alignment-baseline', 'central')
#             .text((d) => d.data[d.key])
  
#   _drawContainers: () ->
#     barHeight = @barHeight
#     stackGenerator = d3.stack()
#       .keys(@stackKeys)
#       .order(d3.stackOrderNone)
#       .offset(d3.stackOffsetNone)
#     @chart.selectAll('g.bar-containers')
#       .data(stackGenerator(@data.data))
#       .enter()
#       .append('g')
#         .attr('class', 'bar-containers')
#         .selectAll('rect')
#           .data((d) => 
#             d.forEach((x) -> 
#               x['index'] = d.index
#               x['key'] = d.key
#             )
#             d
#           )
#           .enter()
#           .append('rect')
#             .attr('x', (d) => @scale.x(0))
#             .attr('y', (d) => 
#               @scale.y(d.data.type)+@labelHeight+(@barHeight*d.index)
#             )
#             .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
#             .attr('height', (d) => @barHeight)
#             .attr('fill', '#FFFFFF')
#             .attr('stroke', '#d2d2d2')
#             .attr('stroke-width', '1px')



#   draw: () ->
#     super
#     @_drawContainers()
#     @_drawBars()
#     @_drawMarkers()
#     @_drawValues()
#     if @legend
#       @legend.draw()



