###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Organization
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Organization::RenameVictimServicesProvider,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Organization
    end
  end
end
