//= require ./namespace

App.Maps.MapWithShapes = class MapWithShapes {
  constructor({ elementId, shapes }) {
    this.initInfoBox = this.initInfoBox.bind(this);
    this.initLegend = this.initLegend.bind(this);
    this.style = this.style.bind(this);
    this.updateInfo = this.updateInfo.bind(this);
    this.clearInfo = this.clearInfo.bind(this);
    this.onEachFeature = this.onEachFeature.bind(this);
    this.updateShapes = this.updateShapes.bind(this);
    this.highlightPrimary = this.highlightPrimary.bind(this);
    this.resetHighlight = this.resetHighlight.bind(this);
    this.highlightSecondary = this.highlightSecondary.bind(this);
    this.elementId = elementId;
    this.shapes = shapes;
    this.showingData = false;
    const mapOptions = {
      minZoom: 6,
      maxZoom: 9,
      zoomControl: false,
      scrollWheelZoom: false,
    };
    this.strokeColor = '#d7d7de';

    this.highlightedFeatures = [];

    this.map = new L.Map(this.elementId, mapOptions);

    L.control
      .zoom({
        position: 'bottomleft',
      })
      .addTo(this.map);

    // Do not show basemap to resmeble mock
    // osmUrl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    // osmAttrib = 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    // osm = new L.TileLayer(osmUrl, {attribution: osmAttrib})
    // @map.addLayer(osm)

    const geoJSONOptions = {
      style: this.style,
      onEachFeature: this.onEachFeature,
    };

    this.geojson = L.geoJSON(this.shapes, geoJSONOptions).addTo(this.map);

    this.map.fitBounds(this.geojson.getBounds());

    this.initInfoBox();
  }
  // @initLegend()

  initInfoBox() {
    this.info = L.control();

    this.info.update = (props) => {
      if (props != null) {
        this._div.innerHTML = `<h4>${props.name} (${props.cocnum})</h4>`;
        if (props.id == this.primaryId) {
          this._div.innerHTML =
            this._div.innerHTML + '<p>Primary CoC</p>';
        } else if (props.metric != null) {
          this._div.innerHTML =
            this._div.innerHTML + '<p>Shared clients: <strong>' + props.metric + '</p>';
        } else {
          this._div.innerHTML =
            this._div.innerHTML + '<p>Shared clients: <strong>0</p>';
        }
        return (this._div.hidden = false);
      } else {
        return (this._div.hidden = true);
      }
    };

    this.info.onAdd = (map) => {
      this._div = L.DomUtil.create('div', 'l-info');
      this.info.update();
      return this._div;
    };

    return this.info.addTo(this.map);
  }

  initLegend() {
    const legend = L.control({ position: 'bottomleft' });

    legend.onAdd = (map) => {
      const div = L.DomUtil.create('div', 'l-info l-legend');
      const metricValues = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
      let i = 0;
      while (i < metricValues.length - 1) {
        let line = '<i style="background:' + this.getColor(metricValues[i]) + '"></i> ';
        line += metricValues[i];
        if (metricValues[i + 1] != null) {
          line += ' - ' + metricValues[i + 1] + '</br>';
        } else {
          line += '+';
        }

        div.innerHTML += line;
        i += 1;
      }
      return div;
    };

    return legend.addTo(this.map);
  }

  style(feature) {
    const { metric } = feature.properties;
    return {
      fillColor: 'white', //@getColor(metric)
      weight: 1,
      opacity: 1,
      color: this.strokeColor,
      dashArray: '',
      fillOpacity: 0.8,
    };
  }

  getColor(d) {
    if (d > 200) {
      return '#D17200';
    } else if (d > 165) {
      return '#D38628';
    } else if (d > 132) {
      return '#D59A4F';
    } else if (d > 100) {
      return '#D7AE77';
    } else if (d > 67) {
      return '#D9C29E';
    } else if (d > 34) {
      return '#DBD6C6';
    } else if (d > 0) {
      return '#DDEAED';
    } else {
      return '#FFFFFF';
    }
  }

  highlightPrimary(id) {
    //this.resetHighlight(this.primaryId);
    const layer = this.getLayerById(id);
    this.primaryId = id;
    if (layer) {
      layer.setStyle({ fillColor: '#36a4a6', fillOpacity: 1 });
      this.bringLayerToFront(layer);
    }
  }

  highlightSecondary(id) {
    //this.resetHighlight(this.secondaryId);
    const layer = this.getLayerById(id);
    this.secondaryId = id;
    if (layer) {
      layer.setStyle({ color: '#265479', weight: 3, opacity: 1 });
      this.bringLayerToFront(layer);
    }
  }

  resetHighlight(id) {
    const layer = this.getLayerById(id);
    if (layer) {
      this.geojson.resetStyle(layer);
    }
  }

  bringLayerToFront(layer) {
    if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge) {
      return layer.bringToFront();
    }
  }

  bringLayerToBack(layer) {
    if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge) {
      return layer.bringToBack();
    }
  }

  getLayerById(id) {
    return this.geojson.getLayers().find((l) => l.feature.properties.id == id);
  }

  updateInfo(e) {
    const layer = (e != null ? e.target : undefined) || e;
    if (this.info != null) {
      this.info.update(layer.feature.properties);
    }
    if (layer.feature.properties.id != this.secondaryId) {
      this.bringLayerToFront(layer);
      layer.setStyle({
        color: '#ccc',
        weight: 3,
        opacity: 1,
      });
    }
  }

  clearInfo(e) {
    const layer = (e != null ? e.target : undefined) || e;
    if (this.info != null) {
      this.info.update(null);
    }
    if (layer.feature.properties.id != this.secondaryId) {
      this.bringLayerToBack(layer);
      return layer.setStyle({
        color: this.strokeColor,
        weight: 1,
        opacity: 1,
      });
    }
  }

  onEachFeature(feature, layer) {
    const handlers = {
      mouseover: this.updateInfo,
      mouseout: this.clearInfo,
    };
    return layer.on(handlers);
  }

  updateShapes({ shapes, primaryId, secondaryId }) {
    this.showingData = true;
    this.geojson.getLayers().forEach((l) => {
      const shapeMetric = shapes[l.feature.properties.id];
      l.feature.properties.metric = shapeMetric;
      this.geojson.resetStyle(l);
      return l.setStyle({
        fillColor: this.getColor(shapeMetric),
        fillOpacity: 1,
      });
    });
    this.highlightPrimary(primaryId);
    this.highlightSecondary(secondaryId);
  }
};
