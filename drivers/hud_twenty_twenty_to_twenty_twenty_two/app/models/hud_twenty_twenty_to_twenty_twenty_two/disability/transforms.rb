###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Disability
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Disability::AddAntiRetroviral,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Disability
    end
  end
end
