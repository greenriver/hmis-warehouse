import { application } from './controllers/application';
import CocOverlapController from './controllers/coc_overlap_controller.js';

// This file is a specific entrypoint for the CoC Overlap page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("coc-overlap", CocOverlapController)
}

application.register('coc-overlap', CocOverlapController);
