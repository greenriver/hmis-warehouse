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
    y: [0, d3.max(counts)],
    possible_x_values: Object.keys(@data[0]),
    series: $.map @data, (d) =>
      d[@data.columns[0]]


  _loadScale: ()=>
    x: d3.scaleBand().domain(@domain.x).rangeRound(@range.x).paddingInner(0.1),
    y: d3.scaleLinear().domain(@domain.y).rangeRound(@range.y),
    color: d3.scaleOrdinal().range(@range.color),
    padding: 5

  _loadRange: ->
    x: [0, @dimensions.width],
    y: [@dimensions.height, 0],
    color: ["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]

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
    bandwidth = @scale.x.bandwidth() / (@data.length * @data.columns.slice(1).length)
    
    @chart.append('g')
      .selectAll('g')
      .data(@data)
      .enter().append('g')
        .attr 'transform', (d)=> # move right bandwidth * series location
          series = d[@domain.possible_x_values[0]]
          offset = @domain.series.indexOf(series) * (bandwidth + @scale.padding)
          'translate(' + offset + ',0)'
        .selectAll('rect')
        .data (d)=>
          @data.columns.slice(1).map (key)=>
            key: key, value: d[key]
        .enter().append('rect')
        .attr 'x', (d)=>
          console.log d.key
          console.log @data.columns.slice(1)
          @scale.x(d.key)
        .attr 'y', (d)=>
          # console.log d.value
          @scale.y(d.value)
          10
        .attr('width', bandwidth)
        .attr 'height', (d)=>
          @scale.y(d.value)
          10
        .attr 'fill', (d)=>
          @scale.color(d.key)