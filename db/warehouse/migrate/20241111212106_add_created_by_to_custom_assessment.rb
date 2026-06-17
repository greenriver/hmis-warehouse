###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCreatedByToCustomAssessment < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # These refer to the User table in the warehouse db, NOT the users table in the app db
      add_reference :CustomAssessments, :created_by_hud_user, foreign_key: { to_table: :User }, null: true
      add_reference :CustomAssessments, :updated_by_hud_user, foreign_key: { to_table: :User }, null: true
    end
  end
end
