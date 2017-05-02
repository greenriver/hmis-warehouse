module Importing
  class RunImportHudZipJob < ActiveJob::Base
  
    def perform upload:
      Importers::UploadedZip.new(upload_id: upload.id).run! 
    end
  end
end