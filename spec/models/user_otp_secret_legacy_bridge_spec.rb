###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# devise-two-factor 6.x stores new OTP secrets in a Rails-encrypted `otp_secret` column,
# but existing users' secrets remain in the legacy attr_encrypted columns
# (encrypted_otp_secret/_iv/_salt). User#legacy_otp_secret must decrypt those so existing
# 2FA keeps working with no data migration.
RSpec.describe 'User OTP secret legacy bridge', type: :model do
  # Writes a secret into the legacy encrypted_otp_secret* columns exactly the way
  # devise-two-factor <= 4.x did (attr_encrypted, per-attribute iv+salt, default
  # aes-256-gcm) — i.e. how production secrets are currently stored.
  # Virtual attr `legacy_secret` is mapped to the encrypted_otp_secret* columns (via
  # `attribute:`) so it does not collide with the real `otp_secret` column that
  # devise-two-factor 6.x adds. This reproduces production's storage format exactly.
  let(:legacy_writer_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      extend AttrEncrypted
      attr_encrypted :legacy_secret,
                     key: ENV['ENCRYPTION_KEY'],
                     mode: :per_attribute_iv_and_salt,
                     encode: true,
                     encode_iv: true,
                     encode_salt: true,
                     attribute: 'encrypted_otp_secret'
    end
  end

  let(:plaintext_secret) { User.generate_otp_secret }

  def user_with_legacy_secret(secret)
    user = create(:user)
    writer = legacy_writer_class.find(user.id)
    writer.legacy_secret = secret
    writer.save!(validate: false)
    user.reload
  end

  it 'reads a legacy-encrypted secret through otp_secret' do
    user = user_with_legacy_secret(plaintext_secret)

    expect(user[:otp_secret]).to be_nil # nothing in the new Rails-encrypted column
    expect(user.otp_secret).to eq(plaintext_secret)
  end

  it 'validates an OTP generated from the legacy secret' do
    user = user_with_legacy_secret(plaintext_secret)

    code = ROTP::TOTP.new(plaintext_secret).now
    expect(user.validate_and_consume_otp!(code)).to be_truthy
  end

  # New/re-enrolled secrets use the Rails-encrypted otp_secret column; this also proves
  # the ActiveRecord encryption config (derived from ENCRYPTION_KEY) works end to end.
  it 'stores a newly generated secret in the Rails-encrypted otp_secret column' do
    user = create(:user)
    user.set_initial_two_factor_secret!
    user.reload

    expect(user.encrypted_otp_secret).to be_nil # not in the legacy columns
    expect(user.otp_secret).to be_present

    raw = User.connection.select_value("SELECT otp_secret FROM users WHERE id = #{user.id}")
    expect(raw).to be_present
    expect(raw).not_to eq(user.otp_secret) # stored encrypted at rest

    code = ROTP::TOTP.new(user.otp_secret).now
    expect(user.validate_and_consume_otp!(code)).to be_truthy
  end
end
