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

    # Depending on your installation cleanup needs, you may also want to expire older versions
    # ::HmisCsvTwentyTwentyTwo.expiring_importer_classes
    # ::HmisCsvTwentyTwenty.expiring_importer_classes
    def models
      ::HmisCsvTwentyTwentyFour.expiring_importer_classes
    end
  end
end
