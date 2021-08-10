###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class Db
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::DbBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Export::Transform
    end

    def self.rails_class
      GrdaWarehouse::Hud::Export
    end
  end
end
