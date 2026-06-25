###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment::RenameR13Columns,
        HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment::UpdateR7Columns,
      ]
    end

    def self.target_class
      HmisCsvImporter::Aggregated::Enrollment
    end
  end
end
