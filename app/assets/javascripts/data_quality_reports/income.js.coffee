#= require ./namespace

class App.DataQualityReports.Income extends App.DataQualityReports.Base
  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "bar", color: @_colors, onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],