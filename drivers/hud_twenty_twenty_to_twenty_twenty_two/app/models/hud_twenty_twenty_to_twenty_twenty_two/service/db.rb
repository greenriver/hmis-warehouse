###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class Db
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::DbBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Service::Transform
    end

    def self.rails_class
      GrdaWarehouse::Hud::Service
    end
  end
end
