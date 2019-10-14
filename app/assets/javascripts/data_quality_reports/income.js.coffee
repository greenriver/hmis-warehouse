#= require ./namespace

class App.DataQualityReports.Income extends App.DataQualityReports.Base
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
          "This Project": "bar",
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
    x = @data.labels[d.x]
    suffix = ''
    if x == '20% Increase'
      suffix = ' 20'
    key = d.name + suffix
    if @support_url.includes('individual') # VersionFour support links are different
      url = @support_url + "&metric=#{key.toLowerCase().replace(/ /g,"_").replace(/-/g, '_')}"
    else
      url = @support_url + key.toLowerCase().replace(/ /g,"_") + "&layout=false"

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load url, (response, status, xhr) ->
      if xhr.status != 200
        $('.modal .modal-content').html(response)

  _over: (d) =>
    $('html,body').css('cursor', 'pointer')

  _out: (d) =>
    $('html,body').css('cursor', 'auto')