import MetricThresholdChartController from './controllers/metric_threshold_chart_controller.js'

// This file is a specific entrypoint for the Metric Definition pages.
// It assumes that `window.application` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("metric-threshold-chart", MetricThresholdChartController)
}
