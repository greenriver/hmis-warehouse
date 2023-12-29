desc 'expose log processor job for cron-job'
task process_activity_logs: [:environment] do
  Hmis::ActivityLogProcessorJob.perform_now
end
