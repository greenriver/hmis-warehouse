###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, :devise_only, type: :model do
  describe '.revoke_stale_two_factor_state!' do
    let!(:disabled) { create(:user_2fa, otp_required_for_login: false, confirmed_2fa: 0) }
    let!(:param_off) { create(:user_2fa, otp_required_for_login: false, confirmed_2fa: 2) }
    let!(:mid_setup) { create(:user_2fa, otp_required_for_login: false, confirmed_2fa: 1) }
    let!(:enabled) { create(:user_2fa) }
    let!(:device_for) do
      [disabled, mid_setup, enabled].index_with do |u|
        u.two_factors_memorized_devices.create!(uuid: SecureRandom.uuid, name: 'Laptop', expires_at: 1.week.from_now)
      end
    end

    it 'clears legacy secret columns and backup codes for 2FA-off users only' do
      [disabled, enabled].each do |u|
        u.update_columns(
          encrypted_otp_secret: 'x',
          encrypted_otp_secret_iv: 'y',
          encrypted_otp_secret_salt: 'z',
          otp_backup_codes: ['code'],
        )
      end

      described_class.revoke_stale_two_factor_state!

      legacy_columns = [:encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt, :otp_backup_codes]
      expect(disabled.reload.slice(*legacy_columns).values).to all(be_nil)
      expect(enabled.reload.slice(*legacy_columns).values).to eq(['x', 'y', 'z', ['code']])
    end

    it 'clears secrets for 2FA-off users except those mid-setup' do
      enabled_secret = enabled.otp_secret
      mid_secret = mid_setup.otp_secret

      described_class.revoke_stale_two_factor_state!

      expect(disabled.reload.otp_secret).to be_nil
      expect(param_off.reload.otp_secret).to be_nil
      expect(param_off.confirmed_2fa).to eq(0)
      expect(mid_setup.reload.otp_secret).to eq(mid_secret)
      expect(enabled.reload.otp_secret).to eq(enabled_secret)
      expect(enabled.confirmed_2fa).to eq(2)
    end

    it 'deletes remembered devices only for 2FA-off users' do
      described_class.revoke_stale_two_factor_state!

      expect(TwoFactorsMemorizedDevice.where(id: device_for[disabled].id)).not_to exist
      expect(TwoFactorsMemorizedDevice.where(id: device_for[mid_setup].id)).not_to exist
      expect(TwoFactorsMemorizedDevice.where(id: device_for[enabled].id)).to exist
    end
  end
end
