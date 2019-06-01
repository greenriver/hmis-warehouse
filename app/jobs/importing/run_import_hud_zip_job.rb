###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class RunImportHudZipJob < BaseJob
    queue_as :low_priority

    def perform upload:
      Importers::HMISFiveOne::UploadedZip.new(data_source_id: upload.data_source_id, upload_id: upload.id).import!
    end
  end
end