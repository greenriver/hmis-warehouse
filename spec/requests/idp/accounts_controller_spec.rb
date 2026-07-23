###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm account self-management. These assertions require the app to have booted under
# AUTH_METHOD=jwt (the dedicated CI step), where the route-level seam mounts Idp::AccountsController
# and JwtAuthenticationHelper#sign_in is active.
RSpec.describe Idp::AccountsController, type: :request, if: AuthMethod.jwt? do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let!(:user) { create(:acl_user, first_name: 'Self', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily', credentials: 'old') }
  # sign_in links this user to the 'test' connector at connector_user_id == user.id.
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{user.id}" }

  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
  end

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  # A creation/write-capable Keycloak connector, so primary_idp resolves to a real KeycloakService
  # (supports_profile_updates? == true, account_console_url present).
  def configure_keycloak!
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )
  end

  describe 'when the connector accepts profile writes (Keycloak)' do
    before(:each) do
      configure_keycloak!
      sign_in user
    end

    describe 'GET edit' do
      it 'renders the name fields editable and deep-links into the Keycloak self-service actions' do
        get edit_account_path

        expect(response).to have_http_status(:ok)
        ['first_name', 'last_name'].each do |field|
          disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
          expect(response.body).not_to match(disabled_input)
        end
        expect(response.body).to include("#{api_url}/realms/#{realm}/protocol/openid-connect/auth")
        expect(response.body).to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).to match(/kc_action=CONFIGURE_TOTP/)
      end
    end

    describe 'PATCH update' do
      let(:current_representation) { { id: user.id.to_s, username: user.email, firstName: 'Self', lastName: 'Serve', email: user.email } }

      before(:each) do
        stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, target_url).to_return(status: 204)
      end

      it 'applies a name change locally and syncs it to Keycloak' do
        patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve', phone: '5085551000', credentials: 'old', email_schedule: 'daily' } }

        expect(user.reload.first_name).to eq('Renamed')
        expect(
          a_request(:put, target_url).with(body: current_representation.merge(firstName: 'Renamed')),
        ).to have_been_made
        expect(flash[:notice]).to eq('Account name was updated.')
        expect(response).to redirect_to(edit_account_path)
      end

      it 'saves local-only fields without calling Keycloak' do
        patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551212', credentials: 'old', email_schedule: 'daily' } }

        expect(user.reload.phone).to eq('5085551212')
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to eq('Phone number was updated.')
      end

      context 'when HMIS is enabled' do
        before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

        it 'syncs HUD users when a tracked field changes' do
          expect_any_instance_of(User).to receive(:sync_to_hud_users).with(no_args)
          patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve' } }
        end

        it 'does not sync HUD users when nothing changed' do
          expect_any_instance_of(User).not_to receive(:sync_to_hud_users)
          patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551000', credentials: 'old', email_schedule: 'daily' } }
        end
      end

      context 'when the Keycloak push fails' do
        before do
          stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
          allow(Sentry).to receive(:capture_exception_with_info)
        end

        it 'still saves the local change, pages Sentry, and warns beside the success' do
          patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve' } }

          expect(user.reload.first_name).to eq('Renamed')
          expect(Sentry).to have_received(:capture_exception_with_info)
          expect(flash[:alert]).to be_present
          expect(flash[:notice]).to be_present
        end
      end
    end
  end

  describe 'when the connector cannot accept profile writes (unconfigured => NullService)' do
    before(:each) { sign_in user }

    it 'renders the name fields read-only and shows the managed-by-IdP notice instead of a console link' do
      get edit_account_path

      expect(response).to have_http_status(:ok)
      ['first_name', 'last_name'].each do |field|
        disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
        expect(response.body).to match(disabled_input)
      end
      expect(response.body).to match(/managed by your identity provider/i)
    end

    it 'strips crafted name params and never calls the IdP' do
      patch account_path, params: { user: { first_name: 'Hacked', last_name: 'Hacked', phone: '5085550000' } }

      user.reload
      expect(user.first_name).to eq('Self')
      expect(user.last_name).to eq('Serve')
      expect(user.phone).to eq('5085550000') # local field still saves
      expect(a_request(:put, /#{Regexp.escape(api_url)}/)).not_to have_been_made
    end
  end

  describe 'IdP-owned routes are absent under JWT' do
    it 'does not generate helpers for password, two-factor, or login-history' do
      # Bare undefined helpers raise NameError (NoMethodError's parent); the route helpers are gone.
      expect { edit_account_password_path }.to raise_error(NameError)
      expect { edit_account_two_factor_path }.to raise_error(NameError)
      expect { locations_account_path }.to raise_error(NameError)
    end
  end
end
