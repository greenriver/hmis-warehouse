#= require ./namespace

class App.Census.CensusVeteran extends App.Census.Base
  _build_census: () ->
    id = 0
    for project_type, data of @data
      continue if @options?.excluded_datasets?.includes project_type
      util = window.App.util.new
      for i of data.datasets
        hash = window.App.util.hashCode(data.title.text)
        color = window.App.util.intToRGB(hash + i * 200)
        data.datasets[i].borderColor = "\##{color}"
        data.datasets[i].backgroundColor = "transparent"
        data.datasets[i].lineTension = 0
        data.datasets[i].borderWidth = 1
        if @options?.disabled_datasets?.includes data.datasets[i].label
          data.datasets[i].hidden = true

      options =
        tooltips: 
          callbacks: 
            label: @_format_tooltip_label
      census_detail_slug = "#{project_type}"
      @_individual_chart(data, id, census_detail_slug, options)
      id += 1
  
  _follow_link: (event) =>
    chart = @charts[event.target.id.replace('census-chart-', '')]
    project = $(event.target).data('project')
    # If we clicked on a point, send us to the list of associated clients
    if point = chart.getElementAtEvent(event)[0]
      date = chart.config.data.datasets[point._datasetIndex].data[point._index].x
      veteran = chart.config.data.datasets[point._datasetIndex].label
      params = {type: @type, date: date, project_type: project, veteran: veteran}
      url = @url.replace('date_range', 'details') + '?' + $.param(params)
      window.open url

  _format_tooltip_label: (tool_tip, data) =>
    return unless tool_tip
    d = new Date(tool_tip.xLabel)
    date_string = new Date((d.getTime() + (d.getTimezoneOffset() * 60000))).toDateString()
    yesterday_count = data['datasets'][tool_tip.datasetIndex]['data'][tool_tip.index]['yesterday'] 
    change_count = tool_tip.yLabel - yesterday_count
    change_percent = (change_count / tool_tip.yLabel * 100).toFixed(2)
    if tool_tip.datasetIndex == 0
      tool_tip.label = [
        date_string,
        "Veteran Client count: #{tool_tip.yLabel}",
        "Change from previous day: #{change_count} (#{change_percent}%)"
      ]
    else
      tool_tip.label = [
        date_string,
        "Non-Veteran Client count: #{tool_tip.yLabel}",
        "Change from previous day: #{change_count} (#{change_percent}%)"
      ]

    
