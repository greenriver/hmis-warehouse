#= require ./namespace

class App.Dashboards.Clients.Exits extends App.Dashboards.Clients.Base
  _build_chart: () =>
    @data = $(@chart_selector).data('chart-data')
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
      legend: @options.legend
      size: @options.size
      bindto: @chart_selector
    })
