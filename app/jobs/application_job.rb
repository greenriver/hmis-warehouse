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
    wait_time = ENV.fetch('RETRY_DELAY_ON_INTERRUPTION', 60)
    retry_job wait: wait_time.to_i.seconds
  end

  # By default, jobs are not interruptible once they have started.
  # Subclasses can override this if they have implemented manual cancellation checkpoints.
  def self.interruptible?
    false
  end

  # Check for cancellation before the job starts performing.
  before_perform :check_halt_status!

  protected

  def check_halt_status!
    return unless self.class.queue_adapter_name == 'delayed_job'
    return unless provider_job_id.present?

    # provider_job_id is the ID of the Delayed::Job record in the database.
    # We look up the record to check its specific cancellation state.
    job = Delayed::Job.find_by(id: provider_job_id)

    # This calls the check_halt_status! method defined in the Delayed::Job monkey patch
    # (see config/initializers/delayed_job.rb), which raises JobCancelled if
    # cancellation_requested_at is set.
    job&.check_halt_status!
  end
end
