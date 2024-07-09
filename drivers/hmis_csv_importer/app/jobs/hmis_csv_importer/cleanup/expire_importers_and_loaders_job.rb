###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Cleanup
  class ExpireImportersAndLoadersJob < ExpireBaseJob
    protected

    # Sequential processing so we don't use quite as many resources at a time
    def perform
      HmisCsvImporter::Cleanup::ExpireLoadersJob.perform_now
      HmisCsvImporter::Cleanup::ExpireImportersJob.perform_now
    end
  end
end
