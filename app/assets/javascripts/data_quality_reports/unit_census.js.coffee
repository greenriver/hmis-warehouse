#= require ./namespace

class App.DataQualityReports.UnitCensus extends App.DataQualityReports.Base
  _format_data: (data) ->
    # fake data
    {
      labels: ["2018-04-11", "2018-04-12", "2018-04-13", "2018-04-14", "2018-04-15", "2018-04-16", "2018-04-17", "2018-04-18", "2018-04-19", "2018-04-20"],
      data: {
        'Project Name 1': [0, 0, 0, 0, 0, 0, 0, 0, 0],
        'Project Name 2': [3, 3, 3, 3, 3, 3, 3, 3, 3],
        'Total': [3, 3, 3, 3, 3, 3, 3, 3, 3],
      },
    }
    # live data
#    data


  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "line", onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],