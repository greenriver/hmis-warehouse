#= require ./namespace

class App.Maps.MapWithShapes
  constructor: (@element_id, @shapes) ->

    mapOptions =
      minZoom: 6
      maxZoom: 9

    @map = new L.Map(@element_id, mapOptions)
    osmUrl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    osmAttrib = 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    osm = new L.TileLayer(osmUrl, {attribution: osmAttrib})

    @map.addLayer(osm)

    geoJSONOptions =
      style: @style
      onEachFeature: @onEachFeature

    @geojson = L.geoJSON(@shapes, geoJSONOptions).addTo(@map)

    @map.fitBounds(@geojson.getBounds())

    @initInfoBox()
    @initLegend()

  initInfoBox: =>
    @info = L.control()

    @info.update = (props) =>
      if props?
        @_div.innerHTML = '<h4>'+props.name+'</h4></h3>'+props.metric+'</h3>'
      else
        @_div.innerHTML = '<h4>Hover over a Geography</h4>'

    @info.onAdd = (map) =>
      @_div = L.DomUtil.create('div', 'l-info')
      @info.update()
      @_div

    @info.addTo(@map)

  initLegend: =>
    legend = L.control(position: 'bottomleft')

    legend.onAdd = (map) =>
      div = L.DomUtil.create('div', 'l-info l-legend')
      metricValues = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
      i = 0
      while i < metricValues.length-1
        line = '<i style="background:' + @getColor(metricValues[i]) + '"></i> '
        line += metricValues[i]
        if metricValues[i+1]?
          line += ' - ' + metricValues[i+1] + '</br>'
        else
          line += '+'

        div.innerHTML += line
        i += 1
      div

    legend.addTo(@map)

  style: (feature) =>
    metric = feature.properties.metric
    {
      fillColor: @getColor(metric)
      weight: 1
      opacity: 1
      color: 'gray'
      dashArray: ''
      fillOpacity: 0.8
    }

  getColor: (metric) ->
    colors = ['#ffffff', '#fff7fb','#ece7f2','#d0d1e6','#a6bddb','#74a9cf','#3690c0','#0570b0','#045a8d','#023858']
    colors[Math.floor(metric*colors.length)]

  highlightFeature: (e) =>
    layer = e.target

    layer.setStyle({
      weight: 3
      color: '#666'
      dashArray: ''
      fillOpacity: 0.8
    })

    @info.update(layer.feature.properties)

    if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)
      layer.bringToFront()

  resetHighlight: (e) =>
    @info.update()
    @geojson.resetStyle(e.target)

  onEachFeature: (feature, layer) =>
    handlers =
      mouseover: @highlightFeature
      mouseout: @resetHighlight
      click: @handleClick
    layer.on(handlers)

  handleClick: (e) =>
    name = e.target.feature.properties.name
    centroid = e.target.feature.properties.centroid
    record_id = e.target.feature.properties.id
    metric = e.target.feature.properties.metric
    popupText = name + " (" + metric + ")"

    @updateForm(record_id)

    options =
      title: name

    if @marker?
      @map.removeLayer(@marker)

    @marker = L.marker(centroid, options)
    @marker.addTo(@map)
    @marker.bindPopup(popupText).openPopup()

  updateForm: (record_id) =>
    @form_offset = -1  unless @form_offset?
    @form_elements = [$('#compare_coc1'), $('#compare_coc2')] unless @form_elements?
    @form_offset = (@form_offset + 1) % @form_elements.length

    @form_elements[@form_offset].val(record_id).trigger('change')
