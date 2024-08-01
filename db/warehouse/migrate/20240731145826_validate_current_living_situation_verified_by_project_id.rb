#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class ValidateCurrentLivingSituationVerifiedByProjectId < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :CurrentLivingSituation, :Project
  end
end
