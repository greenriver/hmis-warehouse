###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Organization
  class Db
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::DbBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Organization::Transform
    end

    def self.rails_class
      GrdaWarehouse::Hud::Organization
    end
  end
end
