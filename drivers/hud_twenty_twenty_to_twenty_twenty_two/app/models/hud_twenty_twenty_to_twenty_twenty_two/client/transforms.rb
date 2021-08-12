###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Client
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Client::TransformGenderToColumns,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Client
    end
  end
end
