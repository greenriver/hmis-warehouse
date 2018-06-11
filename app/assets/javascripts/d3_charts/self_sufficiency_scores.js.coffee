class App.D3Chart.SelfSufficiencyScores extends App.D3Chart.Base
  constructor: (container_selector, legend_selector, margin, data) ->
    super(container_selector, margin)
    @data = @_loadData(data)
    if @data.length == 0
      return
    @scores = [0..5]
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    @barHeight = @scale.y.bandwidth()/@domain.bar_count
    @background_data = @domain.y.map((y) ->
      {y: y, low: 2, med: 2, high: 1}
    )
    @legend = new App.D3Chart.StackedLegend(legend_selector, @_loadLegendLabels(), @range.fill.slice(0, @data.length).reverse())

  _loadData: (data) ->
    data.map((d, i) ->
      d.id = i
      return d
    )

  _formatDate: (date) ->
    month = date.getMonth()+1
    month = if month > 9 then month else '0'+month
    day = date.getDate()
    day = if day > 9 then day else '0'+day
    year = date.getFullYear()
    month+'/'+day+'/'+year  

  _loadLegendLabels: () ->
    legend_labels = @data.map((d) =>
      date = new Date(d.collected_at)
      @_formatDate(date) + ' ' + d.collection_location + '<br/>' + '(total score: '+d.total+')'
    ).slice().reverse()

  _loadDomain: () ->
    domain = {
      x: [0, 5],
      y: @data[0].scores.map((d) -> d[0]),
      fill: @data.map((d) -> d.id),
      bg_fill: [0, 2, 4],
      bar_count: @data.length,
    }
    domain['xAxisY'] = [domain.y[0], domain.y[domain.y.length-1]]
    domain

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      fill: ['#002A45', '#2C9CFF', '#B9DEFF', '#32DEFF'],
      bg_fill: ['#949697', '#D3D5D7', '#EAEAEA']
    }

  _loadScale: ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y).paddingInner(0.2),
      fill: d3.scaleOrdinal().domain(@domain.fill).range(@range.fill),
      bg_fill: d3.scaleOrdinal().domain(@domain.bg_fill).range(@range.bg_fill)
    }

  _customizeYAxis: ->
    axis = @chart.selectAll('g.yAxis')
    axis.selectAll('path').remove()

  _customizeXAxis: ->
    axis = @chart.selectAll('g.xAxis')
    axis.selectAll('path').remove()
    axis.selectAll('line').remove()
    axis.selectAll('g.tick').each((d) ->
      tick = d3.select(this)
      text = tick.selectAll('text')
      text.attr('stroke', '#777777')
    )

  _drawAxis: ->
    xAxis = d3.axisBottom().scale(@scale.x)
      .ticks(@domain.x[1], d3.format("d"))
    yAxis = d3.axisLeft().scale(@scale.y)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+@dimensions.height+')')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0, -'+@margin.top+')')
      .call(xAxis)
    @_customizeXAxis()
    @chart.append('g')
      .attr('class', 'yAxis')
      .call(yAxis)
    @_customizeYAxis()

  _drawBackgroundBars: ->
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
            .attr('y', (d) => @scale.y(d.data.y))
            .attr('height', (d) => @scale.y.bandwidth())
            .attr('width', (d) => @scale.x(d[1])-@scale.x(d[0]))
            .attr('fill', (d) => @scale.bg_fill(d[0]))
            .attr('opacity', '0.7')

  _drawBars: ->
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
              # pi = parents.indexOf(j[i].parentNode)
              pi = j[i].parentNode.__data__.id
              @scale.y(d[0]) + (pi*@barHeight)
            )
            .attr('height', (d) => @barHeight)
            .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
            .attr('fill', (d, i, j) => @scale.fill(j[i].parentNode.__data__.id))
            .attr('opacity', 0.7)


  draw: ->
    if @data.length == 0
      return
    @_drawAxis()
    @_drawBackgroundBars()
    @_drawBars()
    @legend.draw()

    
    
    






