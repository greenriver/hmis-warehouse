#= require ./namespace

class App.DataQualityReports.UnitCensus extends App.DataQualityReports.Base
  _build_chart: ->
    labels = @data['labels']
    @chart = bb.generate
      bindto: @chart_selector
      size:
        height: 350
      data: {json: @data['data'], type: "line", color: @_colors, onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],
          tick:
            show: false
            rotate: 90
            width: 72
            culling:
              max: 10
            format: (x) ->
              labels[Math.round(x)]