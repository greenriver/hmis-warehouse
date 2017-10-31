Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.hours
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
Delayed::Worker.default_queue_name = :default
Delayed::Worker.queue_attributes = {
  high_priority: { priority: -5 },
  default: { priority: 0 },
  low_priority: { priority: 5 },
}