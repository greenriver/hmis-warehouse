###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Project
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Project::AddHopwaMedAssistedLivingFac,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Project
    end
  end
end
