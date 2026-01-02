# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  class << self
    def current_worker_stopping?
      # Use thread-local storage directly. This is safer and more idiomatic
      # than a custom registry.
      worker = Thread.current[:delayed_job_worker]
      worker&.stop? || false
    end
  end

  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, _job, &block|
      Thread.current[:delayed_job_worker] = worker
      block&.call
    ensure
      Thread.current[:delayed_job_worker] = nil
    end
  end
end

class DelayedJobJobIdProvider < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      # job.id is the ID of the Delayed::Job record in the database.
      # We only inject this into ActiveJob-style payloads that have a job_data hash.
      payload = job.payload_object
      if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
        # avoid mutation of job_date due as it crashes if frozen
        payload.job_data = payload.job_data.merge(
          'provider_job_id' => job.id,
        )
      end
    end
  end
end

Delayed::Worker.plugins << DelayedJobJobIdProvider unless Delayed::Worker.plugins.include?(DelayedJobJobIdProvider)
Delayed::Worker.plugins << SignalHandlerPlugin unless Delayed::Worker.plugins.include?(SignalHandlerPlugin)
