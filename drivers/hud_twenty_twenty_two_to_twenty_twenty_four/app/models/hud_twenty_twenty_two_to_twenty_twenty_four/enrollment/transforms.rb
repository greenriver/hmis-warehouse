###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment
  class Transforms
    def self.transforms(csv: false, db: false, references:) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::AddRentalSubsidyType,
        [HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::MoveEnrollmentCoC, references],
        HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::AddNewColumns,
        HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::ChangeLivingSituation, # Done last as it overwrites the old living situation value
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Enrollment
    end
  end
end
