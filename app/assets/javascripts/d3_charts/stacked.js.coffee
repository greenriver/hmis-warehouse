#= require ./namespace
#= require ./base

class App.D3Chart.StackedLegend 
  constructor: (selector, keys, colors) ->
    @legend = d3.select(selector)
    @keys = keys
    @keys_data = keys.slice().reverse()
    @colors = colors
    @scale = {
      color: d3.scaleOrdinal().domain(@keys).range(@colors)
    }

  draw: ->
    hints = @legend.selectAll('.ho-hint')
      .data(@keys_data)
      .enter()
      .append('div')
        .attr('class', 'ho-hint')
    hints.selectAll('div')
      .data((d) => [['color', @scale.color(d)], ['key', d]])
      .enter()
      .append('div')
        .attr('class', (d) =>
          if d[0] == 'key' then 'ho-hint__swatch-text' else 'ho-hint__swatch'
        )
        .style('background-color', (d) =>
          if d[0] == 'color' then d[1] else 'transparent'
        )
        .html((d) =>
          if d[0] == 'key' then ('<small>'+d[1]+'</small>') else ''
        )

class App.D3Chart.VerticalStackedBar extends App.D3Chart.Base
  constructor: (container_selector, margin, keys, xKey) ->
    super(container_selector, margin)
    @keys = keys
    @xKey = xKey

  _loadScale: ->
    {
      x: d3.scaleBand().domain(@domain.x).range(@range.x).padding(0.3),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y),
      color: d3.scaleOrdinal().domain(@domain.color).range(@range.color)
    }

  draw: ->
    stackGenerator = d3.stack()
      .keys(@keys)
      .order(d3.stackOrderNone)
      .offset(d3.stackOffsetNone)
    if @scale && @stackData 
      @chart.selectAll('g.bar')
        .data(stackGenerator(@stackData))
        .enter()
        .append('g')
          .attr('class','bar')
          .attr('fill', (d) => @scale.color(d.key))
          .selectAll('rect')
            .data((d) => d)
            .enter()
            .append('rect')
              .attr('x', (d) => @scale.x(d.data[@xKey]))
              .attr('y', (d) => @scale.y(d[1]))
              .attr('height', (d) => @scale.y(d[0]) - @scale.y(d[1]))
              .attr('width', (d) => @scale.x.bandwidth())
    else 
      console.log('Please add data & scale!')
