###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Export::Db
  module_function

  def up
    HudTwentyTwentyToTwentyTwentyTwo::Export::Transform.up(
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
      GrdaWarehouse::Hud::Export,
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
      GrdaWarehouse::Hud::Export,
    )
  end
end
