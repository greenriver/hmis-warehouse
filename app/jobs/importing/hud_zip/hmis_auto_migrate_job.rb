###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Importing::HudZip
  class HmisAutoMigrateJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 15

    def supports_idempotent_retry?
      false
    end

    def perform(upload_id:, data_source_id:, deidentified: false, allowed_projects: false, stop_version: nil, dry_run: false)
      lock_obtained = nil
      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_name(data_source_id), timeout_seconds: 60) do
        importer = Importers::HmisAutoMigrate::UploadedZip.new(
          data_source_id: data_source_id,
          upload_id: upload_id,
          deidentified: deidentified,
          allowed_projects: allowed_projects,
          stop_version: stop_version,
          dry_run: dry_run,
        )
        importer.import!
        lock_obtained = true
      end

      # when this exits, it will remove the current job from the queue, so add a new one to replace it
      requeue_at(Time.current + WAIT_MINUTES.minutes, "Import of Data Source: #{data_source_id} already running...re-queuing job for #{WAIT_MINUTES} minutes from now") unless lock_obtained
    end

    private def advisory_lock_name(data_source_id)
      GrdaWarehouse::DataSource.import_advisory_lock_name(data_source_id)
    end
  end
end
