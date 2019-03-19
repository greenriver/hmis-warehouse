#= require ./namespace

class App.DataQualityReports.Income extends App.DataQualityReports.Base
  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data:
        json: @data['data'],
        type: "bar",
        colors:
          "This Program": "#091f2f",
          "Goal": 'rgb(228, 228, 228)'
        onclick: @_follow_link
        types:
          "This Program": "bar",
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