#= require ./namespace

class App.DataQualityReports.PHDestination extends App.DataQualityReports.Base

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
        types:
          "Goal": "line",
        onover: @_over,
        onout: @_out,
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
        y:
          padding: 0
          min: 0
          max: 100
      tooltip:
        format:
          value: (v) ->
            "#{v}%"
   _follow_link: (d, element) =>
    console.log @data
    project_id = @data.projects[d.name]
    if @support_url.includes('individual') # VersionFour support links are different
      url = @support_url + "&selected_project_id=#{project_id}"
    else
      url = @support_url + "&layout=false"
    console.log url
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)

  _over: (d) =>
    $('html,body').css('cursor', 'pointer')

  _out: (d) =>
    $('html,body').css('cursor', 'auto')