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

    @chart_data[chart_id] = {}
    @chart_data[chart_id]['title'] = data.title.text
    @chart_data[chart_id]['census_detail_slug'] = census_detail_slug
    
    columns = []

    x_axis = $.map data.datasets[0].data, (row) ->
      row['x']
    x_axis.unshift('x')
    columns.push(x_axis)

    $(data.datasets).each (i) => 
      @chart_data[chart_id][i] = {}
      column = $.map data.datasets[i].data, (row) ->
        row['y']
      column.unshift(data.datasets[i].label)
      columns.push(column)
      if data.datasets[i].data[0].yesterday?
        @chart_data[chart_id][i]['yesterday_counts'] = {}
        $.map data.datasets[i].data, (row) =>
          @chart_data[chart_id][i]['yesterday_counts'][row['x']] = row['yesterday']

    chart = bb.generate
      data: 
        x: 'x'
        columns: columns
        onclick: @_follow_link
      bindto: "\##{chart_id}"
      axis:
        x:
          type: "timeseries"
          tick:
            format: "%b %e, %Y"
        y: 
          min: 0
      grid:
        y:
          show: true
      tooltip: 
          contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
            @_tooltip_contents(chart_id, d, defaultTitleFormat, defaultValueFormat, color)
    @charts[chart_id] = chart

        
  _tooltip_contents: (chart_id, d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here: 
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    chart = @charts[chart_id]
    date = d[0].x.toISOString().split('T')[0]
    tooltip_title = moment(date).format('ll')
    html = "<table class='#{chart.internal.CLASS.tooltip}'><tr><th colspan='4'>#{tooltip_title}</th></tr>"
    $(d).each (i) =>
      row = d[i]
      bg_color = color(row.id)
      html += "<tr class='#{chart.internal.CLASS.tooltipName}#{chart.internal.getTargetSelectorSuffix(row.id)}'>"
      box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
      value = "<td>#{row.value}</td>"
      html += box
      html += value
      if @chart_data[chart_id][i]['yesterday_counts']?
        yesterday = @chart_data[chart_id][i]['yesterday_counts'][date]
        change = row.value - yesterday
        # html += '<tr>'
        if change > 0
          bg_color = '#006600'
          polygon = "<path d='M 5,0.5 9.5,9.75 0.5,9.75 z' style='fill:#{bg_color}; stroke:#{bg_color}' />"
        else if change == 0
          bg_color = '#000000'
          polygon = "<rect width='10' height='10' style='fill:#{bg_color}' ></polygon>"
        else
          bg_color = '#990000'
          polygon = "<path d='M 0.5,0.5 9.75,0.5 5,9.75 z' style='fill:#{bg_color}; stroke:#{bg_color}' />"
        box = "<td class='name'><svg>#{polygon}</svg>change</td>"
        value = "<td>#{change}</td></tr>"
        html += box
        html += value
      # html += '</tr>'
      else
        html += '<td></td><td></td>'

    html += '</table>'
    html

  # Override as necessary
  _follow_link: (d, element) =>
    chart_id = $(element).closest('.jChart').attr('id')
    date = d.x.toISOString().split('T')[0]
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
    
