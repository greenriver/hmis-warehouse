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
    # Default chart options
    Chart.defaults.global.defaultFontSize = 10
    Chart.defaults.global.title.position = 'top'
    Chart.defaults.global.legend.display = false
    Chart.defaults.global.hover.onHover = @_process_hover
    # Chart.defaults.global.legend.position = 'right'
    Chart.defaults.global.tooltips.bodyFontSize = 12
    Chart.defaults.global.tooltips.displayColors = false
    Chart.defaults.global.elements.point.hitRadius = 2
    Chart.defaults.global.elements.point.radius = 2
    Chart.defaults.global.onClick = @_follow_link

    @_build_chart()

  _individual_chart: (data, id, options) ->
    chart_id = "chart-chart-#{id}" 
    @element.append("<canvas id='#{chart_id}' height='#{@height}' width='#{@width}' class='chart-chart'>")
    chart_canvas = $("\##{chart_id}")
    console.log(options)
    default_options = 
      bezierCurve: false,
      scales: 
        xAxes: [
          type: 'time',
          time:
            minUnit: 'day'
            min: @start_date,
            max: @end_date,
        ],
        yAxes: [
          ticks: 
            beginAtZero: true
        ],
    options = $.extend(options, default_options)
    console.log(options)
    @charts[id] = new Chart chart_canvas, 
      type: 'scatter',
      data: data,
      options: options,

  # Override as necessary
  _follow_link: (event) =>
    event.preventDefault()

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    tool_tip.label = [
      date_string,
      "Client count: #{tool_tip.yLabel}"
    ]

  _process_hover: (event, item) =>
    return