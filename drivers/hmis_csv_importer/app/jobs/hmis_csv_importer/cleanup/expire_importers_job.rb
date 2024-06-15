###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Cleanup
  class ExpireImportersJob < ExpireBaseJob
    protected

    def log_id_field
      :importer_log_id
    end

    def log_model
      ::HmisCsvImporter::Importer::ImporterLog
    end

    def models
      ::HmisCsvImporter::Importer::Importer.expiring_models
    end
  end
end
