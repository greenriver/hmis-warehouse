#= require ./namespace

class App.DataQualityReports.TimeToEnter extends App.DataQualityReports.Base
  _format_data: (data) ->
    # fake data
    {
      labels: ["1 month or less", "1 to 6 months", "1 to 12 months", "12 months or greater"],
      data: {
        'Project Name 1': [0, 2, 4, 8],
        'Project Name 2': [1, 3, 5, 7],
        'Total': [1, 5, 9, 15],
      },
    }
    # live data
#    data


  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "bar", onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],