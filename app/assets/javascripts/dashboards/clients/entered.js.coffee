#= require ./namespace

class App.Dashboards.Clients.Entered extends App.Dashboards.Clients.Base
  constructor: (@chart_selector, @sub_population, @support_url, options) ->
    super(@chart_selector, @sub_population, @support_url, options)


  _build_chart: () =>
    return unless $(@chart_selector).length > 0
    @data = $(@chart_selector).data('chart-data')
    @columns = $(@chart_selector).data('chart-columns')
    return unless @columns[1]?
    data =
      x: 'x'
      type: 'bar',
      onclick: @_follow_link
      color: @_colors
      groups: [@data],
      columns: @columns
    @chart = bb.generate({
      data: data,
      axis:
        x:
          type: 'category'
          tick:
            count: 4
        y:
          tick:
            count: 7
            format: d3.format(",.0f")
          max: 100
          padding: 0
      tooltip:
        format:
          value: (v) ->
            "#{v}%"
      legend:
        position: @options.legend.position
      size: @options.size
      bindto: @chart_selector
    })
