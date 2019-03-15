#= require ./namespace

class App.DataQualityReports.PHDestination extends App.DataQualityReports.Base
  _format_data: (data) ->
    {
      labels: [ "" ],
      data: {
        "This Program": [ data ],
        "Goal": [ 100 ],
      }
    }

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "bar", color: @_colors, onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],