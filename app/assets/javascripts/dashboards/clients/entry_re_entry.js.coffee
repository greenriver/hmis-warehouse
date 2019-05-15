#= require ./namespace

class App.Dashboards.Clients.EntryReEntry extends App.Dashboards.Clients.Base
  constructor: (@chart_selector, @data, @sub_population, @entry_support_url, @re_entry_support_url) ->
    super(@chart_selector, @data, @sub_population, @entry_support_url)

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
      legend:
        position: 'right'
      size:
        height: 200
      bindto: @chart_selector
    })

  _follow_link: (d, e) =>
    if d.name == 'New'
      url = @entry_support_url
    else if d.name == 'Returning'
      url = @re_entry_support_url
    month = moment(@chart.categories()[d.index] + ' 1', 'MMM YYYY D')
    url = url.replace('START_DATE', month.format('MMM DD, YYYY'))
    url = url.replace('END_DATE', month.endOf('month').format('MMM DD, YYYY'))
    window.open url