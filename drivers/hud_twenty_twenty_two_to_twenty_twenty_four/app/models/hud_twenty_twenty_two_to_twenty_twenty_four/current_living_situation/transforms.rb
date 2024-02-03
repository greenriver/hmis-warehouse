###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation::AddSubsidyType,
        HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation::ChangeLivingSituation, # Done last as it overwrites the old CLS value
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::CurrentLivingSituation
    end
  end
end
