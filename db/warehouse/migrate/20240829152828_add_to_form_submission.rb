#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddToFormSubmission < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_external_form_submissions, :cleaned_values, :jsonb, null: true

    safety_assured do
      add_reference :hmis_external_form_submissions, :enrollment, index: true, null: true
    end
  end
end
