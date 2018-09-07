Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.hours
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Worker.default_queue_name = 'default_priority'
Delayed::Worker.read_ahead = 2
Delayed::Worker.queue_attributes = {
  high_priority: { priority: -5 },
  default_priority: { priority: 0 },
  low_priority: { priority: 5 },
}

root_folder = File.basename(Rails.root)
path = if root_folder.to_i.to_s == root_folder
  Rails.root.to_s.gsub(root_folder, 'current')
else
  Rails.root
end
ENV['CURRENT_PATH'] = path.to_s.gsub(File.basename(Rails.root), 'current')
if File.exists?(File.join(ENV['CURRENT_PATH'], 'REVISION'))
  ENV['GIT_REVISION'] = File.read(ENV['CURRENT_PATH'])&.strip
end