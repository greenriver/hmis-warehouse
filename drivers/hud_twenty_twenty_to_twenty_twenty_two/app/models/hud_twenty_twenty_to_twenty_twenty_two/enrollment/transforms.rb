###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      classes = [
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::RenameR13Columns,
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::UpdateR7Columns,
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::RenameV7Columns,
      ]
      classes << HudTwentyTwentyToTwentyTwentyTwo::Enrollment::FilterLiteralHomelessHistory if csv
      classes
    end

    def self.target_class
      GrdaWarehouse::Hud::Enrollment
    end
  end
end
