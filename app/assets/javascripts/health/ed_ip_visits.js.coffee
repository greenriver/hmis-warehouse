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
                values: @_ticks(json_data)
                format: (x) ->
                  Math.round(x)
              label:
                text: 'Encounters'
                position: 'outer-middle'
          grid:
            y:
              show: false
          regions: @_y_regions(json_data)
          size:
            height: 200
          bindto: selector
        })

  _max_value: (data) ->
    Math.max.apply(Math, data['Emergency'].concat(data['Inpatient']))

  _ticks: (data) =>
    [1..@_max_value(data)]

  _y_regions: (data) =>
    @_ticks(data).map (d) ->
      odd = if d % 2
        'even'
      else
        'odd'
      axis: 'y'
      start: d-1
      end: d
      class: "bb-region-y-#{odd}"


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

