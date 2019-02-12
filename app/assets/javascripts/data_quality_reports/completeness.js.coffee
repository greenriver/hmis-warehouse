#= require ./namespace

class App.DataQualityReports.Completeness extends App.DataQualityReports.Base
  _format_data: (data) ->
    # fake data
    {
      labels: ["First Name", "Last Name", "DOB", "SSN", "Race", "Ethnicity", "Gender", "Veteran Status", "Disabling Condition", "Living Situation", "Income At Entry", "Income At Exit", "Destination"],
      data: {
        "Complete": [100, 100, 100, 85.72, 94.29, 100, 100, 100, 97.14, 100, 100, 100, 100],
        "Anonymous": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "No Exit Interview Completed": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Don't Know / Refused": [0, 0, 0, 5.71, 5.71, 0, 0, 0, 2.86, 0, 0, 0, 0],
        'Missing / Null': [0, 0, 0, 8.57, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      },
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
    # live data
#    data


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