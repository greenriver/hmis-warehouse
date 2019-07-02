#= require ./namespace

class App.DataQualityReports.NoIncome extends App.DataQualityReports.Base
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
        onover: @_over,
        onout: @_out,
      axis:
        x:
          type: "category",
          categories: @data['labels'],
  _follow_link: (d, element) =>
  # Do nothing by default
    project_id = @data.projects[d.name]
    label = @data.labels[d.index]
    range = @data.ranges[label]
    if @support_url.includes('individual') # VersionFour support links are different
      url = @support_url + "&selected_project_id=#{project_id}&metric=#{range}"
    else
      url = @support_url + "_#{project_id}_#{range}&layout=false"
    if project_id?
      $('.modal .modal-content').html('Loading...')
      $('.modal').modal('show')
      $('.modal .modal-content').load(url)

  _over: (d) =>
    $('html,body').css('cursor', 'pointer')

  _out: (d) =>
    $('html,body').css('cursor', 'auto')