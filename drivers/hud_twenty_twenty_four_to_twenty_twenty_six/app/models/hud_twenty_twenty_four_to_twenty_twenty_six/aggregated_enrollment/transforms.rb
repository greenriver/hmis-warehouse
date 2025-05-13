###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::AggregatedEnrollment
  class Transforms
    def self.transforms(csv: false, db: false, references:) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyFourToTwentyTwentySix::AggregatedEnrollment::AddRentalSubsidyType,
        [HudTwentyTwentyFourToTwentyTwentySix::AggregatedEnrollment::MoveEnrollmentCoC, references],
        HudTwentyTwentyFourToTwentyTwentySix::AggregatedEnrollment::ChangeLivingSituation, # Done last as it overwrites the old living situation value
      ]
    end

    def self.target_class
      HmisCsvImporter::Aggregated::Enrollment
    end
  end
end
