# frozen_string_literal: true

require_relative '../../lib/util/thread_safe_registry'

class SignalHandlerPlugin < Delayed::Plugin
  # While standard Delayed Job workers run in a single-threaded process,
  # thread-safety will support future threaded worker configurations
  # and parallelized test environments.
  @registry = ::ThreadSafeRegistry.new

  class << self
    attr_reader :registry

    def current_worker_stopping?
      @registry.current&.stop? || false
    end
  end

  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, _job, &block|
      SignalHandlerPlugin.registry.register(worker)
      block&.call
    ensure
      SignalHandlerPlugin.registry.unregister
    end
  end
end

class DelayedJobJobIdProvider < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      # job.id is the ID of the Delayed::Job record in the database.
      # We only inject this into ActiveJob-style payloads that have a job_data hash.
      payload = job.payload_object
      payload.job_data['provider_job_id'] = job.id if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
    end
  end
end

Delayed::Worker.plugins << DelayedJobJobIdProvider unless Delayed::Worker.plugins.include?(DelayedJobJobIdProvider)
Delayed::Worker.plugins << SignalHandlerPlugin unless Delayed::Worker.plugins.include?(SignalHandlerPlugin)
