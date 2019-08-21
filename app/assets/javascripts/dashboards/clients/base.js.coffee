#= require ./namespace

class App.Dashboards.Clients.Base
  constructor: (@chart_selector, @data, @sub_population, @support_url, options={}) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @options = Object.assign({
      legend:
        show: true
        position: 'bottom'
      size:
        height: 200
    }, options)
    @_build_chart()

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

  _follow_link: (d, e) =>
    month = moment(@chart.categories()[d.index] + ' 1', 'MMM YYYY D')
    url = @support_url.replace('START_DATE', month.format('MMM DD, YYYY'))
    url = url.replace('END_DATE', month.endOf('month').format('MMM DD, YYYY'))
    window.open url
