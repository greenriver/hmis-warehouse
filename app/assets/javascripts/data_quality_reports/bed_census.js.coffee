#= require ./namespace

class App.DataQualityReports.BedCensus extends App.DataQualityReports.Base
  _format_data: (data) ->
    # fake data
    {
      labels: ["2018-04-11", "2018-04-12", "2018-04-13", "2018-04-14", "2018-04-15", "2018-04-16", "2018-04-17", "2018-04-18", "2018-04-19", "2018-04-20"],
      data: {
        'Project Name 1': [25, 25, 25, 25, 25, 25, 25, 25, 25],
        'Project Name 2': [14, 15, 14, 16, 17, 15, 16, 16, 15],
        'Total': [39, 40, 39, 41, 42, 40, 41, 41, 40],
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
          tick:
            rotate: 90