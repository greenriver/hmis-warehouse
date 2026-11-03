###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddEnrollmentIndexToCustomAssessments < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_index(
        :CustomAssessments,
        [:EnrollmentID, :PersonalID, :data_source_id],
        where: '"DateDeleted" IS NULL',
        name: :idx_custom_assessments_on_en_id_p_id_ds_id,
        if_not_exists: true,
      )
    end
  end
end
