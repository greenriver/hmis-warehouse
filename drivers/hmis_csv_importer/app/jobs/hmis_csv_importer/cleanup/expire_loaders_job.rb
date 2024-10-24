###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Cleanup
  class ExpireLoadersJob < ExpireBaseJob
    protected

    def log_id_field
      :loader_id
    end

    def log_model
      ::HmisCsvImporter::Loader::LoaderLog
    end

    def models
      (
        ::HmisCsvTwentyTwentyFour.expiring_loader_classes +
        ::HmisCsvTwentyTwentyTwo.expiring_loader_classes +
        ::HmisCsvTwentyTwenty.expiring_loader_classes
      )
    end
  end
end
