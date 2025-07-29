###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReferralOriginToCeReferrals < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      add_column :ce_referrals, :referral_origin, :string, null: true

      # Migrate existing records to 'waitlist'
      execute "UPDATE ce_referrals SET referral_origin = 'waitlist' WHERE referral_origin IS NULL"

      # Make the column non-nullable after populating existing records
      change_column_null :ce_referrals, :referral_origin, false
    end
  end

  def down
    remove_column :ce_referrals, :referral_origin
  end
end

# rails db:migrate:up:warehouse VERSION=20250716112736
# rails db:migrate:down:warehouse VERSION=20250716112736
