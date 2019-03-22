#= require ./namespace

class App.DataQualityReports.Completeness extends App.DataQualityReports.Base
  constructor: (@data, @chart_selector, @support_url, @project_id) ->
    super(@data, @chart_selector, @support_url)

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
      data: 
        json: @data['data'], 
        type: "bar", 
        order: @data['order'], 
        groups: @data['groups'], 
        color: @_colors, 
        onclick: @_follow_link,
        types: 
          "Complete": "bar",
          "No Exit Interview Completed": "bar",
          "Don't Know / Refused": "bar",
          "Missing / Null": "bar",
          'Target': "line",
      point:
        show: false
      line:
        classes: [
          'data-quality__target-line'
        ]
      axis:
        x:
          type: "category",
          categories: @data['labels'],
          tick:
            rotate: 60
        range:
          min: 
            y: -100
      grid:
        y:
          lines:
            value: 0,
      tooltip:
        format:
          value: (v) -> 
            "#{v}%"

  _follow_link: (d, element) =>
    column = [
      "name",
      "dob",
      "ssn",
      "race",
      "ethnicity",
      "gender",
      "veteran",
      "disabling_condition",
      "prior_living_situation",
      "income_at_entry",
      "income_at_exit",
      "destination",
    ][d.x]
    switch d.id
      when "Missing / Null" then prefix = "_missing_"
      when "Don't Know / Refused" then prefix = "_refused_"
      when "No Exit Interview Completed" then prefix = "_no_interview_"
      else return

    url = @support_url + ".html?layout=false&key=project_missing_" + @project_id + prefix + column
    $('.modal').modal('show')
    $('.modal .modal-body').load(url)
