###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedExit
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedExit::AddDestinationSubsidyType,
        HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedExit::UpdateDestination, # Done last as it overwrites destination
      ]
    end

    def self.target_class
      HmisCsvImporter::Aggregated::Exit
    end
  end
end
