#= require ./namespace

class App.Health.EdIpVisits
  constructor: (@chart_selector, @url) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_chart()


  _build_chart: () =>
    @chart = bb.generate({
      data:
        url: @url
        groups: [
          [
            'ED Visits',
            'IP Visits',
          ]
        ],
        mimeType: 'json'
        color: @_colors
        types:
          'ED Visits': 'area'
          'IP Visits': 'area'
        x: 'x'
      axis:
        x:
          type: 'timeseries'
          tick:
            format: "%b %Y"
        y:
          tick:
            format: (x) ->
              if x % 1 == 0
                x
              else
                ''
          label:
            text: 'Encounters'
            position: 'outer-middle'
          culling: true

      size:
        height: 200
      bindto: @chart_selector
    })

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#091f2f', '#fb4d42', '#288be4', '#d2d2d2' ]
    if key in ['All']
      color = '#288BEE'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

