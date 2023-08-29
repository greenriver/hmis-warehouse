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
      source_config = if source_class.present?
        [{}]
      else
        target_class
      end

      HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::Transform.up(
        source_class || HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsSource,
        source_config,
        transforms(db: true, references: references),
        HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::RailsDestination,
        target_class,
      )
    end

    def initialize(references)
      @references = references
    end

    def self.source_class
      nil
    end
  end
end
