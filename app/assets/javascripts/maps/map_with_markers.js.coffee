#= require ./namespace

class App.Maps.MapWithMarkers
  constructor: (@element_id, @markers, @labels, @permanent=true) ->
    map = new L.Map(@element_id);
    osmUrl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    osmAttrib = 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    osm = new L.TileLayer(osmUrl, {attribution: osmAttrib})
    
    bounds = new L.LatLngBounds(@markers)
    for marker, i in @markers
      L.marker(marker).bindTooltip(@labels[i], { permanent: @permanent }).addTo map
    if @markers.length == 1
      map.setView(@markers[0], 13)
    else 
      map.fitBounds(bounds)
    map.addLayer(osm)