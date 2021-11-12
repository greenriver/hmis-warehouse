###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceHistory::Builder
  extend ActiveSupport::Concern

  # Default maximum wait time (6 hours)
  DEFAULT_MAX_WAIT_SECONDS = 21_600

  # Advisory lock name
  ADVISORY_LOCK_NAME = 'rebuild_enrollments'.freeze

  # Queue delayed jobs for the enrollments associated with destination clients
  #
  # @param client_ids A destination client id, or an array of destination client ids
  def queue_clients(client_ids)
    self.class.queue_clients(client_ids)
  end

  # Wait until there are no queued enrollment processing jobs for the enrollments associated with
  # destination client ids.
  #
  # @param client_ids A destination client id, or an array of destination client ids
  # @param interval [Integer] The number of seconds between queries
  # @param max_wait_seconds [Integer] The maximum number of seconds to wait
  def wait_for_clients(client_ids:, interval: 30, max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
    self.class.wait_for_clients(client_ids: client_ids, interval: interval, max_wait_seconds: max_wait_seconds)
  end

  # Test to see if there are queued enrollment processing jobs for the enrollments associated
  # with destination client ids.
  #
  # @param client_ids A destination client id, or an array of destination client ids
  # @return [Boolean] is any of the client's enrollment processing incomplete?
  def clients_still_processing?(client_ids:)
    self.class.clients_still_processing?(client_ids: client_ids)
  end

  class_methods do
    # Queue delayed jobs for processing enrollments.
    #
    # @param scope [GrdaWarehouse::Hud::Enrollment::ActiveRecord_Relation] A *GrdaWarehouse::Hud::Enrollment* scope
    def queue_enrollments(scope)
      GrdaWarehouse::Hud::Enrollment.with_advisory_lock(ADVISORY_LOCK_NAME) do
        builder_create_enrollment_jobs(scope)
      end
    end

    # Wait until there are no queued enrollment processing jobs.
    #
    # @param interval [Integer] The number of seconds between queries
    # @param max_wait_seconds [Integer] The maximum number of seconds to wait
    def wait_for_processing(interval: 30, max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
      if Rails.env.test?
        # you must manually process these in the test environment since there are no workers
        Delayed::Worker.new.work_off(2)
      else
        started = Time.current
        while builder_batch_job_scope.exists?
          break if (Time.current - started) > max_wait_seconds

          sleep(interval)
        end
      end
    end

    # Queue delayed jobs for the enrollments associated with destination clients
    #
    # @param client_ids A destination client id, or an array of destination client ids
    def queue_clients(client_ids)
      client_ids = Array.wrap(client_ids)

      GrdaWarehouse::Hud::Enrollment.with_advisory_lock(ADVISORY_LOCK_NAME) do
        # Force rebuilds for any clients with invalidated service histories

        GrdaWarehouse::Hud::Client.destination.where(id: client_ids).find_each do |client|
          client.force_full_service_history_rebuild if client.service_history_invalidated?
        end

        enrollment_ids = builder_client_enrollment_ids(client_ids)
        builder_create_enrollment_jobs(GrdaWarehouse::Hud::Enrollment.where(id: enrollment_ids))
      end
    end

    # Wait until there are no queued enrollment processing jobs for the enrollments associated with
    # destination client ids.
    #
    # @param client_ids A destination client id, or an array of destination client ids
    # @param interval [Integer] The number of seconds between queries
    # @param max_wait_seconds [Integer] The maximum number of seconds to wait
    def wait_for_clients(client_ids:, interval: 30, max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
      if Rails.env.test?
        # you must manually process these in the test environment since there are no workers
        Delayed::Worker.new.work_off(2)
      else
        started = Time.current
        while clients_still_processing?(client_ids: client_ids)
          break if (Time.current - started) > max_wait_seconds

          sleep(interval)
        end
      end
    end

    # Test to see if there are queued enrollment processing jobs for the enrollments associated
    # with destination client ids.
    #
    # @param client_ids A destination client id, or an array of destination client ids
    # @return [Boolean] is any of the client's enrollment processing incomplete?
    def clients_still_processing?(client_ids:)
      client_ids = Array.wrap(client_ids)

      GrdaWarehouse::Hud::Enrollment.where(
        id: builder_client_enrollment_ids(client_ids),
        service_history_processing_job_id: builder_batch_job_scope.pluck(:id),
      ).exists?
    end

    # Class method
    private def builder_batch_job_scope
      Delayed::Job.where(failed_at: nil).jobs_for_class('ServiceHistory::RebuildEnrollments')
    end

    # Class method
    private def builder_client_enrollment_ids(client_ids)
      GrdaWarehouse::Hud::Client.
        destination.
        where(id: client_ids).
        joins(source_enrollments: :project).
        select(Arel.sql(e_t[:id].to_sql))
    end

    # Class method
    private def builder_create_enrollment_jobs(scope)
      en_ids = scope.distinct.joins(:project, :destination_client).pluck(:id).uniq
      already_queued = Set.new
      builder_batch_job_scope.each do |dj|
        en_ids = dj.payload_object.instance_variable_get(:@enrollment_ids)
        already_queued += en_ids
      end
      en_ids -= already_queued.to_a
      Rails.logger.info "Found #{en_ids.count} enrollments needing processing"
      en_ids.each_slice(250) do |batch|
        Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running))
        # GrdaWarehouse::Hud::Enrollment.where(id: batch).update_all(service_history_processing_job_id: job.id)
      end
    end
  end
end
