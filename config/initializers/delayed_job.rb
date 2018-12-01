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

# Monkey patch so Delayed::Worker knows where it started
# Delayed::Worker::Deployment.deployed_to
module Delayed
  class Worker
    class Deployment
      def self.deployed_to
        if Rails.env.development?
          File.realpath(FileUtils.pwd)
        else
          Dir.glob(File.join(File.dirname(File.realpath(FileUtils.pwd)), '*')).max_by{|f| File.mtime(f)}
        end
      end
    end
  end
end

root_folder = File.basename(Rails.root)
# If the root folder is all digits, we're probably on a deployed server
ENV['CURRENT_PATH'] = if /^\d+$/.match?(root_folder)
  Rails.root.to_s.gsub(File.join('releases', root_folder), 'current')
else
  Rails.root.to_s
end
if File.exists?(File.join(ENV['CURRENT_PATH'], 'REVISION'))
  ENV['GIT_REVISION'] = File.read(File.join(ENV['CURRENT_PATH'], 'REVISION'))&.strip
end