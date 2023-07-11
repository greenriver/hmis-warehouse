#= require ./namespace

class App.Maps.MapWithMarkers
  constructor: (@element_id, @data, @options) ->
    map = new L.Map(@element_id)
    osmUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    osmAttrib = 'Map data © <a href="https://www.openstreetmap.org">OpenStreetMap</a> contributors'
    osm = new L.TileLayer(osmUrl, { attribution: osmAttrib })
    map.addLayer(osm)
    bounds = new L.LatLngBounds(@options.bounds)
    if @options.cluster
      group = L.markerClusterGroup()
      for marker in @data
        options = {
          iconShape: 'marker',
          backgroundColor: @options.marker_color,
          borderColor: 'white',
          borderWidth: 2,
        }
        if marker.highlight
          options.borderColor = @options.highlight_color
        m = L.marker(marker.lat_lon, icon: L.BeautifyIcon.icon(options))
        if @options.link
          m.bindPopup(marker.label.join('<br />'))
          # NOTE: there seems to be some sort of weird bug where this isn't bound automatically
          m.on 'click', (e) ->
            this.openPopup()
        else
          m.bindTooltip(marker.label.join('<br />', { permanent: @options.permanent? }))
        group.addLayer(m)
      map.addLayer(group)
      map.fitBounds(bounds)
    else
      for marker in @data
        options = {
          iconShape: 'marker',
          backgroundColor: @options.marker_color,
          borderColor: 'white',
          borderWidth: 2,
        }
        m = L.marker(marker.lat_lon, icon: L.BeautifyIcon.icon(options))
        if @options.link
          m.bindPopup(marker.label)
          # NOTE: there seems to be some sort of weird bug where this isn't bound automatically
          m.on 'click', (e) ->
            this.openPopup()
        else
          m.bindTooltip(marker.label, { permanent: @options.permanent? })
        m.addTo(map)
      if @data.length == 1
        map.setView(@data[0].lat_lon, 13)
      else
        map.fitBounds(bounds)
    map
