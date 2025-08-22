# frozen_string_literal: true

class AddReferralIdToCeEvent < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :Event, :ce_referral_id, :integer, null: true
    add_index :Event, :ce_referral_id, unique: true, algorithm: :concurrently
  end
end
