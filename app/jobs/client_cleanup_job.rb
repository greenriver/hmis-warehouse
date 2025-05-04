###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientCleanupJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority 6

  WAIT_MINUTES = 1

  def perform(ids)
    running_jobs = Delayed::Job.jobs_for_class('ClientCleanupJob').running.count
    # allow up to 2 jobs to run at once, to avoid overwhelming the workers
    if running_jobs > 1

      requeue_job
      return
    end

    GrdaWarehouse::Tasks::ClientCleanup.run_for_clients(ids)
  end

  private def requeue_job
    # Re-queue this job before processing if another report is running for the same class
    # This should help prevent tying up delayed job workers when someone kicks off a dozen of the same report.
    a_t = Delayed::Job.arel_table
    job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
    return unless job_object

    Rails.logger.info("ClientCleanupJob already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
    new_job = job_object.dup
    new_job.update(
      locked_at: nil,
      locked_by: nil,
      run_at: Time.current + WAIT_MINUTES.minutes,
      attempts: 0,
    )
  end

  def priority
    6
  end
end
