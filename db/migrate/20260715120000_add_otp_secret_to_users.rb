###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# devise-two-factor 6.x stores the TOTP secret in a Rails-encrypted `otp_secret`
# column. Existing secrets remain in encrypted_otp_secret/_iv/_salt and are read via
# User#legacy_otp_secret; this nullable column holds new and re-enrolled secrets.
class AddOtpSecretToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :otp_secret, :string
  end
end
