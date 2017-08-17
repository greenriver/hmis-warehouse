#= require ./namespace

class App.ChartsScatterByDate.HousedStateForClient extends App.ChartsScatterByDate.Base
  constructor: (@element, @data, @start_date, @end_date) ->
    @charts = {}
    @height = 100
    @width = 300

  load: =>
    if Object.keys(@data).length
      @_build_charts()
    else
      $(@element).append("<h4 class='text-center'>No Records Found</h4>")
    $(@element).find('.jLoading').remove()

  _build_chart: () ->
    id = 0
    scatter_data = $.map @data, (_, date) ->
      {x: date, y: 1}
    point_colors = $.map @data, (value, _) ->
      if value
        '#2D767C'
      else
        '#773747'
      
    data = {
      datasets: [{
          label: 'Self-Sufficiency Matrix Scores',
          data: scatter_data,
          showLine: false,
          pointRadius: 10,
          pointBackgroundColor: point_colors,
          pointBorderColor: point_colors,
      }],
      title: 
        display: false, 
        text: 'Self-Sufficiency Matrix Scores'
    }

    options = 
      scales: 
        yAxes: [
          ticks: 
            display: false,
            min: 0,
            max: 2,
        ],
      tooltips: 
        callbacks: 
          label: @_format_tooltip_label
      title:
        display: true
        text: 'Housing Status'

    @_individual_chart(data, id, options)

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    tool_tip.label = [
      date_string
    ]
