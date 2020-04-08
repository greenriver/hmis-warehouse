#= require ./namespace

class App.WarehouseReports.PerformanceDashboards.HorizontalBar
  constructor: (@chart_selector, @columns, @categories) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_charts()


  _build_charts: () =>
    data = {
      columns: @columns,
      type: 'bar',
      color: @_colors,
      labels: true,
    }
    bb.generate({
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

