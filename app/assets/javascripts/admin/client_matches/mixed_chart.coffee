#= require ./namespace

class App.Admin.ClientMatches.MixedChart
  constructor: (@chart_selector, options) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_chart()

  _build_chart: () =>
    if $(@chart_selector).length > 0
      @padding = {}
      @height = 200
      data = {
        x: 'x'
        columns: $(@chart_selector).data('chart').columns
        type: 'spline'
        color: @_colors
        labels: true
      }
      @chart = bb.generate({
        data: data,
        bindto: @chart_selector,
        size:
          height: @height
        padding:
          top: 0
          bottom: 20
        axis:
          x:
            label:
              text: 'Score'
              position: 'outer-right'
            tick:
              culling:
                max: 5
          y:
            padding:
              bottom: 0
            min: 0
            label:
              text: 'Match Count'
              position: 'outer-middle'
            tick:
              culling:
                max: 5
        legend:
          show: false
        spline:
          interpolation:
            type: 'monotone-x'
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

