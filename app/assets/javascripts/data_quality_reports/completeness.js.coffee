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
      data: {json: @data['data'], type: "bar", order: @data['order'], groups: @data['groups'], color: @_colors, onclick: @_follow_link}
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

  _follow_link: (d, element) =>
    column = [
      "_name",
      "_dob",
      "_ssn",
      "_race",
      "_ethnicity",
      "_gender",
      "_veteran",
      "_disabling_condition",
      "_prior_living_situation",
      "_income_at_entry",
      "_income_at_exit",
      "_destination",
    ][d.x]
    switch d.id
      when "Missing / Null" then prefix = "missing"
      when "Don't Know / Refused" then prefix = "refused"
      when "No Exit Interview Completed" then prefix = "no_interview"
      else return

    url = @support_url + "?key=" + prefix + column
    window.open url