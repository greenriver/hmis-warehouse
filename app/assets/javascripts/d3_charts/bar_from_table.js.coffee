#= require ./namespace
#= require ./base

# data should be in the form 
class App.D3Chart.BarFromTable extends App.D3Chart.Base
  constructor: (container_selector, data_table_selector, attrs) ->
    margin = top: 20, right: 20, bottom: 40, left: 40
    super(container_selector, margin)
    @data = @_loadData(data_table_selector)
    @domain = @_loadDomain()
    @range = @_loadRange()
    @scale = @_loadScale()
    
  _loadData: (data_table_selector)->
    table = $(data_table_selector)
    csv = @_tableToCsv(table)
    d3.csvParse csv

  _loadDomain: ()=>
    counts = $.map @data, (d) =>
      @data.columns.slice(1).map (key)=>
        d[key] = +d[key]
    x: @data.columns.slice(1),
    y: [d3.max(counts), 0],
    possible_x_values: Object.keys(@data[0]),
    series: $.map @data, (d) =>
      d[@data.columns[0]]


  _loadScale: ()=>
    x: d3.scaleBand().domain(@domain.x).rangeRound(@range.x).paddingInner(0.1),
    y: d3.scaleLinear().domain(@domain.y).rangeRound(@range.y),
    color: d3.scaleLinear().domain([0,@domain.series.length]),
    padding: 2,
    bandwidth: @dimensions.width / (@data.length * @data.columns.length)

  _loadRange: ->
    x: [0, @dimensions.width],
    y: [@dimensions.height, 0],
    color: [0,1]

  _tableToCsv: (table) ->
    rows = table.find('tr')
    data = $.map rows, (row) ->
      $.map $(row).find('td,th'), (cell) ->
        $.trim $(cell).text()
      .join(',')
    .join('\r\n')
  
  _drawBarChart: () =>
    @chart.append('g')
      .selectAll('g')
      .data(@data)
      .enter().append('g')
        .attr 'transform', (d)=> # move right bandwidth * series location
          series = d[@domain.possible_x_values[0]]
          offset = @domain.series.indexOf(series) * (@scale.bandwidth + @scale.padding)
          'translate(' + offset + ',0)'
        .selectAll('rect')
        .data (d)=>
          series = d[@domain.possible_x_values[0]]
          @data.columns.slice(1).map (key)=>
            key: key, value: d[key], series: series
        .enter().append('rect')
        .attr 'x', (d)=>
          @scale.x(d.key)
        .attr 'y', (d)=>
          @dimensions.height - @scale.y(d.value)
        .attr('width', @scale.bandwidth)
        .attr 'height', (d)=>
          @dimensions.height - (@dimensions.height - @scale.y(d.value))
        .attr 'fill', (d)=>
          d3.interpolateRainbow(@scale.color(@domain.series.indexOf(d.series)))

  _drawAxes: =>
    xAxis = d3.axisBottom().scale(@scale.x)
    yAxis = d3.axisLeft().scale(@scale.y)
    
    @chart.append('g')
      # .attr('transform', 'translate(0, ' + @dimensions.height +')')
      .attr('transform', 'translate(0, 10)')
      .attr('class', 'x-axis')
      .call(xAxis)
 
    @chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis)
    
    # @_customizeYaxis()
    # @_customizeXaxis()

  _drawLegend: ()=>
    legend = @chart.append('g')
      .attr('font-family', "'Open Sans Condensed', sans-serif")
      .attr('font-size', '10px')
      .attr("text-anchor", "end")
    .selectAll("g")
    .data(@domain.series.slice().reverse())
    .enter().append("g")
      .attr "transform", (d, i) ->
        "translate(0," + i * 20 + ")"
    legend.append('rect')
      .attr "x", @dimensions.width - 19
      .attr "width", 19
      .attr "height", 19
      .attr "fill", (d)=>
        d3.interpolateRainbow(@scale.color(@domain.series.indexOf(d)))

    legend.append("text")
      .attr "x", @dimensions.width - 24
      .attr "y", 9.5
      .attr "dy", "0.32em"
      .text (d)->
        d

  draw: () ->
    @_drawBarChart()
    @_drawLegend()