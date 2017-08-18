#= require ./namespace

class App.ChartsScatterByDate.HousedStateForClient extends App.ChartsScatterByDate.Base
  constructor: (@element, @data, @start_date, @end_date) ->
    @charts = {}
    @height = 200
    @width = 300

  load: =>
    if Object.keys(@data).length
      @_build_charts()
    else
      $(@element).append("<h4 class='text-center'>No Housing Status Information on File</h4>")
    $(@element).find('.jLoading').remove()

  _build_chart: () ->
    id = 0
    scatter_data = $.map @data, (value, date) ->
      if value
        {x: date, y: 'Housed'}
      else
        {x: date, y: 'Not Housed'}

    point_colors = $.map @data, (value, _) ->
      if value
        '#2D767C'
      else
        '#773747'

    point_styles = $.map @data, (value, _) ->
      if value
        'triangle'
      else
        'rectRounded'
      
    data = {
      datasets: [{
          label: 'Housed Status',
          data: scatter_data,
          showLine: false,
          pointRadius: 6,
          pointHoverRadius: 6,
          pointBackgroundColor: point_colors,
          pointBorderColor: point_colors,
          pointStyle: point_styles,
      }],
      title: 
        display: false, 
        text: 'Housed Status'
      yLabels: ['', 'Housed', 'Not Housed', '']

    }

    options = 
      scales:
        yAxes: [
          type: 'category'
          position: 'left'
          display: true
        ],
      tooltips: 
        callbacks: 
          label: @_format_tooltip_label
      title:
        display: true
        text: 'Housing Status'
        fontSize: 17
        fontFamily: "'Open Sans Condensed', sans-serif"
        fontColor: '#404040'

    @_individual_chart(data, id, options)

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    tool_tip.label = [
      date_string
    ]
