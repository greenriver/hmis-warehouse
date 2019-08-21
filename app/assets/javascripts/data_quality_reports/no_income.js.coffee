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
        y:
          padding: 0
          min: 0
          max: 100
      tooltip:
        contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
          @_toolip(d, defaultTitleFormat, defaultValueFormat, color)
      legend:
        hide: true
  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    # console.log(d, defaultValueFormat(d[0].value), @data)
    tooltip_title = defaultTitleFormat(d[0].x)
    html = "<table class='bb-tooltip'>"
    html += "<thead>"
    # html += "<tr><th>#{tooltip_title}</th><th>Percent</th><th>Clients</th></tr>"
    html += "<tr><th>Percent</th><th>Clients</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]

      if row?
        bg_color = color(row.id)
        html += "<tr class='bb-tooltip-name-#{@chart.internal.getTargetSelectorSuffix(row.id)}'>"
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value}%</td>"
        client_count = @data.counts[row.x]
        count = "<td>#{client_count}</td>"
        # html += box
        html += value
        html += count
        html += "</tr>"

    html += "</tbody>"
    html += '</table>'
    html

  _follow_link: (d, element) =>
    key = this.chart.categories()[d.index]
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