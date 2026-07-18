###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm admin user management. These assertions require the app to have booted under
# AUTH_METHOD=jwt (the dedicated CI step), where the route-level seam mounts
# Admin::Idp::UsersController and JwtAuthenticationHelper#sign_in is active.
RSpec.describe Admin::Idp::UsersController, type: :request, if: AuthMethod.jwt? do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:target_connector_user_id) { 'kc-target-id' }

  let!(:admin_role) { create :admin_role }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User') }

  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{target_connector_user_id}" }

  before(:each) do
    setup_access_control(admin_user, admin_role, collection)

    # DB-managed Keycloak credentials for the 'test' connector so the target user's idp_service
    # resolves to a real KeycloakService rather than a NullService.
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )

    target.user_authentication_sources.find_or_create_by!(
      connector_id: connector_id,
      connector_user_id: target_connector_user_id,
    )
    target.update_column(:last_connector_id, connector_id)

    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )

    sign_in admin_user
  end

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  describe 'GET index (action-menu gating)' do
    it 'offers Force Password Reset for a user with an IdP link' do
      get admin_users_path
      expect(response.body).to include(expire_password_admin_user_path(target))
    end

    it 'hides Force Password Reset for a user with no IdP link' do
      unlinked = create(:acl_user, first_name: 'Unlinked', last_name: 'User')
      get admin_users_path
      expect(response.body).not_to include(expire_password_admin_user_path(unlinked))
    end
  end

  describe 'DELETE destroy (deactivate)' do
    before { stub_request(:put, target_url).to_return(status: 204) }

    it 'flips the local active flag and pushes enabled=false to Keycloak' do
      delete admin_user_path(target)

      expect(target.reload.active).to be false
      expect(a_request(:put, target_url).with(body: { enabled: false })).to have_been_made
      expect(response).to redirect_to(action: :index)
    end

    context 'when the Keycloak push fails' do
      before do
        stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still revokes local access, pages Sentry, and warns beside the success' do
        delete admin_user_path(target)

        expect(target.reload.active).to be false # authoritative local flip commits
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'PATCH expire_password' do
    before { stub_request(:put, target_url).to_return(status: 204) }

    it 'sets the UPDATE_PASSWORD required action in Keycloak' do
      patch expire_password_admin_user_path(target)

      expect(
        a_request(:put, target_url).with(body: { requiredActions: ['UPDATE_PASSWORD'] }),
      ).to have_been_made
      expect(response).to redirect_to(action: :index)
    end

    context 'when the Keycloak push fails' do
      before do
        stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      # There is no authoritative local change here, so a soft failure must not surface a success
      # notice claiming the password reset was scheduled — only the warning.
      it 'pages Sentry, warns, and does not claim success' do
        patch expire_password_admin_user_path(target)

        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).to be_blank
        expect(response).to redirect_to(action: :index)
      end
    end

    context 'when the user has no IdP identity on file' do
      # A real KeycloakService resolves (last_connector_id points at the configured connector),
      # but there is no user_authentication_sources row, so idp_connector_user_id! raises before
      # any HTTP call is made.
      let!(:orphan) { create(:acl_user, first_name: 'Orphan', last_name: 'User') }

      before do
        orphan.update_column(:last_connector_id, connector_id)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'degrades to a warning instead of raising' do
        patch expire_password_admin_user_path(orphan)

        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).to be_blank
        expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
        expect(response).to redirect_to(action: :index)
      end
    end

    context 'when the user has no IdP link at all' do
      # No last_connector_id and no user_authentication_sources row: primary_idp is nil, so the
      # account was never IdP-managed and there is nothing to push. The push-only action no-ops
      # silently rather than warning about an IdP the account was never part of.
      let!(:unlinked) { create(:acl_user, first_name: 'Unlinked', last_name: 'User') }

      before { allow(Sentry).to receive(:capture_exception_with_info) }

      it 'silently no-ops: no HTTP, no Sentry, no warning, no success claim' do
        patch expire_password_admin_user_path(unlinked)

        expect(Sentry).not_to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to be_blank
        expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
        expect(response).to redirect_to(action: :index)
      end
    end
  end

  describe 'GET edit' do
    it 'renders without seeding an OTP secret (2FA is IdP-managed)' do
      get edit_admin_user_path(target)

      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq(target)
    end

    it 'renders the IdP-provisioned name/email fields read-only' do
      get edit_admin_user_path(target)

      expect(assigns(:user).profile_managed_by_idp?).to be true
      # simple_form does not guarantee attribute order, so match either arrangement.
      ['first_name', 'last_name', 'email'].each do |field|
        disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
        expect(response.body).to match(disabled_input)
      end
    end
  end

  describe 'PATCH update' do
    it 'ignores changes to IdP-provisioned name/email but applies local fields' do
      patch admin_user_path(target), params: {
        user: { first_name: 'Hacked', last_name: 'Hacked', email: 'hacked@example.com', notify_on_client_added: '1' },
      }

      target.reload
      expect(target.first_name).to eq('Target')
      expect(target.last_name).to eq('User')
      expect(target.email).not_to eq('hacked@example.com')
      expect(target.notify_on_client_added).to be true
    end

    it 'ignores expired_at (the IdP does not honor local account expiry)' do
      patch admin_user_path(target), params: {
        user: { expired_at: 1.day.ago.to_date.to_s, notify_on_client_added: '1' },
      }

      target.reload
      expect(target.expired_at).to be_nil
      expect(target.notify_on_client_added).to be true
    end
  end

  describe 'Devise-only routes are absent under JWT' do
    it 'does not generate helpers for unlock, invitations, or locations' do
      expect { unlock_admin_user_path(target) }.to raise_error(NoMethodError)
      expect { admin_user_resend_invitation_path(target) }.to raise_error(NoMethodError)
      expect { admin_user_locations_path(target) }.to raise_error(NoMethodError)
    end
  end
end
