# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  # While standard Delayed Job workers run in a single-threaded process,
  # thread-safety will support future threaded worker configurations
  # and parallelized test environments.
  @registry_mutex = Mutex.new
  @active_workers = {}.compare_by_identity # { thread_object => worker_instance }

  class << self
    attr_reader :registry_mutex

    def register_worker(worker)
      @registry_mutex.synchronize do
        @active_workers[Thread.current] = worker
      end
    end

    def unregister_worker
      @registry_mutex.synchronize do
        @active_workers.delete(Thread.current)
      end
    end

    def current_worker_stopping?
      worker = nil
      @registry_mutex.synchronize do
        worker = @active_workers[Thread.current]
      end

      worker&.stop? || false
    end

    # For testing purposes
    def reset!
      @registry_mutex.synchronize do
        @active_workers = {}.compare_by_identity
      end
    end
  end

  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, _job, &block|
      SignalHandlerPlugin.register_worker(worker)
      block&.call
    ensure
      SignalHandlerPlugin.unregister_worker
    end
  end
end

class DelayedJobJobIdProvider < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      # job.id is the ID of the Delayed::Job record in the database
      job.payload_object.job_data['provider_job_id'] = job.id if job.payload_object.respond_to?(:job_data)
    end
  end
end

Delayed::Worker.plugins << DelayedJobJobIdProvider unless Delayed::Worker.plugins.include?(DelayedJobJobIdProvider)
Delayed::Worker.plugins << SignalHandlerPlugin unless Delayed::Worker.plugins.include?(SignalHandlerPlugin)
