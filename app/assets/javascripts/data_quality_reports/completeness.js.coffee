#= require ./namespace

class App.DataQualityReports.Completeness extends App.DataQualityReports.Base
  constructor: (@data, @chart_selector, @support_url, @project_id) ->
    @_set_columns()
    super(@data, @chart_selector, @support_url)

  _set_columns: =>
    if @data.columns?
      @columns = @data.columns
    else
      # for backwards compatibility
      @columns = [
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
      ]

  _format_data: (data) ->
    {
      labels: data.labels,
      data: data.data,
      order: "asc",
      groups: [
        [
          'Complete'
          'Missing / Null'
          "Don't Know / Refused"
          'Not Collected'
          'Partial'
          "Anonymous",
          "No Exit Interview Completed",
        ]
      ]
    }

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      size:
        height: 300
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
          'Not Collected': 'bar',
          'Partial': 'bar'
          "Don't Know / Refused": "bar",
          "Missing / Null": "bar",
          'Target': "line",
        onover: @_over,
        onout: @_out,
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
            multiline: false,
        range:
          min:
            y: -100
        y:
          padding: 0
          max: 100
      grid:
        y:
          lines:
            value: 0,
      tooltip:
        format:
          value: (v) ->
            "#{v}%"

  _follow_link: (d, element) =>
    # console.log(@project_id)
    column = @columns[d.x]
    switch d.id
      when "Missing / Null" then prefix = "missing"
      when "Don't Know / Refused" then prefix = "refused"
      when "No Exit Interview Completed" then prefix = "no_interview"
      when 'Not Collected' then prefix = "not_collected"
      when 'Partial' then prefix = "partial"
      else return
    if @support_url.includes('individual') # VersionFour support links are different
      url = @support_url + "&selected_project_id=#{@project_id}&method=project_completeness&metric=#{prefix}&column=#{column}"
    else
      url = @support_url + ".html?layout=false&key=project_missing_" + @project_id + '_' + prefix + '_' + column

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)

  _over: (d) =>
    $('html,body').css('cursor', 'pointer')

  _out: (d) =>
    $('html,body').css('cursor', 'auto')
