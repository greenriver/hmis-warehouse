#= require ./namespace
#= require ./stacked

class App.D3Chart.ClaimsStackedBar extends App.D3Chart.VerticalStackedBar
  constructor: (container_selector, margin, keys, claims) ->
    super(container_selector, margin, keys, 'date')
    @claims = @_loadClaims(claims)
    @domain = @_loadDomain()
    @range = @_loadRange()
    console.log(@domain)
    console.log(@range)

    @scale = @_loadScale()
    console.log(@scale)
    @stackData = @claims.bars

  _loadClaims: (claims)->
    bars = claims.map((bar) => @_loadBar(bar))
    byYear = d3.nest()
      .key((d) -> d.date.getFullYear())
      .map(bars)
    byMonth = d3.nest()
      .key((d) -> d.date)
      .map(bars)
    {
      byYear: byYear,
      byDate: byMonth,
      bars: bars
    }

  _loadBar: (bar) ->
    [year, month, day] = bar.date.split('-') 
    bar.date = new Date(year, month-1, day)
    bar

  # _loadScale: ->
  #   super

  _loadRange: ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0],
      color: ['#002A45', '#2C9CFF', '#B9DEFF', '#32DEFF', '#008DA8', '#B9B098']
    }

  _loadDomain: -> 
    max = d3.max(@claims.bars, (d) =>
      values = @keys.map((key) -> d[key])
      values.reduce((value, currentValue) -> value + currentValue)
    )
    if max > 100 
      max = Math.ceil(max/100)*100
    {
      x: @claims.bars.map((claim) -> claim.date),
      y: [0, max],
      color: @keys,
    }

  draw: ->
    super



# // class d3Chart.ClaimsStackedBar extends d3Chart.VerticalStackedBar {
# //   constructor(container_selector, margin, keys) {
# //     super(container_selector, margin, keys, 'date')
# //     this.claims = new ClaimsData(container_selector)

# //     this.domain = this.loadDomain()
# //     this.range = this.loadRange()
# //     this.scale = this.loadScale()

# //     this.stackData = this.claims.bars()
# //     this.tooltipData = this.claims.byMonth()
# //     this.tooltip = this.drawTooltip()
# //   }
# // }



# // class ClaimsStackedBar extends VerticalStackedBar {
# //   constructor(container_selector, margin, keys, claims) {
# //     super(container_selector, margin, keys, 'date')
# //     // var data = new ClaimData(keys, claims)
# //     // this.claims = data.loadClaims()
# //     this.claims = claims
# //     this.domain = this.loadDomain()
# //     this.range = this.loadRange()
# //     this.scale = this.loadScale()

# //     this.stackData = this.claims.byMonth
# //   }

# //   draw() {
# //     this.drawAxes()
# //     super.draw()
# //   }

# //   loadYearAxesCenter(months) {
# //     var start = months[0]
# //     var end = months[1]+this.scale.x.bandwidth()
# //     return start + ((end - start)/2)
# //   }

# //   drawAxes() {
# //     var chart = this.chart
# //     var scale = this.scale
# //     var margin = this.margin
# //     var line = d3.line()
# //     var xAxis = d3.axisBottom().tickFormat(function(tick) {return tick.getMonth()+1}).scale(scale.x)
# //     var yAxis = d3. axisLeft().scale(scale.y).ticks(5)
# //     chart.append('g')
# //       .attr('transform', 'translate(0,'+this.dimensions.height+')')
# //       .attr('class', 'x-axis')
# //       .call(xAxis)
# //     chart.append('g')
# //       .call(yAxis)
# //     var center = this.loadYearAxesCenter.bind(this)
# //     this.claims.byYear.forEach(function(year) {
# //       var all = year.value.map(function(d) {return +d.key})
# //       var months = d3.extent(all).map(function(month) {
# //         return scale.x(new Date(year.key, month-1))
# //       })
# //       var y = scale.y(0)
# //       var d = line([
# //         [months[0], y],
# //         [months[0], y+35],
# //         [months[1]+scale.x.bandwidth(), y+35],
# //         [months[1]+scale.x.bandwidth(), y]
# //       ])
# //       var yearAxis = chart.append('g')
# //         .attr('class', 'year-axis')
# //       yearAxis.append('path')
# //         .attr('d', d)
# //         .attr('stroke-width', '1px')
# //         .attr('stroke', '#cccccc')
# //         .attr('fill', 'none')
# //       yearAxis.append('text')
# //         .text(year.key)
# //         .attr('x', center(months))
# //         .attr('y', y+55)
# //         .attr('fill', '#cccccc')
# //         .attr('text-anchor', 'middle')
# //     })
    
# //   }

# //   loadDomain() {
# //     var keys = this.keys
# //     var max = d3.max(this.claims.byMonth, function(d) {
# //       var values = keys.map(function(key) {return d[key]})
# //       return values.reduce(function(value, currentValue) {return value + currentValue})
# //     })
# //     if(max > 100) {
# //       max = Math.ceil(max/100)*100
# //     }
# //     return {
# //       x: this.claims.byMonth.map(function(claim) {return claim.date}),
# //       y: [0, max],
# //       color: this.keys,
# //     }
# //   }

# //   loadRange() {
# //     return {
# //       x: [0, this.dimensions.width],
# //       y: [this.dimensions.height, 0],
# //       color: ['#002A45', '#2C9CFF', '#B9DEFF', '#32DEFF', '#008DA8', '#B9B098']
# //     }
# //   }
# // }