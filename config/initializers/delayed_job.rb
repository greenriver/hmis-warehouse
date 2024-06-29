Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 30.hours

Delayed::Worker.default_queue_name = 'default_priority'
Delayed::Worker.read_ahead = 2
Delayed::Worker.queue_attributes = {
  short_running: { priority: -5 },
  default_priority: { priority: 0 },
  long_running: { priority: 5 },
}

# Monkey patch so Delayed::Worker knows where it started
# Delayed::Worker::Deployment.deployed_to
module Delayed
  class Worker
    class Deployment
      def self.deployed_to
        if Rails.env.development? || Rails.env.test?
          File.realpath(FileUtils.pwd)
        else
          Dir.glob(File.join(File.dirname(File.realpath(FileUtils.pwd)), '*')).max_by{|f| File.mtime(f)}
        end
      end
    end
  end
  # class Job
  #   def self.jobs_for_class(handlers)
  #     handlers = Array.wrap(handlers)
  #     sql = arel_table[:id].eq(0) # This will never happen
  #     handlers.each do |handler|
  #       sql = sql.or(arel_table[:handler].matches("%#{handler}%"))
  #     end
  #     where(sql)
  #   end
  # end
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        def self.jobs_for_class(handlers)
          handlers = Array.wrap(handlers)
          sql = arel_table[:id].eq(0) # This will never happen
          handlers.each do |handler|
            sql = sql.or(arel_table[:handler].matches("%#{handler}%"))
          end
          where(sql)
        end

        # You can pass things you'd like to match that exist within the handlers column
        # Often this is something like ['ClassName', 'method_name'] which will check to see
        # if there's a call to ClassName.method_name in the handler
        def self.queued?(handlers)
          return false if handlers.blank?

          handlers = Array.wrap(handlers)
          scope = where(failed_at: nil, locked_at: nil)
          handlers.each do |handler|
            scope = scope.jobs_for_class(handler)
          end
          scope.exists?
        end

        def self.running?(handlers)
          return false if handlers.blank?

          handlers = Array.wrap(handlers)
          scope = where(failed_at: nil).where.not(locked_at: nil)
          handlers.each do |handler|
            scope = scope.jobs_for_class(handler)
          end
          scope.exists?
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
