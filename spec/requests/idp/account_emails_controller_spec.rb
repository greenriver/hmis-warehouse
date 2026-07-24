###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm email self-management. Requires the app to have booted under AUTH_METHOD=jwt.
RSpec.describe Idp::AccountEmailsController, type: :request, if: AuthMethod.jwt? do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let!(:user) { create(:acl_user, first_name: 'Self', last_name: 'Serve', email: 'before@example.com') }
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{user.id}" }
  let(:actions_url) { "#{target_url}/execute-actions-email" }

  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  def configure_keycloak!
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )
  end

  describe 'when email changes are enabled (Keycloak)' do
    let(:current_representation) { { id: user.id.to_s, username: 'before@example.com', firstName: 'Self', lastName: 'Serve', email: 'before@example.com' } }

    before(:each) do
      configure_keycloak!
      sign_in user
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
      stub_request(:put, actions_url).to_return(status: 204)
    end

    it 'renders the email form' do
      get edit_account_email_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="user[email]"')
    end

    it 'updates the email locally, pushes it to Keycloak, and sends no Devise confirmation mail' do
      patch account_email_path, params: { user: { email: 'after@example.com' } }

      expect(user.reload.email).to eq('after@example.com')
      expect(
        a_request(:put, target_url).with(body: current_representation.merge(email: 'after@example.com', emailVerified: false)),
      ).to have_been_made
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(flash[:notice]).to eq('Account email was updated.')
      expect(response).to redirect_to(edit_account_email_path)
    end

    it 'syncs HUD users with the previous email when HMIS is enabled' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      expect_any_instance_of(User).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

      patch account_email_path, params: { user: { email: 'after@example.com' } }
    end

    it 'does nothing when the email is unchanged' do
      patch account_email_path, params: { user: { email: 'before@example.com' } }

      expect(a_request(:put, target_url)).not_to have_been_made
      expect(flash[:notice]).to be_blank
    end

    context 'when the Keycloak push fails' do
      before do
        stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still commits the local email, pages Sentry, and warns' do
        patch account_email_path, params: { user: { email: 'after@example.com' } }

        expect(user.reload.email).to eq('after@example.com')
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'when email changes are disabled (unconfigured => NullService)' do
    before(:each) { sign_in user }

    it 'redirects edit to the account page with an unavailable notice' do
      get edit_account_email_path

      expect(response).to redirect_to(edit_account_path)
      expect(flash[:alert]).to match(/not available/i)
    end

    it 'refuses the update and never calls the IdP' do
      patch account_email_path, params: { user: { email: 'after@example.com' } }

      expect(user.reload.email).to eq('before@example.com')
      expect(a_request(:put, /#{Regexp.escape(api_url)}/)).not_to have_been_made
      expect(response).to redirect_to(edit_account_path)
    end
  end
end
