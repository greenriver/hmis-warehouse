###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UpdateWarehouseClientsCachesJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  WAIT_MINUTES = 4

  def perform(client_ids: [], include_cas_and_cohorts: false, skip_expensive_calculations: false)
    # If any for this class are already running, requeue for a few minutes in the future
    any_jobs_of_type_other_than_self = Delayed::Job.jobs_for_class(self.class.name).
      running.
      where.not(Delayed::Job.arel_table[:handler].matches("%#{job_id}%")).
      exists?
    return requeue_job if any_jobs_of_type_other_than_self

    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids, include_cas_and_cohorts: include_cas_and_cohorts, skip_expensive_calculations: skip_expensive_calculations)
  end

  private def requeue_job
    # Re-queue this job if there is another already running with the same class name.
    # There is a potential for a race condition here and multiple may end up running at the same time if they are all picked up
    # before any have been marked as running.  This is ok, we're just trying to limit it from using the entire DJ workforce
    a_t = Delayed::Job.arel_table
    job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
    return unless job_object

    Rails.logger.info("UpdateWarehouseClientsCachesJob is already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
    new_job = job_object.dup
    new_job.update(
      locked_at: nil,
      locked_by: nil,
      run_at: Time.current + WAIT_MINUTES.minutes,
      attempts: 0,
    )
  end
end
