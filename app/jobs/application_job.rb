###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Custom error to signal that a job should be stopped and discarded or retried
  class JobCancelled < StandardError; end
  class JobInterrupted < StandardError; end

  # discard_on is a standard Active Job feature
  # When JobCancelled is raised, Active Job catches it and prevents any retries.
  discard_on JobCancelled

  rescue_from JobInterrupted do |_error|
    # Re-enqueue on SIGTERM so work resumes after the worker shuts down.
    # Delay to avoid immediately re-running in the same worker loop.
    wait_time = ENV.fetch('RETRY_DELAY_ON_INTERRUPTION', 60).to_i
    retry_job wait: wait_time.to_i.seconds
  end

  # By default, jobs are not interruptible once they have started.
  # Subclasses can override this if they have implemented manual cancellation checkpoints.
  def self.interruptible?
    false
  end

  # Check for cancellation before the job starts performing.
  before_perform :check_halt_status!

  def check_halt_status!
    return unless self.class.queue_adapter_name == 'delayed_job'

    # Check for SIGTERM first
    if SignalHandlerPlugin.current_worker_stopping?
      msg = 'Job interrupted by SIGTERM'
      Rails.logger.warn(msg)
      raise JobInterrupted, msg
    end

    return unless provider_job_id.present?

    # Check for manual cancellation
    requested_at = nil
    Delayed::Job.uncached do
      requested_at = Delayed::Job.where(id: provider_job_id).pluck(:cancellation_requested_at).first
    end
    return unless requested_at

    msg = "Job #{provider_job_id} cancelled"
    Rails.logger.warn(msg)
    raise JobCancelled, msg
  end
end
