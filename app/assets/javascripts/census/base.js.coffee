#= require ./namespace

class App.Census.Base
  constructor: (@url, @type, @start_date, @end_date, @options) ->
    @data = {}
    @charts = {}
    @chart_data = {}
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
    
    @_build_census()

  _individual_chart: (data, id, census_detail_slug, options) ->
    chart_id = "census-chart-#{id}" 
    $('.jCharts').append("<div class='row'><div class='col-sm-8'><h4 class='census__chart-title'>#{data.title.text}</h4></div><div class='col-sm-4 jChartDownloads'></div></div><div id='#{chart_id}' class='jChart'></div>")

    console.log(data, id, census_detail_slug, options)
    x_axis = $.map data.datasets[0].data, (row) ->
      row['x']
    client_counts = $.map data.datasets[0].data, (row) ->
      row['y']
    inventory_counts = $.map data.datasets[1].data, (row) ->
      row['y']

    @chart_data[chart_id] = {}
    @chart_data[chart_id]['census_detail_slug'] = census_detail_slug
    @chart_data[chart_id]['yesterday_counts'] = {}
    $.map data.datasets[0].data, (row) =>
      @chart_data[chart_id]['yesterday_counts'][row['x']] = row['yesterday']

    x_axis.unshift('x')
    client_counts.unshift('clients')
    inventory_counts.unshift('inventory')

    chart = bb.generate
      data: 
        x: 'x'
        columns: [ x_axis, client_counts, inventory_counts]
        onclick: @_follow_link
      bindto: "\##{chart_id}"
      axis:
        x:
          type: "timeseries"
          tick:
            format: "%b %e, %Y"
        y: 
          min: 0
    @charts[chart_id] = chart

        
  # Override as necessary
  _follow_link: (d, element) =>
    chart_id = $(element).closest('.jChart').attr('id')
    chart = @charts[chart_id]
    date = d.x.toISOString().split('T')[0]
    yesterday = @chart_data[chart_id]['yesterday_counts'][date]
    change = d.value - yesterday
    project = @chart_data[chart_id]['census_detail_slug']

    # # If we clicked on a point, send us to the list of associated clients
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
    # Disable downloads
    return
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
    
