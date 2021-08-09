###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment::Db
  module_function

  def up
    HudTwentyTwentyToTwentyTwentyTwo::Enrollment::Transform.up(
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
      GrdaWarehouse::Hud::Enrollment,
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
      GrdaWarehouse::Hud::Enrollment,
    )
  end
end
