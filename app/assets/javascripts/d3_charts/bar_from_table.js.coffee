#= require ./namespace
#= require ./base

# data should be in the form 
class App.D3Chart.BarFromTable extends App.D3Chart.Base
  constructor: (container_selector, data_table_selector, attrs) ->
    super(container_selector, 10)
    @data = @_loadData(data_table_selector)
    if @data.length > 0
      @range = @_loadRange()
      @domain = @_loadDomain()
      @scale = @_loadScale()
      @datesContainer = @container.selectAll(attrs.dates_container)

  _loadData: (data_table_selector)->
    table = $(data_table_selector)
    rows = table.find('tr')
    data = $.map rows, (row) ->
      $.map $(row).find('td,th'), (cell) ->
        $.trim $(cell).text()
      .join(',')
    .join('\r\n')
    console.log data
    #keys = Object.keys(data)
    []

  draw: () ->
    []