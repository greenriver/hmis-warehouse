###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Disability
  class Csv
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::CsvBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Disability::Transform
    end

    def self.destination_class
      GrdaWarehouse::Hud::Disability
    end
  end
end
