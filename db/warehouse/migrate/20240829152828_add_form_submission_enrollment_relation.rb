#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddFormSubmissionEnrollmentRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_external_form_submissions, :enrollment_id, :string, null: true

    # todo @martha
    # safety_assured do
    #   add_reference :hmis_external_form_submissions, :enrollment, foreign_key: { to_table: :Enrollment }, index: true, null: true
    # end
  end
end
