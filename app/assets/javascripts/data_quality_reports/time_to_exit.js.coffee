#= require ./namespace

class App.DataQualityReports.TimeToExit extends App.DataQualityReports.Base

  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      size:
        height: 350
      data:
        json: @data['data'],
        type: "bar",
        color: @_colors,
        onclick: @_follow_link
        onover: @_over,
        onout: @_out,
        types:
          "Goal": "line",
      point:
        show: false,
      line:
        classes: [
          'data-quality__target-line'
        ]
      axis:
        x:
          type: "category",
          categories: @data['labels'],

  _follow_link: (d, element) =>
    if @support_url.includes('individual') # VersionFour support links are different
      project_id = @data.projects[d.name]
      url = @support_url + "&selected_project_id=#{project_id}"
    else
      url = @support_url + "_#{d.name.toLowerCase().replace(/ /g,"_")}&layout=false"

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load url, (response, status, xhr) ->
      if xhr.status != 200
        $('.modal .modal-content').html(response)

  _over: (d) =>
    $('html,body').css('cursor', 'pointer')

  _out: (d) =>
    $('html,body').css('cursor', 'auto')