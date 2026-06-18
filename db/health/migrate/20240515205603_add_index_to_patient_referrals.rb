###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddIndexToPatientReferrals < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_index :patient_referrals, [:patient_id, :current]
    end
  end
end
