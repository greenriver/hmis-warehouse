#= require ./namespace

class App.DataQualityReports.UnitCensus extends App.DataQualityReports.Base
  _build_chart: ->
    labels = @data['labels']
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "line", onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],
          tick:
            rotate: 90
            width: 72
            count: 13
            format: (x) ->
              labels[Math.round(x)]