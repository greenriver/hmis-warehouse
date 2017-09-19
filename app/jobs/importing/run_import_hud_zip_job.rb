module Importing
  class RunImportHudZipJob < ActiveJob::Base
  
    def perform upload:
      Importers::HMISFiveOne::UploadedZip.new(data_source_id: upload.data_source_id, upload_id: upload.id).import!
    end
  end
end