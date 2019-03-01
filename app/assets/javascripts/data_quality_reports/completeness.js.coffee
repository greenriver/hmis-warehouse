#= require ./namespace

class App.DataQualityReports.Completeness extends App.DataQualityReports.Base
  _format_data: (data) ->
    {
      labels: data.labels,
      data: data.data,
      order: "asc",
      groups: [
        [
          "Complete",
          "Anonymous",
          "No Exit Interview Completed",
          "Don't Know / Refused",
          'Missing / Null',
        ]
      ]
    }

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "bar", order: @data['order'], groups: @data['groups'], onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],
          tick:
            rotate: 60
      grid:
        y:
          lines:
            value: 0,