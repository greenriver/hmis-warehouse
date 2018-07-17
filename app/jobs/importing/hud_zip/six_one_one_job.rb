module Importing::HudZip
  class SixOneOneJob < ActiveJob::Base
    queue_as :low_priority
  
    def initialize upload_id:, data_source_id:, deidentified: false 
      @upload_id = upload_id
      @data_source_id = data_source_id
      @deidentified = deidentified
    end

    def perform 
      Importers::HMISSixOneOne::UploadedZip.new(
        data_source_id: @data_source_id, 
        upload_id: @upload_id,
        deidentified: @deidentified,
      ).import!
    end

    def enqueue(job)
    end

    def max_attempts
      2
    end
  end
end
