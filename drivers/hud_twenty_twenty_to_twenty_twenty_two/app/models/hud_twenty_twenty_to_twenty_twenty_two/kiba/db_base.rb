###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Kiba::DbBase
  extend ActiveSupport::Concern

  included do
    def self.up
      transformer.up(
        HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsSource,
        rails_class,
        HudTwentyTwentyToTwentyTwentyTwo::Kiba::RailsDestination,
        rails_class,
      )
    end
  end
end
