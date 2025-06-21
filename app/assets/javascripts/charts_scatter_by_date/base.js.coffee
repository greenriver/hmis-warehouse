#= require ./namespace

class App.ChartsScatterByDate.Base
  constructor: (@url, @start_date, @end_date, @current_date) ->
    @data = {}
    @charts = {}
    @element = $('.jCharts')
    @height = 60
    @width = 300

  load: ->
    $.get @url, {range: {start: @start_date, end: @end_date}}, (data) =>
      @data = data
      if Object.keys(data).length
        @_build_charts()
      else
        @element.append("<h4 class='text-center'>No Records Found</h4>")
      $('.jLoading').remove()
  _build_charts: ->
    @_build_chart()

  _individual_chart: (data, id, options) ->
    chart_id = "chart-chart-#{id}"
    @element.append("<div id='#{chart_id}' class='chart-chart'>")

    default_options =
      bindto: "##{chart_id}"
      size:
        height: @height
      data: data
      axis:
        x:
          type: 'timeseries'
          min: new Date(@start_date)
          max: new Date(@end_date)
          tick:
            fit: true
        y:
          padding: { bottom: 0 }
          min: 0
      legend:
        show: false
      point:
        r: 2

    final_options = $.extend(true, default_options, options)
    @charts[id] = window.bb.generate(final_options)

  # Override as necessary
  _follow_link: (d) =>
    return

  _format_tooltip_contents: (d) =>
    return unless d && d.length > 0

    point = d[0]
    date = point.x
    date_string = new Date(date.getTime() + (date.getTimezoneOffset() * 60000)).toDateString()
    value = point.value

    html = """
      <table class="bb-tooltip">
        <tbody>
          <tr><td class="name">#{date_string}</td></tr>
          <tr><td class="name">#{point.name}: #{value}</td></tr>
        </tbody>
      </table>
    """
    return html


  _process_hover: (d) =>
    return

  _process_hover_out: (d) =>
    return
