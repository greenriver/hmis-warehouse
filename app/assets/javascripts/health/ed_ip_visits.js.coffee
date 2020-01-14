#= require ./namespace

class App.Health.EdIpVisits
  constructor: (@chart_selector, @url) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_charts()


  _build_charts: () =>
    $.getJSON @url, (data) =>
      for year, json_data of data
        selector = @chart_selector+'-'+year
        $(@chart_selector).prepend("<div class='#{selector.replace('.', '')} mb-6' />")
        bb.generate({
          title:
            text: year
          data:
            json: json_data
            color: @_colors
            type: 'bar'
            x: 'x'
          point:
            show: false
          axis:
            x:
              type: 'timeseries'
              tick:
                format: "%B"
                culling: false
                rotate: 60
            y:
              tick:
                count: =>
                  max_value = Math.max.apply(Math, json_data['Emergency'].concat(json_data['Inpatient']))
                  if max_value % 2
                    max_value + 1
                  else
                    max_value + 2
                format: (x) ->
                  Math.round(x)
              label:
                text: 'Encounters'
                position: 'outer-middle'
          size:
            height: 200
          bindto: selector
        })

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#bb2716', '#00549e', '#bb2716', '#00549e' ]
    if key in ['All']
      color = '#288BEE'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

