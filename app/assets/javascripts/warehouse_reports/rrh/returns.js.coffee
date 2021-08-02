#= require ./namespace
class App.WarehouseReports.Rrh.Returns
  constructor: (@wrapper, @data, @support_url) ->
    @plot()

  plot: =>
    tt = bb.generate
      data:
        columns: @data.data
        type: "bar"
        onclick: @_follow_link
      axis:
        x:
          tick:
            format: (i, category_name) =>
              @data.labels[i]
      tooltip:
        contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
          @_toolip(d, defaultTitleFormat, defaultValueFormat, color)
        # format:
        #   title: (i) =>
        #     'Time to Return ' + @data.labels[i]

      color:
        pattern: ["#fb4d42", "#288be4", "#091f2f", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
      bindto: @wrapper

  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    # console.log(d, defaultValueFormat(d[0].value), @data)
    tooltip_title = defaultTitleFormat(d[0].x)
    html = "<table class='bb-tooltip'>"
    html += "<thead>"
    html += "<tr><th>Time to Return</th><th>Clients</th><th>Destination prior to Return</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]
      if row?
        bg_color = color(row.id)
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value}</td>"
        details = "<td class='text-left'>"
        for k, v of @data.destinations[row.index]
          details += "#{k} (#{v})<br />"
        details +="</td>"
        html += box
        html += value
        html += details
        html += "</tr>"

    html += "</tbody>"
    html += '</table>'
    html

  _follow_link: (d, e) =>
    return unless @support_url.length > 1
    # if @data.projects_selected == true
    bucket = @data.labels[d.index]
    url = @support_url + encodeURI("&selected_project=#{d.name}&bucket=#{bucket}")
    # console.log(d, @data, url)

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)
