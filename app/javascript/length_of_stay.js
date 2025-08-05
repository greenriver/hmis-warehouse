import LengthOfStayChartController from './controllers/length_of_stay_chart_controller.js'

// This file is a specific entrypoint for the Length of Stay report page.
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("length-of-stay-chart", LengthOfStayChartController)
}
