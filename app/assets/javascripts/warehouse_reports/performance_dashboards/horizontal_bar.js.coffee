#= require ./namespace

class App.WarehouseReports.PerformanceDashboards.HorizontalBar
  constructor: (@chart_selector, @columns, @categories, @options) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @padding = @options.padding || {}
    @_build_chart()

  _build_chart: () =>
    data = {
      columns: @columns
      type: 'bar'
      color: @_colors
      labels: true
      onclick: @_follow_link
    }
    @chart = bb.generate({
      data: data,
      bindto: @chart_selector,
      size:
        height: 800
      axis:
        rotated: true,
        y:
          outer: false
          tick:
            rotate: -35
            autorotate: true
        x:
          height: 100
          type: 'category',
          categories: @categories,
          outer: false
          tick:
            rotate: -35
            autorotate: true
            fit: true
            culling: false
      grid:
        y:
          show: true
      bar:
        width: 35
      padding:
        left: @padding.left || 150
        top: 0
        bottom: 40
    })

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#00918C', '#FFA600', ]
    if key in ['All']
      color = '#288BEE'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

  _follow_link: (d, element) =>
    return unless @options.follow_link == 'true'

    bucket_title = @chart.categories()[d.index]
    bucket = @options.sub_keys[bucket_title]
    # console.log(d, @chart, @chart.categories(), @options.sub_keys, @options.params, bucket_title, bucket)
    report = 'report'
    if @chart.data()[1].id == d.id
      report = 'comparison'
      # console.log(@options, @options.date_ranges.comparison.start_date)
      @options.params.options.start_date = @options.date_ranges.comparison.start_date
      @options.params.options.end_date = @options.date_ranges.comparison.end_date
    # If we clicked on a point, send us to the list of associated clients
    @options.params.options.report = report
    @options.params.options.sub_key = bucket
    # console.log(@options.params)

    url = @options.link_base + '?' + $.param(@options.params)
    # console.log(url)
    window.open url
