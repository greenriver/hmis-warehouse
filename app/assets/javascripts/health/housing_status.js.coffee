#= require ./namespace

class App.Health.HousingStatus
  constructor: (@chart_selector, @data, @options={}) ->
    @color_map = {}
    @next_color = 0
    @_build_charts()


  _build_charts: () =>
    data = {
      x: 'x',
      columns: @data,
      onclick: @_follow_link
      onover: @_set_pointer_cursor
      onout: @_set_default_cursor
      type: 'bar',
      color: @_colors,
      labels: true,
    }
    @chart = bb.generate({
      data: data,
      bindto: @chart_selector,
      axis: {
        rotated: true,
        x: {
          type: 'category',
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

    # Override as necessary
  _follow_link: (d, element) =>
    return unless @options.link?

    params = { filter: @options.params }
    params.filter.status = @chart.x()[d.x]
    url = @options.link + '?' + $.param(params)
    window.open url

  _set_pointer_cursor: (event, item) =>
    $(@chart_selector).css('cursor', 'pointer')

  _set_default_cursor: (event, item) =>
    $(@chart_selector).css('cursor', 'default')

