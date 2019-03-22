#= require ./namespace

class App.DataQualityReports.TimeToEnter extends App.DataQualityReports.Base

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      size: 
        height: 250
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