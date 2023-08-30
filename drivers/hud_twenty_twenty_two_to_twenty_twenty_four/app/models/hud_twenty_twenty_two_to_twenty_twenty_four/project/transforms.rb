###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Project
  class Transforms
    def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
      [
        HudTwentyTwentyTwoToTwentyTwentyFour::Project::UpdateProjectType,
        HudTwentyTwentyTwoToTwentyTwentyFour::Project::AddRrhSubType,
      ]
    end

    def self.target_class
      GrdaWarehouse::Hud::Project
    end
  end
end
