###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Disability::Db
  module_function

  def up
    HudTwentyTwentyToTwentyTwentyTwo::Disability::Transform.up(
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
      GrdaWarehouse::Hud::Disability,
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
      GrdaWarehouse::Hud::Disability,
    )
  end
end
