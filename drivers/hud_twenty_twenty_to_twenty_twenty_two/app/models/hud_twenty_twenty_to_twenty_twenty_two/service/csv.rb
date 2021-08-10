###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Service
  class Csv
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::CsvBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Service::Transform
    end

    def self.destination_class
      GrdaWarehouse::Hud::Service
    end
  end
end
