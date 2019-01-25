#= require ./namespace

class App.DataQualityReports.Base
  constructor: (@data, @chart_selector, @support_url) ->
    @data = @_format_data(@data)

  build_chart: =>
    if @data['data']?
      @_build_chart()
    else 
      $(@chart_selector + '.jChart').append ("<h4 class='text-center'>No Records Found</h4>")
    $('.jLoading').remove()
    
  
  _format_data: (data) ->
    data
  
  _follow_link: (d, element) =>
    console.log(d, element, @support_url)
    
  
