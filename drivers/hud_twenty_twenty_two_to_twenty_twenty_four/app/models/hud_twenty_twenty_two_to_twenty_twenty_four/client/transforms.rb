###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Client
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::Client::UpdateGenders,
        HudTwentyTwentyTwoToTwentyTwentyFour::Client::UpdateRaceAndEthnicity,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Client
    end
  end
end
