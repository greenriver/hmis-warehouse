###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Client
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::Client::TransformGenderToColumns,
        HudTwentyTwentyToTwentyTwentyTwo::Client::TransformRace,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Client
    end
  end
end
