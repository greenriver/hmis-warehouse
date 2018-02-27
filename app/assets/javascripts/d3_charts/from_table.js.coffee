#= require ./namespace
#= require ./base

# data should be in the form 
class App.D3Chart.FromTable extends App.D3Chart.Base
  constructor: (container_selector, data_table_selector, attrs) ->
    margin = top: 20, right: 20, bottom: 40, left: 40
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