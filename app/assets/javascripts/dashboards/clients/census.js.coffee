#= require ./namespace

class App.Dashboards.Clients.Census extends App.Dashboards.Clients.Base
  _build_chart: () =>
    data =
      x: 'x'
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
      legend: @options.legend
      size: @options.size
      bindto: @chart_selector
    })

  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    console.log(d, defaultValueFormat(d[0].value), @data, @options)
    tooltip_title = defaultTitleFormat(d[0].x)
    html = "<table class='bb-tooltip'>"
    html += "<thead>"
    html += "<tr><th colspan='2'>#{tooltip_title}</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]
      if row?
        bg_color = color(row.id)
        html += "<tr class='bb-tooltip-name-#{@chart.internal.getTargetSelectorSuffix(row.id)}'>"
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value}</td>"
        html += box
        html += value
        html += "</tr>"
    total_count = @options.totals[1][d[0].x + 1]
    html += "<tfoot>"
    html += "<tr><th>Total</th><th>#{total_count}</th></tr>"
    html += "</tfoot>"
    html += "</tbody>"
    html += '</table>'
    html
