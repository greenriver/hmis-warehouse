###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Devise-only: account_two_factor routes are drawn only on the Devise arm.
RSpec.describe AccountTwoFactorsController, :devise_only, type: :request do
  include LegacyOtpSecretWriter

  let(:user) { create(:user_2fa) }

  before(:each) { sign_in(user) }

  describe 'DELETE destroy' do
    let!(:old_secret) { user.otp_secret }
    let!(:device) do
      user.two_factors_memorized_devices.create!(uuid: SecureRandom.uuid, name: 'Laptop', expires_at: 1.week.from_now)
    end
    let!(:other_device) do
      create(:user_2fa).two_factors_memorized_devices.create!(uuid: SecureRandom.uuid, name: 'Other', expires_at: 1.week.from_now)
    end

    it 'replaces the OTP secret and shows the new one on the edit page' do
      delete account_two_factor_path
      get edit_account_two_factor_path

      user.reload
      expect(user.otp_secret).to be_present
      expect(user.otp_secret).not_to eq(old_secret)
      expect(user.otp_required_for_login).to be(false)
      expect(user.confirmed_2fa).to eq(0)
      expect(response.body).to include(user.otp_secret)
      expect(response.body).not_to include(old_secret)
    end

    it 'rejects a code from the old secret during re-setup' do
      delete account_two_factor_path
      get edit_account_two_factor_path

      patch account_two_factor_path, params: { user: { otp_attempt: ROTP::TOTP.new(old_secret).now } }

      expect(flash[:error]).to eq('The code submitted was invalid')
      expect(user.reload.confirmed_2fa).to eq(0)
    end

    context 'when the secret is stored only in the legacy columns' do
      let(:legacy_secret) { User.generate_otp_secret }

      before do
        write_legacy_otp_secret(user, legacy_secret)
      end

      it 'clears the legacy columns and rejects a code from the legacy secret' do
        expect(user.otp_secret).to eq(legacy_secret)

        delete account_two_factor_path
        get edit_account_two_factor_path

        user.reload
        expect([user.encrypted_otp_secret, user.encrypted_otp_secret_iv, user.encrypted_otp_secret_salt]).to all(be_nil)
        expect(user.otp_secret).not_to eq(legacy_secret)

        patch account_two_factor_path, params: { user: { otp_attempt: ROTP::TOTP.new(legacy_secret).now } }

        expect(flash[:error]).to eq('The code submitted was invalid')
        expect(user.reload.confirmed_2fa).to eq(0)
      end
    end

    it 'deletes only this user’s remembered devices' do
      delete account_two_factor_path

      expect(TwoFactorsMemorizedDevice.where(id: device.id)).not_to exist
      expect(TwoFactorsMemorizedDevice.where(id: other_device.id)).to exist
    end
  end

  describe 'PATCH update' do
    it 'flashes an invalid-code error when otp_attempt is missing' do
      patch account_two_factor_path, params: { user: { foo: 1 } }

      expect(response).to redirect_to(edit_account_two_factor_path)
      expect(flash[:error]).to eq('The code submitted was invalid')
    end
  end
end
