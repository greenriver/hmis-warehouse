###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Project
  class Transforms
    def self.transforms(csv: false, db: false) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyToTwentyTwentyTwo::Project::AddHopwaMedAssistedLivingFac,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Project
    end
  end
end
