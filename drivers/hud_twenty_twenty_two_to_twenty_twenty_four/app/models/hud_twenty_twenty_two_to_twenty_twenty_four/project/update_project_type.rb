###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Project
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
