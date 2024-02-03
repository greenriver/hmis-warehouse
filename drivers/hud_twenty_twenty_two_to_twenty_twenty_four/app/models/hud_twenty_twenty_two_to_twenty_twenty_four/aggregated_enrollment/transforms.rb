###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
