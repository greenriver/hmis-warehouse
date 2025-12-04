###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class ForceValidEnrollmentCoc < Base
    def cleanup!
      raise 'HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc is no longer active'
    end

    def enrollment_coc_scope
    end

    def enrollment_coc_source
    end

    def self.description
      'Fix Enrollment.CoCCode where possible, remove where not.'
    end

    def self.enable
      {
        import_cleanups: {
          'EnrollmentCoc': ['HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc'],
        },
      }
    end
  end
end
