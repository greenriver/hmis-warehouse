###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Project
  class Csv
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::CsvBase

    def self.transformer
      HudTwentyTwentyToTwentyTwentyTwo::Project::Transform
    end

    def self.destination_class
      GrdaWarehouse::Hud::Project
    end
  end
end
