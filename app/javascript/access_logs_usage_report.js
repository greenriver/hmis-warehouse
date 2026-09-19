import AccessLogsUsageReportController from './controllers/access_logs_usage_report_controller.js'

// Entrypoint for the access_logs "Report Usage" tab. Assumes `window.application`
// has already been initialized by application_esbuild.js.
if (window.Stimulus) {
  window.Stimulus.register("access-logs-usage-report", AccessLogsUsageReportController)
}
