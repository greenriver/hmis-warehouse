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
       