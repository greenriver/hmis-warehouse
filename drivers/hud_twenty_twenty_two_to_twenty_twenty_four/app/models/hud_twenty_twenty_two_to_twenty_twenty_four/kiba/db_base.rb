###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::DbBase
  extend ActiveSupport::Concern

  included do
    def self.up
      HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::Transform.up(
        HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsSource,
        target_class,
        transforms(db: true),
        HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsDestination,
        target_class,
      )
    end
  end
end
