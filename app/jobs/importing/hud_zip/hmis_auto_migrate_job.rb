###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class HmisAutoMigrateJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 15

    # When you call jobs with .perform_later, they are executed in the ActiveJob world, which doesn't
    # obey they max_attempts for Delayed Job.  We'll adjust the attempts to give us what we want
    after_enqueue :enforce_max_attempts

    def perform(upload_id:, data_source_id:, deidentified: false, allowed_projects: false)
      lock_obtained = GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_name(data_source_id), timeout_seconds: 2) do
        importer = Importers::HmisAutoMigrate::UploadedZip.new(
          data_source_id: data_source_id,
          upload_id: upload_id,
          deidentified: deidentified,
          allowed_projects: allowed_projects,
        )
        importer.import!
      end

      # when this exits, it will remove the current job from the queue, so add a new one to replace it
      requeue_at(Time.current + WAIT_MINUTES.minutes, "Import of Data Source: #{data_source_id} already running...re-queuing job for #{WAIT_MINUTES} minutes from now") unless lock_obtained
    end

    private def advisory_lock_name(data_source_id)
      GrdaWarehouse::DataSource.import_advisory_lock_name(data_source_id)
    end

    def enforce_max_attempts
      delayed_job.update!(attempts: calculated_attempts)
    end

    def calculated_attempts
      dj_max_attempts = Delayed::Worker.max_attempts
      max_attempts = 1
      return 0 if max_attempts >= dj_max_attempts

      dj_max_attempts - max_attempts
    end
  end
end
