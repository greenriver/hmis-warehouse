#= require ./namespace

class App.DataQualityReports.TimeToEnter extends App.DataQualityReports.Base
  _format_data: (data) ->
    values = {}
    for k,v of data
      values[k] = [0, v, 0]
    values["Goal"] = [14, 14, 14]
    {
      labels: ["", "", ""],
      data: values
    }

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data:
        json: @data['data'],
        type: "bar",
        color: @_colors,
        onclick: @_follow_link
        types:
          "Goal": "line",
      point:
        show: false,
      line:
        classes: [
          'data-quality__target-line'
        ]
      axis:
        x:
          type: "category",
          categories: @data['labels'],