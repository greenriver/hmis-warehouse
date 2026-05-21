#= require ./namespace
class App.WarehouseReports.Rrh.Destination
  constructor: (@wrapper, @legend_wrapper, @data, @support_url) ->
    @plot()
    # console.log(@data)

  plot: =>
    @chart = bb.generate
      size:
        width: 500
        height: 500
      data:
        columns: @data.data
        type: "pie"
        onclick: @_follow_link
      tooltip:
        contents: (d, defaultTitleFormat, defaultValueFormat, color) =>
          @_toolip(d, defaultTitleFormat, defaultValueFormat, color)
      pie:
        label:
          format: (value, ratio, id) ->
            "#{value} (#{d3.format(".0%")(ratio)})"
      color:
        pattern: ["#fb4d42", "#288be4", "#091f2f", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
      bindto: @wrapper

  _toolip: (d, defaultTitleFormat, defaultValueFormat, color) =>
    # Somewhat reverse engineered from here:
    # https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    # console.log(d, defaultValueFormat(d[0].value), @data)
    tooltip_title = defaultTitleFormat(d[0].x)
    html = "<table class='bb-tooltip' style='white-space: normal'>"
    html += "<thead>"
    html += "<colgroup><col style='width: 150px' /><col style='width: 100px' /><col style='width: 250px' /></colgroup>"
    html += "<tr><th>Destination Group</th><th>Clients</th><th>Destinations</th></tr>"
    html += "</thead>"
    html += "<tbody>"
    $(d).each (i) =>
      row = d[i]

      if row?
        bg_color = color(row.id)
        box = "<td class='name'><svg><rect style='fill:#{bg_color}' width='10' height='10'></rect></svg>#{row.name}</td>"
        value = "<td>#{row.value} (#{d3.format(".0%")(row.ratio)})</td>"
        details = "<td class='text-left'>#{@_destination_list(row.name)}</td>"
        html += box
        html += value
        html += details
        html += "</tr>"

    html += "</tbody>"
    html += '</table>'
    html

  _destination_list: (name) =>
    destinations = @data.support[name]?.detailed_destinations
    return '' unless destinations?
    "<ul>#{("<li>#{k} (#{v})</li>" for k, v of destinations).join('')}</ul>"

  _follow_link: (d, e) =>
    return unless @support_url.length > 1
    url = @support_url + encodeURI("&destination=#{d.id}")
    # console.log(d, @data, url)

    $('.modal .modal-content').html('Loading...')
    $('.modal').modal('show')
    $('.modal .modal-content').load(url)
