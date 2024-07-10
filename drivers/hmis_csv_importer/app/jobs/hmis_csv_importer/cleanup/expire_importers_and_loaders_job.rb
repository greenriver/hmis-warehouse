###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Cleanup
  class ExpireImportersAndLoadersJob < ExpireBaseJob
    protected

    # Sequential processing so we don't use quite as many resources at a time
    def perform(dry_run: false)
      HmisCsvImporter::Cleanup::ExpireLoadersJob.perform_now(dry_run: dry_run)
      HmisCsvImporter::Cleanup::ExpireImportersJob.perform_now(dry_run: dry_run)
    end
  end
end
