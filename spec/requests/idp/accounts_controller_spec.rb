###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm account self-management. On this arm the route-level seam mounts Idp::AccountsController
# and JwtAuthenticationHelper#sign_in is active.
RSpec.describe Idp::AccountsController, :jwt_only, type: :request do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let!(:user) { create(:acl_user, first_name: 'Self', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily') }
  # sign_in links this user to the 'test' connector at jwt_connector_user_id, which is deliberately
  # not the warehouse user id — the Admin API is addressed by the IdP's id.
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{jwt_connector_user_id(user)}" }

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
  # (supports_profile_updates? == true).
  def configure_keycloak!
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )
  end

  # Asserting the raise rather than a redirect is what shows authenticate_user! ran ahead of the
  # action; the gate itself is covered in warehouse_jwt_wiring_spec.rb.
  describe 'with no forwarded token' do
    it 'refuses the profile tab' do
      expect { get edit_account_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    it 'refuses a profile write, and writes nothing' do
      expect do
        patch account_path, params: { user: { first_name: 'Hacked', last_name: 'Hacked', phone: '5085550000' } }
      end.to raise_error(Idp::UnauthenticatedRequestError)

      user.reload
      expect(user.first_name).to eq('Self')
      expect(user.phone).to eq('5085551000')
    end
  end

  describe 'when the connector accepts profile writes (Keycloak)' do
    before(:each) do
      configure_keycloak!
      sign_in user
    end

    describe 'GET edit' do
      it 'renders the name fields editable' do
        get edit_account_path

        expect(response).to have_http_status(:ok)
        ['first_name', 'last_name'].each do |field|
          disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
          expect(response.body).not_to match(disabled_input)
        end
      end

      # Their coverage lives in the Idp::AccountEmailsController spec.
      it 'leaves the credential self-service links to the Login & Security tab' do
        get edit_account_path

        expect(response.body).not_to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).not_to match(/kc_action=CONFIGURE_TOTP/)
      end
    end

    describe 'PATCH update' do
      let(:current_representation) { { id: jwt_connector_user_id(user), username: user.email, firstName: 'Self', lastName: 'Serve', email: user.email } }

      before(:each) do
        stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, target_url).to_return(status: 204)
      end

      it 'applies a name change locally and syncs it to Keycloak' do
        patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily' } }

        expect(user.reload.first_name).to eq('Renamed')
        expect(
          a_request(:put, target_url).with(body: current_representation.merge(firstName: 'Renamed')),
        ).to have_been_made
        expect(flash[:notice]).to eq('Account name was updated.')
        expect(response).to redirect_to(edit_account_path)
      end

      it 'saves local-only fields without calling Keycloak' do
        patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551212', email_schedule: 'daily' } }

        expect(user.reload.phone).to eq('5085551212')
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to eq('Phone number was updated.')
      end

      it 'persists a theme-only change even though it has no notice' do
        patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily', theme: 'modern' } }

        expect(user.reload.theme).to eq('modern')
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_blank
      end

      # The IdP owns the address: a change goes through Idp::AccountEmailsController so the mailbox is
      # verified before it becomes real. This action writes the same users row, so it has to refuse an
      # address handed straight to it, and likewise the agency, which the form renders disabled. The
      # phone change makes the save run, so the assertions can't pass on a skipped update.
      it 'ignores crafted email and agency params on a request that does save' do
        # Set explicitly rather than left to the factory's hard-coded agency_id, so the crafted id is
        # a different row.
        own_agency = create(:agency)
        other_agency = create(:agency)
        user.update_column(:agency_id, own_agency.id)
        original_email = user.email

        patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551212', email_schedule: 'daily', email: 'attacker@example.com', agency_id: other_agency.id } }

        user.reload
        expect(user.phone).to eq('5085551212')
        expect(user.email).to eq(original_email)
        expect(user.agency_id).to eq(own_agency.id)
        expect(a_request(:put, target_url)).not_to have_been_made
      end

      context 'when HMIS is enabled' do
        # A real Hmis::Hud::User on an HMIS data source, matched by email the way
        # User#sync_to_hud_users matches. These examples assert against the row rather than mocking
        # sync_to_hud_users, so they cover the sync's outcome rather than the call.
        let!(:hmis_data_source) { create(:hmis_primary_data_source) }
        let!(:hud_user) { create(:hmis_hud_user, data_source: hmis_data_source, user_email: user.email, user_first_name: 'Self', user_last_name: 'Serve') }

        before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

        it 'carries a name change through to the HMIS user rows and on to Keycloak' do
          patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily' } }

          expect(user.reload.first_name).to eq('Renamed')
          expect(hud_user.reload.user_first_name).to eq('Renamed')
          expect(
            a_request(:put, target_url).with(body: current_representation.merge(firstName: 'Renamed')),
          ).to have_been_made
          expect(flash[:notice]).to eq('Account name was updated.')
        end

        it 'leaves the HMIS user rows alone when nothing changed' do
          # Stale on purpose: a sync would rewrite this to the user's current name, so the row
          # standing still is observable evidence the sync was skipped.
          stale_hud_user = create(:hmis_hud_user, data_source: hmis_data_source, user_email: user.email, user_first_name: 'Stale', user_last_name: 'Row')

          patch account_path, params: { user: { first_name: 'Self', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily' } }

          expect(stale_hud_user.reload.user_first_name).to eq('Stale')
          expect(a_request(:put, target_url)).not_to have_been_made
          expect(flash[:notice]).to be_blank
        end

        # The HUD sync shares the local save's transaction, so a rejected Hmis::Hud::User write takes
        # the profile edit with it rather than leaving HMIS rows naming someone the app no longer does.
        # any_instance because the controller's @user comes back from User.find_or_create_from_jwt,
        # not from this example.
        it 'rolls the local save back when the HUD sync is rejected, and never reaches Keycloak' do
          allow_any_instance_of(User).to receive(:sync_to_hud_users).and_raise(ActiveRecord::RecordInvalid)

          patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve', phone: '5085551000', email_schedule: 'daily' } }

          expect(user.reload.first_name).to eq('Self')
          expect(hud_user.reload.user_first_name).to eq('Self')
          expect(a_request(:put, target_url)).not_to have_been_made
          expect(response).to have_http_status(:ok)
          expect(flash[:notice]).to be_blank
        end
      end

      context 'when the Keycloak push fails' do
        before do
          stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
          allow(Sentry).to receive(:capture_exception_with_info)
        end

        # The push shares a transaction with the local save, so a refused push takes the save with
        # it — the user's profile can't drift from what their IdP holds.
        it 'saves nothing, pages Sentry, and re-renders saying so' do
          patch account_path, params: { user: { first_name: 'Renamed', last_name: 'Serve' } }

          expect(user.reload.first_name).to eq('Self')
          expect(Sentry).to have_received(:capture_exception_with_info)
          expect(flash[:alert]).to match(/couldn't save your changes/)
          expect(flash[:notice]).to be_blank
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

  # Same locked-profile behavior as the NullService context above, but on a reachable, *built*
  # Keycloak (active config, manage_users:false), not an absent config — proving it locks and drops
  # writes rather than raising.
  describe 'when the connector authenticates but declines profile writes (manage_users:false)' do
    before(:each) do
      create(
        :idp_service_config,
        :authenticate_only,
        connector_id: connector_id,
        provider: 'keycloak',
        api_url: api_url,
        keycloak_realm: realm,
      )
      sign_in user
    end

    it 'renders the name fields read-only with the managed-by-IdP hint' do
      get edit_account_path

      expect(response).to have_http_status(:ok)
      ['first_name', 'last_name'].each do |field|
        disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
        expect(response.body).to match(disabled_input)
      end
      expect(response.body).to match(/managed by your identity provider/i)
    end

    it 'strips crafted name params, saves local fields, and never calls the IdP' do
      patch account_path, params: { user: { first_name: 'Hacked', last_name: 'Hacked', phone: '5085550000' } }

      user.reload
      expect(user.first_name).to eq('Self')
      expect(user.last_name).to eq('Serve')
      expect(user.phone).to eq('5085550000')
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
