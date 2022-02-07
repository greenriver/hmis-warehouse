###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::Service::AddMovingOnOtherType,
        HudTwentyTwentyToTwentyTwentyTwo::Service::RemoveV3Code11,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Service
    end
  end
end
