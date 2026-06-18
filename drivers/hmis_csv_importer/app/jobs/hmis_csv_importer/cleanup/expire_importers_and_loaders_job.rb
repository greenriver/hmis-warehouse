###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Cleanup
  class ExpireImportersAndLoadersJob < ExpireBaseJob
    protected

    # Sequential processing so we don't use quite as many resources at a time
    def perform(options)
      HmisCsvImporter::Cleanup::ExpireLoadersJob.perform_now(**options)
      HmisCsvImporter::Cleanup::ExpireImportersJob.perform_now(**options)
    end
  end
end
