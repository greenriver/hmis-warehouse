import { Controller } from '@hotwired/stimulus';
import MapWithShapes from '../maps/map_with_shapes';

export default class extends Controller {
  static values = {
    shapes: Array,
  };

  connect() {
    this.map = new MapWithShapes({
      elementId: this.element.id,
      shapes: this.shapesValue,
    });
  }
}
