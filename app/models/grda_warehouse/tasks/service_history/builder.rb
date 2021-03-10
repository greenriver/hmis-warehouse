###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ServiceHistory
  class Builder
    # Default maximum wait time (6 hours)
    DEFAULT_MAX_WAIT_SECONDS = 21_600

    # Queue delayed jobs for processing enrollments.
    #
    # @param scope [ActiveRecord Scope] A GrdaWarehouse::Hud::Enrollment scope
    def self.queue_enrollments(scope)
      GrdaWarehouse::Hud::Enrollment.with_advisory_lock('rebuild_enrollments') do
        create_enrollment_jobs(scope)
      end
    end

    # Wait until there are no queued enrollment processing jobs.
    #
    # @param interval [Integer] The number of seconds between queries
    # @param max_wait_seconds [Integer] The maximum number of seconds to wait
    def self.wait_for_processing(interval: 30, max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
      if Rails.env.test?
        # you must manually process these in the test environment since there are no workers
        Delayed::Worker.new.work_off(2)
      else
        started = Time.current
        while batch_job_scope.exists? do
          break if (Time.current - started) > max_wait_seconds

          sleep(interval)
        end
      end
    end

    # Queue delayed jobs for the enrollments associated with destination clients
    #
    # @param client_ids A destination client id, or an array of destination client ids
    def self.queue_clients(client_ids)
      client_ids = [client_ids] if client_ids.is_a? Integer # Wrap single client_ids

      GrdaWarehouse::Hud::Enrollment.with_advisory_lock('rebuild_enrollments') do
        # Force rebuilds for any clients with invalidated service histories
        client_ids.find_each do |client_id|
          client = GrdaWarehouse::Hud::Client.destination.find(client_id)
          next if client.blank?

          client.force_full_service_history_rebuild if client.service_history_invalidated?
        end

        enrollment_ids = client_enrollment_ids(client_ids)
        create_enrollment_jobs(GrdaWarehouse::Hud::Enrollment.where(id: enrollment_ids))
      end
    end

    # Wait until there are no queued enrollment processing jobs for the enrollments associated with
    # destination client ids.
    #
    # @param client_ids A destination client id, or an array of destination client ids
    # @param interval [Integer] The number of seconds between queries
    # @param max_wait_seconds [Integer] The maximum number of seconds to wait
    def self.wait_for_clients(client_ids:, interval: 30, max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
      client_ids = [client_ids] if client_ids.is_a? Integer # Wrap single client_ids

      if Rails.env.test?
        # you must manually process these in the test environment since there are no workers
        Delayed::Worker.new.work_off(2)
      else
        enrollments_scope = GrdaWarehouse::Hud::Enrollment.where(
          id: enrollment_ids(client_ids),
          service_history_processing_job_id: batch_job_scope.select(:id),
        )
        while enrollments_scope.exists? do
          break if (Time.current - started) > max_wait_seconds

          sleep(interval)
        end
      end
    end

    private def self.batch_job_scope
      @batch_job_scope ||= Delayed::Job.where(queue: ::ServiceHistory::RebuildEnrollmentsByBatchJob.queue_name, failed_at: nil).
        jobs_for_class('ServiceHistory::RebuildEnrollments')
    end

    private def self.client_enrollment_ids(client_ids)
      GrdaWarehouse::Hud::Client.
        destination.
        where(id: client_ids).
        joins(source_enrollments: :project).
        select(Arel.sql(e_t[:id].to_sql))
    end

    private def self.create_enrollment_jobs(scope)
      scope.unassigned.joins(:project, :destination_client).
        pluck_in_batches(:id, batch_size: 250) do |batch|
          job = Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch))
          where(id: batch).update_all(service_history_processing_job_id: job.id)
      end
    end
  end
end
