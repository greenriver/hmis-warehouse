###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::AddC1Columns,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::HealthAndDv
    end
  end
end
