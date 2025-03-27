# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddTargetEnrollmentToReferral < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # it's ok to use safety_assured here, since these tables aren't in production use yet
      add_reference :ce_referrals, :target_enrollment, foreign_key: { to_table: :Enrollment }, null: true
    end
  end
end
