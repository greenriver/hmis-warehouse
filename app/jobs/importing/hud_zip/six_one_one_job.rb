module Importing::HudZip
  class SixOneOneJob < ActiveJob::Base
  
    def initialize upload:
      @upload = upload
    end

    def perform 
      Importers::HMISSixOneOne::UploadedZip.new(
        data_source_id: @upload.data_source_id, 
        upload_id: @upload.id
      ).import!
    end

    def enqueue(job)
    end
  end
end