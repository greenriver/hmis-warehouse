import DataSourceFormController from './controllers/data_source_form_controller.js'

// Entrypoint for the data source create/edit form.
// Assumes window.Stimulus was initialized by application_esbuild.js.
if (window.Stimulus) {
  window.Stimulus.register('data-source-form', DataSourceFormController)
}
