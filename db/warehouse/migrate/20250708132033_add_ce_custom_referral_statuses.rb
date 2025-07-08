###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCeCustomReferralStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :ce_custom_referral_statuses do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :treatment, null: true
      t.references :data_source, null: false
      t.timestamps
    end

    safety_assured do
      add_reference :ce_referrals, :custom_referral_status, null: true, foreign_key: { to_table: :ce_custom_referral_statuses }
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20250708132033
# rails db:migrate:down:warehouse VERSION=20250708132033
