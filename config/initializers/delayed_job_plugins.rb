###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  class << self
    def current_worker_stopping?
      # Use thread-local storage directly. This is safer and more idiomatic
      # than a custom registry.
      worker = Thread.current[:delayed_job_worker]
      worker&.stop? || false
    end

    # Tell the worker bound to this thread to stop reserving new jobs and exit
    # after the current one. The process exits, and Kubernetes recreates the pod
    # with a freshly-rotated IRSA web-identity token.
    def stop_current_worker!(reason)
      worker = Thread.current[:delayed_job_worker]
      return unless worker

      Rails.logger.error("[delayed_job] stopping #{worker.name}: #{reason}")
      worker.stop
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

# When the worker's *ambient* AWS credentials are dead (expired IRSA web-identity
# token, missing creds), every job this worker reserves will fail identically and
# poison the queue. Detect that class of error and stop the worker so the pod is
# recycled. This is the catch-all; individual jobs may handle it more gracefully first.
class AwsCredentialFailurePlugin < Delayed::Plugin
  # Match by name + walk the cause chain so we catch wrapped errors and don't
  # depend on AWS constants being autoloaded at initializer-load time.
  CREDENTIAL_ERROR_NAMES = [
    'Aws::STS::Errors::ExpiredTokenException',
    'Aws::STS::Errors::InvalidIdentityToken',
    'Aws::Errors::MissingCredentialsError',
  ].freeze

  def self.credential_failure?(error)
    err = error
    while err
      return true if CREDENTIAL_ERROR_NAMES.include?(err.class.name)

      err = err.cause
    end
    false
  end

  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |_job, &block|
      block.call
    rescue StandardError => e
      SignalHandlerPlugin.stop_current_worker!("AWS credential failure (#{e.class})") if AwsCredentialFailurePlugin.credential_failure?(e)
      raise # let delayed_job record the failure and reschedule as usual
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
Delayed::Worker.plugins << AwsCredentialFailurePlugin unless Delayed::Worker.plugins.include?(AwsCredentialFailurePlugin)
