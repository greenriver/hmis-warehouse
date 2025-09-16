###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'kiba-common/sources/enumerable'

module HudTwentyTwentyFourToTwentyTwentySix::Kiba::DbBase
  extend ActiveSupport::Concern

  included do
    def self.up(references)
      source_config = if source_class.present?
        [{}]
      else
        target_class
      end

      HudTwentyTwentyFourToTwentyTwentySix::Kiba::Transform.up(
        source_class || HudTwentyTwentyFourToTwentyTwentySix::Kiba::RailsSource,
        source_config,
        transforms(db: true, references: references),
        HudTwentyTwentyFourToTwentyTwentySix::Kiba::RailsDestination,
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
