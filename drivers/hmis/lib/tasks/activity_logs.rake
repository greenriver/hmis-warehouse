desc 'expose log processor job for cron-job'
task process_access_logs: [:environment] do
  Hmis::AccessLogProcessorJob.perform_now
end
