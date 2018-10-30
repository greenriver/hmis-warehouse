#= require ./namespace

class App.Census.CombinedProjectType extends App.Census.Base
  _build_census: () ->
    id = 0
   
    point_styles = [
      "circle",
      "<polygon points='0 0 0 0'></polygon>",
      "rectangle",
      "<polygon points='0 0 0 0'></polygon>",
      "<polygon points='2.5 0 0 5 5 5'></polygon>",
      "<polygon points='0 0 0 0'></polygon>",
      "<polygon points='2.5 0 0 2.5 2.5 5 5 2.5 2.5 0'></polygon>",
      "<polygon points='0 0 0 0'></polygon>",
      "circle",
      "<polygon points='0 0 0 0'></polygon>",
      "rectangle",
      "<polygon points='0 0 0 0'></polygon>",
      "<polygon points='2.5 0 0 5 5 5'></polygon>",
      "<polygon points='0 0 0 0'></polygon>",
      "<polygon points='2.5 0 0 2.5 2.5 5 5 2.5 2.5 0'></polygon>",
      "<polygon points='0 0 0 0'></polygon>",
      "circle",
      "<polygon points='0 0 0 0'></polygon>",
      "rectangle",
    ]
    # console.log @data
    for group, data of @data
      continue if @options?.excluded_datasets?.includes(group)
      util = window.App.util.new
      # console.log group, data
      for i of data.datasets
        if @options?.disabled_datasets?.includes data.datasets[i].label
          data.datasets[i].hidden = true

      options =
        point:
          pattern: point_styles
        # legend:
        #   usePoint: true
        #   position: 'right'
      census_detail_slug = "#{group}"
      @_individual_chart(data, id, census_detail_slug, options)
      id += 1
  
  _follow_link: (event) =>
    return
    
  _height: ->
    150