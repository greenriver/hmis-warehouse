###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class HmisAutoMigrateJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 15

    def initialize(upload_id:, data_source_id:, deidentified: false, project_whitelist: false)
      @upload_id = upload_id
      @data_source_id = data_source_id
      @deidentified = deidentified
      @project_whitelist = project_whitelist
    end

    def before(job)
      # Re-queue this import before processing if another import is running for the same data_source
      # This should help prevent tying up delayed job workers that are really just waiting
      # for the previous import to complete
      @data_source_id = job.payload_object.instance_variable_get(:@data_source_id)
      return unless already_running_for_data_source?

      Rails.logger.info("Import of Data Source: #{@data_source_id} already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
      # when this exits, it will remove the current job from the queue, so add a new one to replace it
      new_job = job.dup
      new_job.update(
        locked_at: nil,
        locked_by: nil,
        run_at: Time.current + WAIT_MINUTES.minutes,
        attempts: 0,
      )
    end

    def perform
      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_name, timeout_seconds: 0) do
        importer = Importers::HmisAutoMigrate::UploadedZip.new(
          data_source_id: @data_source_id,
          upload_id: @upload_id,
          deidentified: @deidentified,
          allowed_projects: @project_whitelist,
        )
        importer.import!
      end
    end

    private def already_running_for_data_source?
      GrdaWarehouse::DataSource.advisory_lock_exists?(advisory_lock_name)
    end

    private def advisory_lock_name
      "hud_import_auto_migrate_#{@data_source_id}"
    end

    def enqueue(job)
    end

    def max_attempts
      1
    end
  end
end
