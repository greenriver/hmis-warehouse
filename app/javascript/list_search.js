import ListSearchController from './controllers/list_search_controller.js'

// This file is a specific entrypoint for the Role Table page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("list-search", ListSearchController)
}
