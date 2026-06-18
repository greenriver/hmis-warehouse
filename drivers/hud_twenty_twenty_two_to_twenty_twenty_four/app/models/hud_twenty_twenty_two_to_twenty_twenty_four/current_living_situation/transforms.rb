###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
