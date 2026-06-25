###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Opt-in graceful handling for jobs that touch AWS/S3.
#
# When a job fails because the *worker's* ambient AWS credentials are dead (an expired
# IRSA web-identity token, missing creds) rather than because of anything the job did,
# we don't want to burn the job's (often limited) attempt budget on a problem that
# belongs to the pod. Wrap the AWS-touching work in `with_aws_credential_rescue` and,
# on a credential failure, we:
#   - requeue a fresh attempt for a healthy worker WITHOUT burning an attempt, then
#   - stop this worker so Kubernetes recycles the pod with a freshly-rotated token.
#
# Bounded: after MAX_CREDENTIAL_RESCHEDULES the failure is persistent (a misconfigured
# role/policy, not a transient token), so we re-raise and let it fail normally. The
# catch-all AwsCredentialFailurePlugin still stops the worker on the way out (so the pod
# recycles), and delayed_job records the failure in the failed queue + Sentry instead of
# looping forever.
#
# The reschedule counter rides along in the cloned job's serialized data (not a cache),
# so the bound is durable: a lost counter could only ever fail *open* into the very
# infinite loop this is meant to prevent.
module AwsCredentialRescue
  extend ActiveSupport::Concern

  # How many free (non-attempt-burning) reschedules before we give up and fail for real.
  MAX_CREDENTIAL_RESCHEDULES = 1
  # Default wait before the retry — long enough for the poisoned pod to be recycled.
  DEFAULT_CREDENTIAL_RESCHEDULE_WAIT = 15.minutes
  # Key under which the reschedule count travels in the job's serialized data.
  CREDENTIAL_RESCHEDULE_KEY = 'aws_credential_reschedules'

  # Run a block that talks to AWS, gracefully handling dead ambient worker credentials.
  # `context` is an optional label for logging (e.g. the data source being imported).
  # Returns :rescheduled when it handled a credential failure, otherwise the block's value.
  # NOTE: on the handled path the block's own return value is discarded in favor of the
  # :rescheduled sentinel — callers that need the block's value must not rely on it here.
  def with_aws_credential_rescue(wait: DEFAULT_CREDENTIAL_RESCHEDULE_WAIT, context: nil)
    yield
  rescue StandardError => e
    raise unless AwsCredentialFailurePlugin.credential_failure?(e)

    count = aws_credential_reschedule_count
    # We already gave it a fresh worker and it failed again -> persistent, let it surface.
    raise if count >= MAX_CREDENTIAL_RESCHEDULES

    label = [self.class.name, context].compact.join(' ')
    rescheduled = reschedule_after_credential_failure(
      wait: wait,
      next_count: count + 1,
      message: "AWS credentials unusable (#{e.class}) for #{label}; requeuing " \
               "(reschedule #{count + 1}/#{MAX_CREDENTIAL_RESCHEDULES})",
    )
    # We couldn't find our own job row to clone (extreme edge case, e.g. the row was
    # deleted mid-run). Re-raise so the failure is recorded normally rather than silently
    # dropped; the catch-all plugin still stops the worker on the way out.
    raise unless rescheduled

    SignalHandlerPlugin.stop_current_worker!("AWS credential failure (#{e.class})")
    :rescheduled
  end

  private

  # How many times this job has already been rescheduled for a credential failure,
  # read from the running job's serialized data (0 on the first run).
  def aws_credential_reschedule_count
    payload = delayed_job&.payload_object
    job_data = payload.respond_to?(:job_data) ? payload.job_data : nil
    return 0 unless job_data.is_a?(Hash)

    job_data[CREDENTIAL_RESCHEDULE_KEY].to_i
  end

  # Clone the current Delayed::Job into a fresh, future-scheduled attempt (no burned
  # attempt, cleared failure metadata) carrying the incremented reschedule count in its
  # serialized data. Mirrors BaseJob#requeue_at, but re-serializes the payload so the
  # counter travels with the clone (same job_data-merge trick as DelayedJobJobIdProvider).
  # Returns true when a clone was scheduled, false when the job row couldn't be found.
  def reschedule_after_credential_failure(wait:, next_count:, message:)
    dj = delayed_job
    unless dj.present?
      Sentry.capture_message("Unable to find delayed_job for credential reschedule in #{self.class.name} (AJ ID: #{job_id}, Provider ID: #{provider_job_id})")
      return false
    end

    Rails.logger.info(message)
    new_job = dj.dup
    payload = new_job.payload_object
    if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
      payload.job_data = payload.job_data.merge(CREDENTIAL_RESCHEDULE_KEY => next_count)
      new_job.payload_object = payload
    end
    new_job.update(
      locked_at: nil,
      locked_by: nil,
      failed_at: nil,
      last_error: nil,
      run_at: Time.current + wait,
      attempts: calculated_attempts,
    )
    true
  end
end
