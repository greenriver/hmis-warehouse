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
  
  _follow_link: (d, element) =>
    chart_id = $(element).closest('.jChart').attr('id')
    date = d.x.toISOString().split('T')[0]
    project = @chart_data[chart_id]['census_detail_slug']
    # # If we clicked on a point, send us to the list of associated clients
    params = {type: @type, date: date, project_type: project, veteran: d.name}
    url = @url.replace('date_range', 'details') + '?' + $.param(params)
    window.open url    
