#= require ./namespace

class App.Health.HousingStatus
  constructor: (@chart_selector, @data) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_charts()


  _build_charts: () =>
    console.log(@data)
    @data = {
      x: 'x',
      columns: [
        ['x', 'Permanent', 'Shelter', 'Doubled Up', 'Street', 'Temporary', 'Unknown'],
        ['Starting', 10, 20, 30, 1, 3, 5],
        ['Ending', 3, 4, 7, 2, 3, 9],
      ],
      type: 'bar',
    }
    bb.generate({
      data: @data,
      bindto: @chart_selector,
      axis: {
        x: {
          type: 'category',
        }
      }
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

