###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCeReferralDeclineReasons < ActiveRecord::Migration[7.2]
  def change
    create_table :ce_referral_decline_reasons do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.references :data_source, null: false, index: true
      t.datetime :deleted_at, index: true
      t.timestamps

      t.index [:data_source_id, :key], unique: true
    end

    safety_assured do
      # Strong Migrations warns that creating a foreign key blocks writes on both tables,
      # but it's acceptable here because: the referrals' decline_reason col is empty for now
      # and the referrals itself table is not huge, so the locks will be released quickly.
      add_reference :ce_referrals, :decline_reason,
                    null: true,
                    foreign_key: { to_table: :ce_referral_decline_reasons }
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260112201542
# rails db:migrate:down:warehouse VERSION=20260112201542
