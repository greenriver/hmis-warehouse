###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class Transforms
    def self.transforms
      [
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::RenameR13Columns,
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::UpdateR7Columns,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Enrollment
    end
  end
end
