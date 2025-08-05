import CustomFilesController from './controllers/custom_files_controller.js'

// This file is a specific entrypoint for the HMIS CSV Exports page.
// It assumes that `window.application` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("custom-file-exports", CustomFilesController)
}
