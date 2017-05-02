#= require ./namespace

class App.Census.CensusBedNightProgram extends App.Census.Base
  _build_census: () ->
    id = 0
    for data_source, all_organizations of @data
      for organization, all_projects of all_organizations
        for project, data of all_projects
          util = window.App.util.new
          for i of data.datasets
            hash = window.App.util.hashCode(data.title.text)
            color = window.App.util.intToRGB(hash + i * 200)
            data.datasets[i].borderColor = "\##{color}"
            data.datasets[i].backgroundColor = "transparent"
            data.datasets[i].lineTension = 0
            data.datasets[i].borderWidth = 1
          if data.datasets[1]?
            data.datasets[1].borderColor = "red"
          options =
            tooltips: 
              callbacks: 
                label: @_format_tooltip_label
          census_detail_slug = "#{data_source}-#{organization}-#{project}"
          @_individual_chart(data, id, census_detail_slug, options)
          id += 1        
       
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
        "Client count: #{tool_tip.yLabel}",
        "Change from previous day: #{change_count} (#{change_percent}%)"
      ]
    else
      tool_tip.label = [
        date_string,
        "Bed inventory: #{tool_tip.yLabel}"
      ]