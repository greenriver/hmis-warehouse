#= require ./namespace

class App.Reports.CocOverlap
  constructor: (@element_id, @props={}) ->
    {
      mapId='leaflet-map',
      mapShapes={}
    } = @props
    new App.Maps.MapWithShapes mapId, mapShapes
