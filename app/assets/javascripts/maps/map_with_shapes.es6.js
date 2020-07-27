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
      minZoom: 5,
      maxZoom: 9,
      zoomSnap: 0.2,
      zoomControl: false,
      scrollWheelZoom: false,
    };
    this.strokeColor = '#aaa';

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
      let innerHTML = '';
      let hidden = true;
      if (props != null) {
        const { id, name, cocnum, metric } = props;
        const { primaryId, secondaryId, primaryName } = this;
        innerHTML = `<h4>${name} (${cocnum})</h4>`;
        if (id == primaryId) {
          innerHTML += '<p>Primary CoC</p>';
        } else if (primaryId) {
          if (id == secondaryId) {
            innerHTML += '<p>Secondary CoC</p>';
          }
          if (metric == null) {
            innerHTML += '<p>No shared clients because data is unavailable for this CoC</p>';
          } else {
            innerHTML += `<p><stron>${metric}</strong> shared clients with ${
              primaryName || 'the primary CoC'
            }</p>`;
          }
        }
        hidden = false;
      }
      this._div.innerHTML = innerHTML;
      this._div.hidden = hidden;
    };

    this.info.onAdd = () => {
      this._div = L.DomUtil.create('div', 'l-info');
      this.info.update();
      return this._div;
    };

    return this.info.addTo(this.map);
  }

  initLegend() {
    const legend = L.control({ position: 'bottomleft' });

    legend.onAdd = () => {
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

  style() {
    return {
      fillColor: 'white',
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
      const { name, cocnum } = layer.feature.properties;
      this.primaryName = `${name} (${cocnum})`;
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
        color: '#888',
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
