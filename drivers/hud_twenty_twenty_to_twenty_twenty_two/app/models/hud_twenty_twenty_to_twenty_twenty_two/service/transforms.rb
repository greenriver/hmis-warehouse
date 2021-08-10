###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Service::AddMovingOnOtherType,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Service
    end
  end
end
