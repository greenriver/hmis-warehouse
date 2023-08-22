###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'kiba-common/sources/enumerable'

module HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::DbBase
  extend ActiveSupport::Concern

  included do
    def self.up(references)
      HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::Transform.up(
        HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsSource,
        target_class,
        transforms(db: true, references: references),
        HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsDestination,
        target_class,
      )
    end

    def initialize(references)
      @references = references
    end
  end
end
