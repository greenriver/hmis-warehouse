###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddSourceEnrollmentToCeReferrals < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :ce_referrals, :source_enrollment, null: true, index: false, foreign_key: { to_table: :Enrollment }
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20250620132952
# rails db:migrate:down:warehouse VERSION=20250620132952
