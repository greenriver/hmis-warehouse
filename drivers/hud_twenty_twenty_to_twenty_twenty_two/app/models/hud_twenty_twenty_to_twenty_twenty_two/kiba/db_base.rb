###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Kiba::DbBase
  extend ActiveSupport::Concern

  included do
    def self.up
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::Transform.up(
        HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
        target_class,
        transforms(db: true),
        HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
        target_class,
      )
    end
  end
end
