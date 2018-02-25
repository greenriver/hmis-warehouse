#= require ./namespace
#= require ./base

# data should be in the form 
class App.D3Chart.BarFromTable extends App.D3Chart.Base
  constructor: (container_selector, data_table_selector, attrs) ->
    margin = top: 20, right: 20, bottom: 0, left: 40
    super(container_selector, margin)
    @data = @_loadData(data_table_selector)

  _loadData: (data_table_selector)->
    table = $(data_table_selector)
    csv = @_tableToCsv(table)
    d3.csvParse csv

  _tableToCsv: (table) ->
    rows = table.find('tr')
    data = $.map rows, (row) ->
      $.map $(row).find('td,th'), (cell) ->
        $.trim $(cell).text()
      .join(',')
    .join('\r\n')

  draw: () ->
    console.log(@dimensions)
    width = @dimensions.width
    height = @dimensions.height
    x0 = d3.scaleBand()
      .rangeRound([0, width])
      .paddingInner(0.1)
    x1 = d3.scaleBand()
      .padding(0.05)
    y = d3.scaleLinear()
      .rangeRound([height, 0])
    z = d3.scaleOrdinal()
      .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"])
    @chart.append('g')
      .selectAll('g')
      .data(@data)
      .enter().append('g')
        .attr 'transform', (d)->
          'translate(' + x0(d.State) + ',0'
        .selectAll('rect')
        .data (d)=>
          @data.columns.slice(1).map (key)->
            key: key, value: d[key]
        .enter().append('rect')
        .attr 'x', (d)->
          x1(d.key)
        .attr 'y', (d)->
          y(d.value)
        .attr('width', x1.bandwidth())
        .attr 'height', (d)->
          height - y(d.value)
        .attr 'fill', (d)->
          z(d.key)