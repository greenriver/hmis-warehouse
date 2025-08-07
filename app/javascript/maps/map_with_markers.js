import L from 'leaflet';
import 'leaflet.markercluster';
import 'beautifymarker';

export function createMapWithMarkers(elementId, data, options) {
  const map = new L.Map(elementId);
  const osmUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  const osmAttrib = 'Map data © <a href="https://www.openstreetmap.org">OpenStreetMap</a> contributors';
  const osm = new L.TileLayer(osmUrl, { attribution: osmAttrib });
  map.addLayer(osm);
  const bounds = new L.LatLngBounds(options.bounds);
  if (options.cluster) {
    const group = L.markerClusterGroup();
    for (const marker of data) {
      const markerOptions = {
        iconShape: 'marker',
        backgroundColor: options.marker_color,
        borderColor: 'white',
        borderWidth: 2,
      };
      if (marker.highlight) {
        markerOptions.borderColor = options.highlight_color;
      }
      const m = L.marker(marker.lat_lon, { icon: L.BeautifyIcon.icon(markerOptions) });
      if (options.link) {
        m.bindPopup(marker.label.join('<br />'));
        m.on('click', function () {
          this.openPopup();
        });
      } else {
        m.bindTooltip(marker.label.join('<br />'), { permanent: options.permanent });
      }
      group.addLayer(m);
    }
    map.addLayer(group);
    map.fitBounds(bounds);
  } else {
    for (const marker of data) {
      const markerOptions = {
        iconShape: 'marker',
        backgroundColor: options.marker_color,
        borderColor: 'white',
        borderWidth: 2,
      };
      const m = L.marker(marker.lat_lon, { icon: L.BeautifyIcon.icon(markerOptions) });
      if (options.link) {
        m.bindPopup(marker.label);
        m.on('click', function () {
          this.openPopup();
        });
      } else {
        m.bindTooltip(marker.label, { permanent: options.permanent });
      }
      m.addTo(map);
    }
    if (data.length === 1) {
      map.setView(data[0].lat_lon, 13);
    } else {
      map.fitBounds(bounds);
    }
  }
  return map;
}
