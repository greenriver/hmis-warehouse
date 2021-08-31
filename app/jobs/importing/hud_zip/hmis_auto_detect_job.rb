###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class HmisAutoDetectJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(upload_id:, data_source_id:, deidentified: false, project_whitelist: false)
      @upload_id = upload_id
      @data_source_id = data_source_id
      @deidentified = deidentified
      @project_whitelist = project_whitelist
    end

    def perform
      importer = Importers::HmisAutoDetect::UploadedZip.new(
        data_source_id: @data_source_id,
        upload_id: @upload_id,
        deidentified: @deidentified,
        allowed_projects: @project_whitelist,
      )
      importer.import!
    end

    def enqueue(job)
    end

    def max_attempts
      1
    end
  end
end
