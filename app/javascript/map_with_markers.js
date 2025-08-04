import { application } from './controllers/application';
import MapWithMarkersController from './controllers/map_with_markers_controller.js';

if (window.Stimulus) {
  window.Stimulus.register("map-with-markers", MapWithMarkersController)
}

application.register('map-with-markers', MapWithMarkersController);
