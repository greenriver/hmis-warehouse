#= require ./namespace

class App.WarehouseReports.Rrh.Time
  constructor: (@chart_selector, @data, @support_url) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @_build_chart()

  _build_chart: () =>
    @chart = bb.generate({
      data:
        x: 'x'
        columns: @data.data
        color: @_colors
        onclick: @_follow_link
      tooltip:
        contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
          @_toolip(d, defaultTitleFormat, defaultValueFormat, color)
      axis:
        x:
          type: 'category'
          tick:
            culling:
              max: 8
        y:
          tick:
            count: 7
            format: d3.format(",.0f")
          padding: 0
          min: @_calc_min(@data.data)
      grid:
        x:
          show: true
          ticks: 4
        y:
          show: true
          ticks: 4
      legend:
        show: true
        position: 'right'
      size:
        height: 200
      bindto: @chart_selector
    })

  # Enforce a maximum of 0 as the minimum, but allow it to drop below 0.
  _calc_min: (data) =>
    # Deep clone so we don't mess up the data array
    d = JSON.parse(JSON.stringify(data));
    d = [].concat.apply([], d)

    # Throw out all non-numeric values
    d = d.filter (el)->
      !isNaN(parseFloat(el)) && isFinite(el)
    # ensure we have a 0
    d.push(0)
    d.reduce (a,b) -> Math.min a, b

  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    # console.log(d, defaultValueFormat(d[0].value), @data)
    tooltip_title = defaultTitleFormat(d[0].x)
    html = "<table class='bb-tooltip'>"
    html += "<thead>"
    html += "<tr><th colspan='4'>#{tooltip_title}</th></tr>"
    html += "<tr><th>Project</th><th>Average Days</th><th>Client Count</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]

      if row?
        bg_color = color(row.id)
        html += "<tr class='bb-tooltip-name-#{@chart.internal.getTargetSelectorSuffix(row.id)}'>"
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value}</td>"
        client_count = @data.support[tooltip_title][row.id].count
        count = "<td>#{client_count}</td>"
        html += box
        html += value
        html += count
        html += "</tr>"

    html += "</tbody>"
    html += '</table>'
    html

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


  _follow_link: (d, e) =>
    # if d.name != 'All'
    month = @data.labels[d.index + 1]
    url = @support_url + encodeURI("&selected_project=#{d.name}&month=#{month}")
    # console.log(d, @data, url, month)

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)
