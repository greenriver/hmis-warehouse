#= require ./namespace

class App.Maps.MapWithMarkers
  constructor: (@element_id, @markers, @labels, @permanent=true, @cluster=false, @bounds=false) ->
    map = new L.Map(@element_id)
    osmUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    osmAttrib = 'Map data © <a href="https://www.openstreetmap.org">OpenStreetMap</a> contributors'
    osm = new L.TileLayer(osmUrl, {attribution: osmAttrib})
    map.addLayer(osm)
    if @bounds
      bounds = new L.LatLngBounds(@bounds)
    else
      bounds = new L.LatLngBounds(@markers)

    if @cluster
      group = L.markerClusterGroup()
      for marker, i in @markers
        m = L.marker(marker, {title: @labels[i]})
        m.bindPopup(@labels[i])
        group.addLayer(m)
      map.addLayer(group)
      map.fitBounds(bounds)
    else
      for marker, i in @markers
        L.marker(marker).bindTooltip(@labels[i], { permanent: @permanent }).addTo map
      if @markers.length == 1
        map.setView(@markers[0], 13)
      else
        map.fitBounds(bounds)

    map
