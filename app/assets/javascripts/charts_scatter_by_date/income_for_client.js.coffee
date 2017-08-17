#= require ./namespace

class App.ChartsScatterByDate.IncomeForClient extends App.ChartsScatterByDate.Base
  constructor: (@element, @data, @start_date, @end_date) ->
    @charts = {}
    @height = 200
    @width = 300

  load: =>
    if Object.keys(@data).length
      @_build_charts()
    else
      $(@element).append("<h4 class='text-center'>No Income Records On File</h4>")
    $(@element).find('.jLoading').remove()
  _build_chart: () ->
    id = 0
    scatter_data = $.map @data, (count,date) ->
      {x: date, y: count}
    data = {
      datasets: [{
          label: 'Total Monthly Income',
          data: scatter_data
      }],
      title: 
        display: false, 
        text: 'Income'
    }

    util = window.App.util.new
    for i of data.datasets
      hash = window.App.util.hashCode(data.title.text)
      color = window.App.util.intToRGB(hash + i * 200)
      data.datasets[i].borderColor = "\##{color}"
      data.datasets[i].backgroundColor = "transparent"
      data.datasets[i].lineTension = 0
      data.datasets[i].borderWidth = 1
    options =
      tooltips: 
        callbacks: 
          label: @_format_tooltip_label
      title:
        display: true
        text: 'Total Monthly Income'
        fontSize: 17
        fontFamily: "'Open Sans Condensed', sans-serif"
        fontColor: '#404040'
      scales:
        yAxes: [
          ticks: 
            callback: (label, index, labels) ->
              "$#{label}"
        ]
    @_individual_chart(data, id, options)

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    tool_tip.label = [
      date_string,
      "Total Monthly Income: #{tool_tip.yLabel}"
    ]
