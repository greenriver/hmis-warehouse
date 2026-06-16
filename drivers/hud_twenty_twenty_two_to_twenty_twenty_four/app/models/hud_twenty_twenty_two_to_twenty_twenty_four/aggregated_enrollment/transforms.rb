###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment
  class Transforms
    def self.transforms(csv: false, db: false, references:) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment::AddRentalSubsidyType,
        [HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment::MoveEnrollmentCoC, references],
        HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment::ChangeLivingSituation, # Done last as it overwrites the old living situation value
      ]
    end

    def self.target_class
      HmisCsvImporter::Aggregated::Enrollment
    end
  end
end
