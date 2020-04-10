#= require ./namespace

class App.WarehouseReports.PerformanceDashboards.HorizontalBar
  constructor: (@chart_selector, @columns, @categories, @options) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
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
      axis: {
        rotated: true,
        x: {
          type: 'category',
          categories: @categories,
        }
      }
    })

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#51ACFF', '#45789C', ]
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

    chart_id = $(element).closest('.jChart').attr('id')
    bucket_title = @chart.categories()[d.index]
    bucket = @options.sub_keys[bucket_title]
    # console.log(d, @chart, @chart.groups())
    # If we clicked on a point, send us to the list of associated clients
    params =
      options:
        key: @options.key
        sub_key: bucket
        breakdown: @options.breakdown

    url = @options.link_base + '?' + $.param(params)
    # window.open url