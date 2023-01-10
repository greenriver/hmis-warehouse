###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForceProjectEnrollmentCoc < Base
    def cleanup!
      # Do nothing, logic has been moved into ProjectCleanup
      # leaving this here so we don't throw an error when loading the importer extension page
    end

    def self.description
      '[DEPRECTED] Force Enrollment CoC to match Project CoC if Enrollment CoC is present'
    end

    def self.enable
    end
  end
end
