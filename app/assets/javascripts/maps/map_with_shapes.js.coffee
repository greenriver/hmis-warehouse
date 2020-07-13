#= require ./namespace

class App.Maps.MapWithShapes
  constructor: ({@elementId, @shapes}, @callback) ->
    @selectionIndex = 0
    mapOptions =
      minZoom: 6
      maxZoom: 9
      zoomControl: false

    @mapHighlightColors = ['#fca736', '#ffe09b']
    @highlightedFeatures = []

    @map = new L.Map(@elementId, mapOptions)

    L.control.zoom({
        position: 'topright'
    }).addTo(@map);

    # Do not show basemap to resmeble mock
    # osmUrl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    # osmAttrib = 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    # osm = new L.TileLayer(osmUrl, {attribution: osmAttrib})
    # @map.addLayer(osm)

    geoJSONOptions =
      style: @style
      onEachFeature: @onEachFeature

    @geojson = L.geoJSON(@shapes, geoJSONOptions).addTo(@map)

    @map.fitBounds(@geojson.getBounds())

    # @initInfoBox()
    # @initLegend()

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
      fillColor: 'white' #@getColor(metric)
      weight: 1
      opacity: 1
      color: '#d7d7de'
      dashArray: ''
      fillOpacity: 0.8
    }

  getColor: (d) ->
    if d > 200 then '#0154A6'
    else if d > 165 then '#256CB3'
    else if d > 132 then '#4A85BF'
    else if d > 100 then '#6E9DCC'
    else if d > 67 then '#92B6D9'
    else if d > 34 then '#B6CEE6'
    else if d > 0 then '#DBE7F2'
    else '#FFFFFF'

  highlightFeature: (e, highlightIndex=0) =>
    layer = e?.target || e

    layer.setStyle({
      fillColor: @mapHighlightColors[highlightIndex],
      fillOpacity: 1
    })

    @info?.update(layer.feature.properties)

    if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)
      layer.bringToFront()

  resetHighlight: (e) =>
    @info?.update()
    @geojson.resetStyle(e.target? || e)

  onEachFeature: (feature, layer) =>
    handlers =
      # mouseover: @highlightFeature
      # mouseout: @resetHighlight
      click: @handleClick
    layer.on(handlers)

  handleClick: (e) =>
    name = e.target.feature.properties.name
    centroid = e.target.feature.properties.centroid
    record_id = e.target.feature.properties.id
    metric = e.target.feature.properties.metric
    popupText = name + " (" + metric + ")"

    options =
      title: name

    # Update current marker
    # noop for now until we establish UX
    if @marker?
      @map.removeLayer(@marker)
    # @marker = L.marker(centroid, options)
    # @marker.addTo(@map)
    # @marker.bindPopup(popupText).openPopup()

    index = @callback(record_id)
    @updateSelections(e.target, index)


  updateSelections: (selectedFeature, selectionIndex) =>
    currentlyHighlighted = @highlightedFeatures[selectionIndex]
    if currentlyHighlighted
      @resetHighlight(@highlightedFeatures[selectionIndex])

    # Search through the layers if the selection is not a Layer
    unless selectedFeature.feature
      selectedFeature = @geojson.getLayers().find (l) =>
        l.feature.properties.id == +selectedFeature
    @highlightedFeatures[selectionIndex] = selectedFeature
    @highlightFeature(selectedFeature, selectionIndex)

  updateData: (shapes, selections) =>
    @geojson.getLayers().forEach (l) =>
      id = l.feature.properties.id
      shapeMetric = shapes[l.feature.properties.id]
      l.feature.properties.metric = shapeMetric
      # do not change the currently selected layers
      return if selections.includes id
      l.setStyle({
        fillColor: @getColor(shapeMetric)
        fillOpacity: 1
      })
