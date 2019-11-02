#= require ./namespace

class App.Dashboards.Clients.EntryReEntry extends App.Dashboards.Clients.Base
  constructor: (@chart_selector, @data, @sub_population, @entry_support_url, @re_entry_support_url, options) ->
    super(@chart_selector, @data, @sub_population, @entry_support_url, options)

  _build_chart: () =>
    data =
      x: 'x'
      onclick: @_follow_link
      color: @_colors
      columns: @data
    @chart = bb.generate({
      data: data,
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
          min: 0
      grid:
        x:
          show: true
          ticks: 4
        y:
          show: true
          ticks: 4
      tooltip:
        contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
          @_toolip(d, defaultTitleFormat, defaultValueFormat, color)
      legend:
        position: @options.legend.position
      size: @options.size
      bindto: @chart_selector
    })
  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    # console.log(d, defaultValueFormat(d[0].value), @data)
    tooltip_title = defaultTitleFormat(d[0].x)
    total_count = 0
    html = "<table class='bb-tooltip'>"
    html += "<thead>"
    html += "<tr><th colspan='2'>#{tooltip_title}</th></tr>"
    # html += "<tr><th>Percent</th><th>Clients</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]
      if row?
        total_count += row.value
        bg_color = color(row.id)
        html += "<tr class='bb-tooltip-name-#{@chart.internal.getTargetSelectorSuffix(row.id)}'>"
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value}</td>"
        html += box
        html += value
        html += "</tr>"
    html += "</tbody>"
    html += "<tfoot>"
    html += "<tr><th>Total</th><th>#{total_count}</th></tr>"
    html += "</tfoot>"
    html += '</table>'
    html

  _follow_link: (d, e) =>
    if d.name == 'New'
      url = @entry_support_url
    else if d.name == 'Returning'
      url = @re_entry_support_url
    if url
      month = moment(@chart.categories()[d.index] + ' 1', 'MMM YYYY D')
      url = url.replace('START_DATE', month.format('MMM DD, YYYY'))
      url = url.replace('END_DATE', month.endOf('month').format('MMM DD, YYYY'))
      window.open url
