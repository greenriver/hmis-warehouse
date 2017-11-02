module Importing::HudZip
  class FiveOneJob < ActiveJob::Base
  
    def initialize upload_id:, data_source_id:
      @upload_id = upload_id
      @data_source_id = data_source_id
    end

    def perform
      Importers::HMISFiveOne::UploadedZip.new(
        data_source_id: @data_source_id, 
        upload_id: @upload_id
      ).import!
    end

    def enqueue(job, queue: :default_priority)
    end

    def max_attempts
      2
    end
  end
end