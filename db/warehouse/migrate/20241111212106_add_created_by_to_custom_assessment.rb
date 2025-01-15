#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddCreatedByToCustomAssessment < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # These refer to the User table in the warehouse db, NOT the users table in the app db
      add_reference :CustomAssessments, :created_by_hud_user, foreign_key: { to_table: :User }, null: true
      add_reference :CustomAssessments, :updated_by_hud_user, foreign_key: { to_table: :User }, null: true
    end
  end
end
