###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Client::Db
  module_function

  def up
    HudTwentyTwentyToTwentyTwentyTwo::Client::Transform.up(
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
      GrdaWarehouse::Hud::Client,
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
      GrdaWarehouse::Hud::Client,
    )
  end
end
