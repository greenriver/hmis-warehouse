#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddCreatedByToCustomAssessment < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # These refer to the users table in the app db (not warehouse), so fk relationship is not made explicitly
      add_reference :CustomAssessments, :created_by_user, null: true, type: :integer
      add_reference :CustomAssessments, :updated_by_user, null: true, type: :integer
    end
  end
end
