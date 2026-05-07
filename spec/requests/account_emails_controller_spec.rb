# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountEmailsController, type: :request do
  # TODO: - get auth working in tests
  let(:user) { create :user }
  let(:email)  { ActionMailer::Base.deliveries.last }

  before(:each) do
    sign_in(user)
  end

  describe 'GET edit' do
    before(:each) do
      get edit_account_email_path
    end

    it 'assigns user' do
      expect(assigns(:user)).to eq user
    end

    it 'renders edit' do
      expect(response).to render_template 'accounts/edit'
    end
  end

  describe 'PUT update' do
    context 'with no current password' do
      before(:each) do
        patch account_email_path, params: { user: { email: 'info@greenriver.com' } }
      end
      it 'does not update' do
        expect(User.not_system.first.email).to_not eq 'info@greenriver.com'
      end
      it 'has an error' do
        expect(assigns(:user).errors.count).to eq 1
      end
      it 'renders edit' do
        expect(response).to redirect_to edit_account_email_path
      end
    end

    context 'with current password' do
      let(:changes) do
        {
          email: 'info@greenriver.com',
          current_password: Digest::SHA256.hexdigest('abcd1234abcd1234'),
        }
      end

      before(:each) do
        patch account_email_path, params: { user: changes }
      end
      it 'updates email' do
        assigns(:user).confirm
        expect(User.not_system.first.email).to eq changes[:email]
      end
      it 'sends an email confirmation email' do
        expect(email.to).to eq [changes[:email]]
      end
      it 'redirects to edit' do
        expect(response).to redirect_to edit_account_email_path
      end
    end

    context 'when HMIS is enabled' do
      before(:each) do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'syncs HUD users with the previous email on success' do
        expect_any_instance_of(User).to receive(:sync_to_hud_users).with(previous_email: user.email)

        patch account_email_path, params: { user: { email: 'info@greenriver.com', current_password: Digest::SHA256.hexdigest('abcd1234abcd1234') } }
      end

      it 'does not sync HUD users when the update fails' do
        expect_any_instance_of(User).not_to receive(:sync_to_hud_users)

        patch account_email_path, params: { user: { email: 'info@greenriver.com' } }
      end
    end
  end
end
