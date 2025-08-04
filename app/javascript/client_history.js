import ClientHistoryController from './controllers/client_history_controller.js'

// This file is a specific entrypoint for the client history calendar.
// It assumes that `window.application` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("client-history", ClientHistoryController)
}
