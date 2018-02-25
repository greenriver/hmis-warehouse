#= require ./namespace
#= require ./base

# data should be in the form 
class App.D3Chart.BarFromTable extends App.D3Chart.Base
  constructor: (container_selector, data_table_selector, attrs) ->
    margin = top: 20, right: 20, bottom: 0, left: 40
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
    color: d3.scaleLinear(d3.interpolateSpectral()).domain([0,@domain.series.length]),
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

  draw: () ->
    console.log(@domain)
    # console.log @data.keys()
    
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
          d3.interpolateSpectral(@scale.color(@domain.series.indexOf(d.series)))
