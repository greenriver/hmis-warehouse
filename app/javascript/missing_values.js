import MissingValuesChartController from './controllers/missing_values_chart_controller.js'

// This file is a specific entrypoint for the Missing Values report page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("missing-values-chart", MissingValuesChartController)
}
