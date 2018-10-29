#= require ./namespace

class App.Census.CombinedProjectType extends App.Census.Base
  _build_census: () ->
    id = 0
    point_styles = [
      'circle',
      'cross',
      'crossRot',
      'dash',
      'line',
      'rect',
      'rectRounded',
      'rectRot',
      'star',
      'triangle',
    ]
    # console.log @data
    for group, data of @data
      continue if @options?.excluded_datasets?.includes(group)
      util = window.App.util.new
      # console.log group, data
      for i of data.datasets
        hash = window.App.util.hashCode(data.title.text)
        color = window.App.util.intToRGB(hash + (i+ 1) * 200)
        data.datasets[i].borderColor ?= "\##{color}"
        data.datasets[i].backgroundColor ?= "transparent"
        data.datasets[i].lineTension ?= 0
        data.datasets[i].borderWidth ?= 1
        data.datasets[i].pointStyle ?= point_styles[i % point_styles.length]
        data.datasets[i].pointRadius ?= 4
        if @options?.disabled_datasets?.includes data.datasets[i].label
          data.datasets[i].hidden = true

      options =
        tooltips: 
          callbacks: 
            label: @_format_tooltip_label
      census_detail_slug = "#{group}"
      @_individual_chart(data, id, census_detail_slug, options)
      id += 1
  
  _follow_link: (event) =>
    return
    
  _height: ->
    150