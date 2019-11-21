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
            'Emergency',
            'Inpatient',
          ]
        ],
        mimeType: 'json'
        color: @_colors
        types:
          'Emergency': 'area'
          'Inpatient': 'area'
        x: 'x'
      point:
        show: false
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
    colors = [ '#9AABD9', '#7990C9', '#7990C9', '#9AABD9' ]
    if key in ['All']
      color = '#288BEE'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

