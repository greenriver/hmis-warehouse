###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment::RenameR13Columns,
        HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment::UpdateR7Columns,
      ]
    end

    def self.target_class
      HmisCsvTwentyTwenty::Aggregated::Enrollment
    end
  end
end
