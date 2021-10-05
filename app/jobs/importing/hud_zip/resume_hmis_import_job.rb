###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class ResumeHmisImportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(import_id:)
      import = GrdaWarehouse::ImportLog.find(import_id.to_i)
      importer = HmisCsvImporter::Importer::Importer.new(
        loader_id: import.loader_log.id,
        data_source_id: import.data_source_id,
      )
      importer.importer_log = import.importer_log
      importer.resume!
    end

    def max_attempts
      1
    end
  end
end
