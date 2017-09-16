#= require ./namespace
class App.D3Chart.TopBarCharts
  constructor: (chartIds, legendSelector=null, drawLegend=false) ->
    @chartIds = chartIds
    if legendSelector
      @legend = d3.select(legendSelector)
    @drawLegend = drawLegend

  _drawLegend: (chart, types) ->
    keyClass = 'd3-top-leged-pc__key'
    labels = {all: 'All Participants', patient: 'Current Patient'}
    @legend.selectAll(keyClass)
      .data(types)
      .enter()
      .append('div')
        .attr('class', keyClass)
        .text((d) => labels[d])
        .append('div')
          .attr('class', 'ho-chart__swatch')
          .style('background-color', (d) => chart.scale.color(d))


  draw: () ->
    legend = @legend
    drawLegend = @drawLegend
    @chartIds.forEach((id) =>
      that = @
      url = $(id).data('url')
      yAttr = $(id).data('yattr')
      yLabel = $(id).data('ylabel')
      mainType = $(id).data('maintype')
      $.get(url, (data) ->
        if data.length > 0
          chart = new App.D3Chart.TopBar(id, data, yAttr, yLabel, mainType)
          chart.draw()
          if drawLegend && legend
            drawLegend = false
            that._drawLegend(chart, ['patient', 'all'])            
        else
          d3.select(id)
            .style('height', 'auto')
            .style('border-right', 'none')
            .style('margin-top', '0px')
            .append('p')
              .text('No Data')
      )
    )
    

class App.D3Chart.TopBar
  constructor: (container_selector, data, yAttr, yLabel, mainType) ->
    @attrs = {all: 'sdh_pct', patient: 'indiv_pct'}
    @mainType = mainType
    @subType = if mainType == 'patient' then 'all'
    @yAttr = yAttr
    @yLabel = yLabel
    @data = data
    @_loadBarData()
    @container = d3.select(container_selector)
    @chart = @container
    @margin = {top: 0, right: 0, bottom: 0, left: 0}
    @dimensions = @_loadDimensions()
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()

  _loadBarData: () -> 
    @data.forEach((d) =>
      mainAttr = @attrs[@mainType]
      subAttr = @attrs[@subType]
      d.pct = [
        {type: @mainType, value: d[mainAttr]}
      ]
      if @subType
        d.pct.push({type: @subType, value: d[subAttr]})
    )

  _loadDimensions: () ->
    cBox = @container.node().getBoundingClientRect()
    width = cBox.width
    height = cBox.height
    {
      width: width - @margin.left - @margin.right,
      height: height - @margin.top - @margin.bottom,
      chartWidth: width,
      chartHeight: height,
      chartTransform: 'translate('+@margin.left+','+@margin.top+')'
    }

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      height: 20,
      color: ['#008DA8', '#00549E']
    }

  _loadXDomain: () ->
    type = @mainType
    total = @data.map((v) =>
      Math.round(v[@attrs[type]]*100)
    ).reduce((total, v) ->
      total + v
    )/100
    [0, total] 

  _loadDomain: () ->
    {
      x: @_loadXDomain(),
      y: @data.map((bar) => bar[@yAttr]),
      height: 1,
      color: ['all', 'patient']
    }

  _loadScale: () ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      height: @range.height/@domain.height,
      index: (d) =>
        @domain.y.indexOf(d[@yAttr]) + 1
      yContainerClass: (d) =>
        if d.key == 'index'
          'd3-top__key-number'
        else
          'd3-top__key-text'
      yText: (d) =>
        if d.key == 'index'
          @domain.y.indexOf(d.data[@yAttr]) + 1
        else
          d.data[@yAttr]
      color: d3.scaleOrdinal().domain(@domain.color).range(@range.color)
    }

  _drawBars: () ->
    @chart.selectAll('.d3-top__key-bar')
      .selectAll('.d3-top__bar')
      .data((d) -> [d])
      .enter()
      .append('div')
        .attr('class', 'd3-top__bar')
      .selectAll('.d3-top__bar-inner')
        .data((d) -> d.pct)
        .enter()
        .append('div')
          .attr('class', 'd3-top__bar-inner')
          .style('width', (d) => @scale.x(d.value)+'px')
          .style('height', (d) => @scale.height+'px')
          .style('background-color', (d) => @scale.color(d.type))
          .append('span')
            .text((d) => Math.round(d.value*100)+'%')

  _drawKeyBars: () ->
    @chart.selectAll('.d3-top__key-bar')
      .data(@data)
      .enter()
      .append('div')
        .attr('class', 'd3-top__key-bar')
  
  _drawKeys: () ->
    @chart
      .selectAll('.d3-top__key-bar')
      .selectAll('.d3-top__key')
        .data((d) -> [d])
        .enter()
        .append('div')
          .attr('class', 'd3-top__key')
        .selectAll('div')
          .data((d) -> [{key: 'index', data: d}, {key: 'text', data: d}])
          .enter()
          .append('div')
            .attr('class', (d) => @scale.yContainerClass(d))
            .text((d) => @scale.yText(d))
 
  draw: () ->
    xAxis = @chart.append('div')
      .attr('class', 'x-axis')
    xAxis.append('span')
      .attr('class', 'x-axis__max')
      .style('color', @scale.color(@mainType))
      .text(Math.ceil(@domain.x[1]*100)+'%')
    xAxis.append('span').text(@yLabel)
    @_drawKeyBars()
    @_drawKeys()
    @_drawBars()

