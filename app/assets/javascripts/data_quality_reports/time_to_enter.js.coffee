#= require ./namespace

class App.DataQualityReports.TimeToEnter extends App.DataQualityReports.Base
  _format_data: (data) ->
    # fake data
    {
      labels: ["Goal", "This Program"],
      data: {
        'Project Name 1': [14, 4],
        'Project Name 2': [14, 2],
        'Total': [14, 3],
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