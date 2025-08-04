import { Controller } from '@hotwired/stimulus';
import { createMapWithMarkers } from '../maps/map_with_markers';

export default class extends Controller {
  static values = {
    markers: Array,
    options: Object,
  };

  connect() {
    createMapWithMarkers(
      this.element.id,
      this.markersValue,
      this.optionsValue
    );
  }
}
