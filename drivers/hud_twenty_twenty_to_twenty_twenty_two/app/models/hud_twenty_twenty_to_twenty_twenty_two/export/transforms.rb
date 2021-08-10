###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Export::AddCsvVersion,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Export
    end
  end
end
