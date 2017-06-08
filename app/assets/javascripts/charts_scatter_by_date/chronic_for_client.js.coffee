#= require ./namespace

class App.ChartsScatterByDate.ChronicForClient extends App.ChartsScatterByDate.Base
  constructor: (@element, @url, @start_date, @end_date) ->
    @data = {}
    @charts = {}
    @height = 100
    @width = 300

  load: ->
    $.get @url, (data) =>
      @data = data
      if Object.keys(data).length
        @_build_charts()
      else
        $(@element).append("<h4 class='text-center'>No Records Found</h4>")
      $(@element).find('.jLoading').remove()
  _build_chart: () ->
    id = 0
    scatter_data = $.map @data, (count,date) ->
      console.log date
      {x: date, y: count}
    data = {
      datasets: [{
          label: 'Chronic days',
          data: scatter_data
      }],
      title: {display: false, text: 'Counts by day'}
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
    @_individual_chart(data, id, options)

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    tool_tip.label = [
      date_string,
      "Chronic days: #{tool_tip.yLabel}"
    ]
