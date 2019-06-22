#= require ./namespace

class App.WarehouseReports.Rrh.TimeChart
  constructor: (@chart_selector, @data) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    console.log @data
    @_build_chart()

  _build_chart: () =>
    data =
      x: 'x'
      color: @_colors
      columns: @data.data
    console.log data
    # @chart = bb.generate({
    #   data: data,
    #   axis:
    #     x:
    #       type: 'category'
    #       tick:
    #         culling:
    #           max: 8
    #     y:
    #       tick:
    #         count: 7
    #         format: d3.format(",.0f")
    #       padding: 0
    #       min: 0
    #   grid:
    #     x:
    #       show: true
    #       ticks: 4
    #     y:
    #       show: true
    #       ticks: 4
    #   legend:
    #     show: false
    #   size:
    #     height: 200
    #   bindto: @chart_selector
    # })

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#091f2f', '#fb4d42', '#288be4', '#d2d2d2' ]
    if key in ['Goal', 'Average', 'Target']
      color = 'rgb(228, 228, 228)'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

  # _follow_link: (d, e) =>
  #   month = moment(@chart.categories()[d.index] + ' 1', 'MMM YYYY D')
  #   url = @support_url.replace('START_DATE', month.format('MMM DD, YYYY'))
  #   url = url.replace('END_DATE', month.endOf('month').format('MMM DD, YYYY'))
  #   window.open url