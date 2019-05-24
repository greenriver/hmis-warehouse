#= require ./namespace

class App.DataQualityReports.Base
  constructor: (@data, @chart_selector, @support_url) ->
    @data = @_format_data(@data)
    @color_map = {}
    @next_color = 0

  build_chart: =>
    if @data['data']?
      @_build_chart()
    else
      $(@chart_selector + '.jChart').append ("<h4 class='text-center'>No Records Found</h4>")
    $('.jLoading').remove()

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

  _format_data: (data) ->
    data

  _follow_link: (d, element) =>
    # Do nothing by default
    # console.log(d, element, @support_url)


