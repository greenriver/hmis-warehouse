###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReferralIdToCeEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :Event, :ce_referral_id, :integer, null: true

    safety_assured do
      add_index :Event, :ce_referral_id
    end
  end
end
