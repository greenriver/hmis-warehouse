class App.D3Chart.SelfSufficiencyScores extends App.D3Chart.Base
  constructor: (container_selector, margin, data) ->
    super(container_selector, margin)
    # @data = data
    @data = []
    @data = data.map((bars) ->
      scores = bars.scores.reduce((a, b) ->
        if b[0] != 'Total'
          a.push(b)
        return a
      , [])
      bars.scores = scores
      return bars
    )
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    
    @background_data = @domain.y.map((y) ->
      {y: y, low: 2, med: 2, high: 1}
    )
    console.log(@background_data)

  _loadYDomain: () ->
    all_labels = []
    score_labels = @data.map((d) -> 
      d.scores.map((score) -> score[0])
    ).forEach((sl) ->
      all_labels = all_labels.concat(sl)
    )
    uniq_labels = all_labels.reduce((a, b) -> 
      if a.indexOf(b) < 0 && b != 'Total' 
        a.push(b)
      return a
    , [])
    console.log(uniq_labels)
    return uniq_labels


  _loadDomain: () ->
    {
      x: [0, 5],
      y: @_loadYDomain(),
      fill: [0, 1, 2, 3],
      bg_fill: [0, 2, 4]
    }

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      fill: ['red', 'blue', 'orange', 'purple'],
      bg_fill: ['#949697', '#D3D5D7', '#EAEAEA']
    }

  _loadScale: ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y).paddingInner(0.2),
      fill: d3.scaleOrdinal().domain(@domain.fill).range(@range.fill),
      bg_fill: d3.scaleOrdinal().domain(@domain.bg_fill).range(@range.bg_fill)
    }

  _drawAxis: ->
    xAxis = d3.axisBottom().scale(@scale.x)
      .ticks(@domain.x[1], d3.format("d"))
    yAxis = d3.axisLeft().scale(@scale.y)
    @chart.append('g')
      .attr('transform', 'translate(0,'+@dimensions.height+')')
      .call(xAxis)
    @chart.append('g').call(yAxis)

  draw: ->
    @_drawAxis()

    stack = d3.stack()
      .keys(['low', 'med', 'high'])
      .order(d3.stackOrderNone)
      .offset(d3.stackOffsetNone)

    @chart.selectAll('g.ss-bg-bar')
      .data(stack(@background_data))
      .enter()
      .append('g')
        .attr('class', 'ss-bg-bar')
        .selectAll('rect')
          .data((d) -> d)
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(d[0]))
            .attr('y', (d) => 
              console.log(d)
              @scale.y(d.data.y)
            )
            .attr('height', (d) => @scale.y.bandwidth())
            .attr('width', (d) => @scale.x(d[1])-@scale.x(d[0]))
            .attr('fill', (d) => @scale.bg_fill(d[0]))
    
    parents = []
    @chart.selectAll('g.ss-bars')
      .data(@data)
      .enter()
      .append('g')
        .attr('class', (d, i) =>'ss-bars ss-bars-'+i)
        .selectAll('rect')
          .data((d, i, j) -> parents = j; return d.scores)
          .enter()
          .append('rect')
            .attr('x', (d, i, j) => @scale.x(0))
            .attr('y', (d, i, j) =>
              pi = parents.indexOf(j[i].parentNode)
              @scale.y(d[0]) + (pi*(@scale.y.bandwidth()/4.0))
            )
            .attr('height', (d) => @scale.y.bandwidth()/4.0)
            .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
            .attr('fill', (d, i, j) => 
              pi = parents.indexOf(j[i].parentNode)
              @scale.fill(pi)
            )

    # @chart.selectAll('rect')
    #   .data(@data[0].scores)
    #   .enter()
    #   .append('rect')
    #     .attr('x', (d) => 
    #       console.log('Score: '+d[1])
    #       console.log(@scale.x(d[1]))
    #       @scale.x(0)
    #     )
    #     .attr('y', (d) =>
    #       console.log('Category: '+d[0]) 
    #       @scale.y(d[0])
    #     )
    #     .attr('height', (d) => @scale.y.bandwidth()/3.0)
    #     .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
    #     .attr('fill', 'red')

    # @chart.selectAll('rect')
    #   .data(@data[1].scores)
    #   .enter()
    #   .append('rect')
    #     .attr('x', (d) => 
    #       console.log('Score: '+d[1])
    #       console.log(@scale.x(d[1]))
    #       @scale.x(0)+@scale.y.bandwidth()/3.0
    #     )
    #     .attr('y', (d) =>
    #       console.log('Category: '+d[0]) 
    #       @scale.y(d[0])
    #     )
    #     .attr('height', (d) => @scale.y.bandwidth()/3.0)
    #     .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
    #     .attr('fill', 'blue')





