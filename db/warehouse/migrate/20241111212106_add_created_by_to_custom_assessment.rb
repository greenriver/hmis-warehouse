#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddCreatedByToCustomAssessment < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # These refer to the users table in the app db (not warehouse), so fk relationship is not made explicitly
      add_reference :CustomAssessments, :created_by_user, null: true
      add_reference :CustomAssessments, :updated_by_user, null: true
      # This refers to the User table in the warehouse db
      add_reference :CustomAssessments, :created_by_hud_user, foreign_key: { to_table: :User }, null: true
      # no need to add updated_by_hud_user, since UserID column exists
    end
  end
end
