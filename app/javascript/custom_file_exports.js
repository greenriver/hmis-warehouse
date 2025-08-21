import CustomFileExportsController from './controllers/custom_file_exports_controller.js'

// This file is a specific entrypoint for the HMIS CSV Exports page.
// It assumes that `window.application` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("custom-file-exports", CustomFileExportsController)
}
