###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit::Db
  module_function

  def up
    HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit::Transform.up(
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
      GrdaWarehouse::Hud::IncomeBenefit,
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
      GrdaWarehouse::Hud::IncomeBenefit,
    )
  end
end
