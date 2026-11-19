###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Stores a secret in the legacy encrypted_otp_secret/_iv/_salt columns in the format
# devise-two-factor <= 4.x wrote (attr_encrypted, per-attribute iv+salt, aes-256-gcm, Base64),
# and clears the Rails-encrypted otp_secret column so reads go through User#legacy_otp_secret.
module LegacyOtpSecretWriter
  def write_legacy_otp_secret(user, secret)
    writer_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      extend AttrEncrypted
      attr_encrypted :legacy_secret,
                     key: ENV['ENCRYPTION_KEY'],
                     mode: :per_attribute_iv_and_salt,
                     algorithm: 'aes-256-gcm',
                     encode: true,
                     encode_iv: true,
                     encode_salt: true,
                     attribute: 'encrypted_otp_secret'
    end
    writer = writer_class.find(user.id)
    writer.legacy_secret = secret
    writer.save!(validate: false)
    user.update_columns(otp_secret: nil)
    user.reload
  end
end
