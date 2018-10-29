#= require ./namespace

class App.Census.CensusByProjectType extends App.Census.Base
  _build_census: () ->
    id = 0
    for project_type, data of @data  
      util = window.App.util.new
      options = 
        size: 
          height: 200
      census_detail_slug = "#{project_type}"
      @_individual_chart(data, id, census_detail_slug, options)
      id += 1

  _follow_link: (d, element) =>
    chart_id = $(element).closest('.jChart').attr('id')
    date = d.x.toISOString().split('T')[0]
    project = @chart_data[chart_id]['census_detail_slug']

    # # If we clicked on a point, send us to the list of associated clients
    params = {type: @type, date: date, project_type: project}
    url = @url.replace('date_range', 'details') + '?' + $.param(params)
    window.open url
 
    
