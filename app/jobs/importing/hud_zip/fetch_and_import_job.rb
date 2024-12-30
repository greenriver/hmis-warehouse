###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class FetchAndImportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 4

    def perform(klass:, options:)
      safe_klass = known_classes.detect { |m| klass == m }
      raise "Unknown import class: #{klass}; You must add it to the list of known classes in FetchAndImportJob" unless safe_klass.present?

      data_source_id = options.with_indifferent_access[:data_source_id]
      lock_obtained = GrdaWarehouse::DataSource.with_advisory_lock("#{klass}_#{data_source_id}", timeout_seconds: 10) do
        safe_klass.constantize.new(**options).import!
      end

      requeue_job(data_source_id) unless lock_obtained
    end

    def max_attempts
      1
    end

    def known_classes
      [
        'Importers::HmisAutoMigrate::S3',
      ].freeze
    end

    private def requeue_job(data_source_id)
      # Re-queue this import for a few minutes later
      a_t = Delayed::Job.arel_table
      job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
      return unless job_object

      Rails.logger.info("Import for Data Source #{data_source_id} already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
      new_job = job_object.dup
      new_job.update(
        locked_at: nil,
        locked_by: nil,
        run_at: Time.current + WAIT_MINUTES.minutes,
        attempts: 0,
      )
    end
  end
end
