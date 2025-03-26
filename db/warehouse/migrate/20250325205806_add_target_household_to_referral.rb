#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddTargetHouseholdToReferral < ActiveRecord::Migration[7.0]
  def change
    add_column :ce_referrals, :target_household_id, :string, null: true
  end
end
