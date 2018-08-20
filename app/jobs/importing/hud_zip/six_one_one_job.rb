module Importing::HudZip
  class SixOneOneJob < ActiveJob::Base
    queue_as :low_priority

    def initialize upload_id:, data_source_id:, deidentified: false, project_whitelist: false
      @upload_id = upload_id
      @data_source_id = data_source_id
      @deidentified = deidentified
      @project_whitelist = project_whitelist
    end

    def perform
      importer = Importers::HMISSixOneOne::UploadedZip.new(
        data_source_id: @data_source_id,
        upload_id: @upload_id,
        deidentified: @deidentified,
        project_whitelist: @project_whitelist
      )
      importer.pre_process! if @project_whitelist
      importer.import!
    end

    def enqueue(job)
    end

    def max_attempts
      1
    end
  end
end
