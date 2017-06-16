#= require ./namespace

class App.Census.Base
  constructor: (@url, @type, @start_date, @end_date, @options) ->
    @data = {}
    @charts = {}
    @width = @_width()
    @height = @_height()

  load: ->
    $.get @url, {start_date: @start_date, end_date: @end_date, type: @type}, (data) =>
      @data = data
      if Object.keys(data).length
        @_build_charts()
      else
        $('.jCharts').append("<h4 class='text-center'>No Records Found</h4>")
      $('.jLoading').remove()

  charts: ->
    @charts
    
  _build_charts: ->
    # Default chart options
    Chart.defaults.global.defaultFontSize = 10
    Chart.defaults.global.onClick = @_follow_link
    Chart.defaults.global.hover.onHover = @_process_hover
    Chart.defaults.global.title.position = 'top'
    Chart.defaults.global.legend.display = true
    Chart.defaults.global.legend.position = 'right'
    Chart.defaults.global.tooltips.bodyFontSize = 12
    Chart.defaults.global.tooltips.displayColors = false
    Chart.defaults.global.elements.point.hitRadius = 2
    Chart.defaults.global.elements.point.radius = 2
    Chart.defaults.global.animation.onComplete = @_animation_complete

    @_build_census()

  _individual_chart: (data, id, census_detail_slug, options) ->
    chart_id = "census-chart-#{id}" 
    $('.jCharts').append("<div class='row'><div class='col-sm-8'><h4 class='census__chart-title'>#{data.title.text}</h4></div><div class='col-sm-4 jChartDownloads'></div></div>")
    $('.jCharts').append("<canvas id='#{chart_id}' height='#{@height}' width='#{@width}' class='census-chart' data-project='#{census_detail_slug}'>")
    chart_canvas = $("\##{chart_id}")

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

    @charts[id] = new Chart chart_canvas, 
      type: 'scatter',
      data: data,
      options: options,
        
  # Override as necessary
  _follow_link: (event) =>
    chart = @charts[event.target.id.replace('census-chart-', '')]
    project = $(event.target).data('project')

    # If we clicked on a point, send us to the list of associated clients
    if point = chart.getElementAtEvent(event)[0]
      date = chart.config.data.datasets[point._datasetIndex].data[point._index].x
      params = {type: @type, date: date, project: project}
      url = @url.replace('date_range', 'details') + '?' + $.param(params)
      window.open url

  _process_hover: (event, item) =>
    if item.length
      $('.census-chart').css('cursor', 'pointer')
    else
      $('.census-chart').css('cursor', 'default')

  _format_tooltip_label: (tool_tip) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    if tool_tip.datasetIndex == 0
      tool_tip.label = [
        tool_tip.xLabel,
        date_string,
        "Client count: #{tool_tip.yLabel}"
      ]
    else
      tool_tip.label = [
        date_string,
        "Bed inventory: #{tool_tip.yLabel}"
      ]

  _animation_complete: (anim) ->
    return unless anim?
    return unless $(anim.chartInstance.chart.canvas).prev('.row').find('.jChartDownloads').is(':empty')
    image_url = anim.chartInstance.chart.canvas.toDataURL()
    datasets = anim.chartInstance.chart.config.data.datasets
    csv = []
    i = 1
    $.each datasets, (data) ->
      csv[0] ?= []
      csv[0][data * i] = 'Date'
      csv[0][(data * i) + 1] = datasets[data]['label']
      i++
      $.each datasets[data].data, (day) ->
        csv[day + 1] ?= []
        csv[day + 1][data * (i - 1)] = datasets[data].data[day]['x']
        csv[day + 1][(data * (i - 1)) + 1] = datasets[data].data[day]['y']

    csvString = csv.map((d) ->
      d.join()
    ).join('\n')
 
    data_url = 'data:attachment/csv;census.csv,' + encodeURIComponent(csvString)
    html = '<a href="' + image_url + '" target="_blank">Download Image</a>'
    html += '<br /><a href="' + data_url + '" target="_blank" download="census.csv">Download Data</a>'
    $(anim.chartInstance.chart.canvas).prev('.row').find('.jChartDownloads').html(html)

  _width: ->
    300

  _height: ->
    40
    
