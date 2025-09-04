import { application } from './controllers/application';
import ClientFileRowController from './controllers/client_file_row_controller.js';

// This file is a specific entrypoint for the client file row controller.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("client-file-row", ClientFileRowController)
}

application.register('client-file-row', ClientFileRowController);
