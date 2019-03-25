#= require ./namespace

class App.DataQualityReports.TimeInProgram extends App.DataQualityReports.Base
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
      axis:
        x:
          type: "category",
          categories: @data['labels']
  _follow_link: (d, element) =>
    # Do nothing by default
    project_id = @data.projects[d.name]
    label = @data.labels[d.index]
    range = @data.ranges[label]
    url = @support_url + "_#{project_id}_#{range}&layout=false"
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)