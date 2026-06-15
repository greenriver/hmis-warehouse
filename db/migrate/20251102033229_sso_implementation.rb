###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SsoImplementation < ActiveRecord::Migration[7.1]
  def change
    create_table :user_authentication_sources do |t|
      t.references :user, null: false, index: true
      t.string :connector_id, null: false
      t.string :connector_user_id, null: false
      t.boolean :enabled, default: true, null: false
      t.index [:connector_user_id, :connector_id], unique: true
      t.timestamps
      t.timestamp :discarded_at, index: true
    end
    add_column :users, :last_connector_id, :string

    # For a future migration, we should rename and eventually remove the old devise columns
    # [
    #   :encrypted_password,
    #   :reset_password_token,
    #   :reset_password_sent_at,
    #   :remember_created_at,
    #   :current_sign_in_at,
    #   :current_sign_in_ip,
    #   :confirmation_token,
    #   :confirmed_at,
    #   :confirmation_sent_at,
    #   :failed_attempts,
    #   :locked_at,
    #   :unlock_token,
    #   :password_changed_at,
    #   :consumed_timestep,
    #   :otp_required_for_login,
    #   :confirmed_2fa,
    #   :otp_backup_codes,
    #   :encrypted_otp_secret,
    #   :encrypted_otp_secret_iv,
    #   :encrypted_otp_secret_salt,
    # ].each do |col_name|
    #   rename_column :users, col_name, "legacy_#{col_name}"
    # end
  end
end
