#= require ./namespace

class App.WarehouseReports.PerformanceDashboards.HorizontalBar
  constructor: (@chart_selector, options) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    if options?.remote == true
      @_observe()
    else
      @_build_chart()

  _build_chart: () =>
    if $(@chart_selector).length > 0
      @options = $(@chart_selector).data('chart').options
      @categories = $(@chart_selector).data('chart').categories
      @link_params = $(@chart_selector).data('chart').params

      @padding = @options.padding || {}
      @height = @options.height || 400
      data = {
        columns: $(@chart_selector).data('chart').columns
        type: 'bar'
        color: @_colors
        labels: true
        onclick: @_follow_link
      }
      @chart = bb.generate({
        data: data,
        bindto: @chart_selector,
        size:
          height: @height
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
          width: 30
        padding:
          left: @padding.left || 150
          top: 0
          bottom: 20
      })
    else
      console.log("#{@chart_selector} not found on page")

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
    return unless @options.follow_link == true

    bucket_title = @chart.categories()[d.index]
    bucket = @options.sub_keys[bucket_title]
    # console.log(d, @chart, @chart.categories(), @options.sub_keys, @options, bucket_title, bucket)
    # return
    # console.log(d, @chart.data(), bucket_title, bucket, @options)
    report = 'report'
    if @chart.data()[1]?.id == d.id
      @link_params.filters.start_date = @options.date_ranges.comparison.start_date
      @link_params.filters.end_date = @options.date_ranges.comparison.end_date
    else
      @link_params.filters.start_date = @options.date_ranges.report.start_date
      @link_params.filters.end_date = @options.date_ranges.report.end_date
    # If we clicked on a point, send us to the list of associated clients
    @link_params.filters.report = report
    if bucket?
      @link_params.filters.sub_key = bucket
    else
      @link_params.filters.sub_key = ''
    # console.log(@link_params, bucket)

    url = '/' + @options.link_base + '?' + $.param(@link_params)
    # console.log(url)
    window.open url

  _observe: =>
    @processed = []
    MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if MutationObserver
      (
        new MutationObserver (mutations) =>
          for mutation in mutations
            if $(mutation.target).data('complete') == 'true' && @_selector_exists() && @_selector_unprocessed()
              # console.log($(@chart_selector).data(), @chart_selector)
              @_build_chart()
              @processed.push @chart_selector
      ).observe(
        document.body
        childList: false
        subtree: true
        attributes: true
        attributeFilter: ['complete']
      )

  _selector_exists: =>
    $(@chart_selector).length > 0

  _selector_unprocessed: =>
    @chart_selector not in @processed