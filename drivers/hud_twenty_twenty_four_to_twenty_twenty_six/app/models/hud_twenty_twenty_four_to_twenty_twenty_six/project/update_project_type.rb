###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Project
  class UpdateProjectType
    def process(row)
      project_type = if row['ProjectType'].to_i == 1
        if row['TrackingMethod'].to_i == 3
          1
        else
          0
        end
      else
        row['ProjectType']
      end

      row['ProjectType'] = project_type

      row
    end
  end
end
