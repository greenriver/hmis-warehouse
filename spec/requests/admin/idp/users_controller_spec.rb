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

    it 'offers an "Add a User Account" button linking to the IdP create form' do
      get admin_users_path
      expect(response.body).to include(new_admin_user_path)
    end

    it 'omits the create button when no connector can provision accounts' do
      allow_any_instance_of(::Idp::KeycloakService).to receive(:supports_user_creation?).and_return(false)
      get admin_users_path
      expect(response.body).not_to include(new_admin_user_path)
    end
  end

  describe 'GET new' do
    it 'renders the create form' do
      get new_admin_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    let(:new_email) { 'newbie@example.com' }
    let(:users_url) { "#{api_url}/admin/realms/#{realm}/users" }
    let(:new_kc_id) { 'kc-new-id' }
    let(:actions_url) { "#{api_url}/admin/realms/#{realm}/users/#{new_kc_id}/execute-actions-email" }
    let(:params) { { user: { first_name: 'New', last_name: 'Bie', email: new_email, connector_id: connector_id } } }

    context 'when the email is new to Keycloak' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 201, headers: { 'Location' => "#{users_url}/#{new_kc_id}" })
        stub_request(:put, actions_url).to_return(status: 204)
      end

      it 'creates the local user, provisions and links Keycloak, and sends the setup email' do
        expect { post admin_users_path, params: params }.to change(User, :count).by(1)

        user = User.find_by(email: new_email)
        expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to include([connector_id, new_kc_id])
        expect(user.last_connector_id).to eq(connector_id)
        expect(a_request(:post, users_url)).to have_been_made
        expect(a_request(:put, actions_url).with(body: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'].to_json)).to have_been_made
        expect(response).to redirect_to(edit_admin_user_path(user))
        expect(flash[:notice]).to match(/setup email has been sent/)
      end
    end

    context 'when the email already exists in Keycloak' do
      let(:existing_kc_id) { 'kc-existing-id' }
      let(:existing_actions_url) { "#{api_url}/admin/realms/#{realm}/users/#{existing_kc_id}/execute-actions-email" }

      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).
          to_return(status: 200, body: [{ id: existing_kc_id, email: new_email }].to_json)
        stub_request(:put, existing_actions_url).to_return(status: 204)
      end

      it 'links the existing remote account instead of creating a duplicate' do
        expect { post admin_users_path, params: params }.to change(User, :count).by(1)

        user = User.find_by(email: new_email)
        expect(user.user_authentication_sources.pluck(:connector_user_id)).to include(existing_kc_id)
        expect(a_request(:post, users_url)).not_to have_been_made
        expect(a_request(:put, existing_actions_url)).to have_been_made
        expect(response).to redirect_to(edit_admin_user_path(user))
      end
    end

    context 'when the setup email fails to send' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 201, headers: { 'Location' => "#{users_url}/#{new_kc_id}" })
        stub_request(:put, actions_url).to_return(status: 500, body: { errorMessage: 'SMTP down' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still creates the account, pages Sentry, and warns the email did not send' do
        post admin_users_path, params: params

        user = User.find_by(email: new_email)
        expect(user).to be_present
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).not_to match(/setup email has been sent/)
        expect(response).to redirect_to(edit_admin_user_path(user))
      end
    end

    context 'when the email already exists locally' do
      let!(:dup) { create(:acl_user, email: new_email) }

      it 're-renders the form and never provisions Keycloak' do
        expect { post admin_users_path, params: params }.not_to change(User, :count)

        expect(a_request(:get, users_url)).not_to have_been_made
        expect(a_request(:post, users_url)).not_to have_been_made
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the Keycloak create fails' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 409, body: { errorMessage: 'User exists with same username' }.to_json)
      end

      it 'does not create the local user and re-renders the form' do
        expect { post admin_users_path, params: params }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(a_request(:put, /execute-actions-email/)).not_to have_been_made
      end
    end
  end

  describe 'DELETE destroy (deactivate)' do
    let(:current_representation) { { id: target_connector_user_id, username: target.email } }

    before do
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
    end

    it 'flips the local active flag and pushes enabled=false to Keycloak' do
      delete admin_user_path(target)

      expect(target.reload.active).to be false
      expect(a_request(:put, target_url).with(body: current_representation.merge(enabled: false))).to have_been_made
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
    let(:current_representation) { { id: target_connector_user_id, username: target.email } }

    before do
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
    end

    it 'sets the UPDATE_PASSWORD required action in Keycloak' do
      patch expire_password_admin_user_path(target)

      expect(
        a_request(:put, target_url).with(body: current_representation.merge(requiredActions: ['UPDATE_PASSWORD'])),
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
    it 'renders the name/email fields editable, since Keycloak accepts profile writes' do
      get edit_admin_user_path(target)

      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq(target)
      ['first_name', 'last_name', 'email'].each do |field|
        disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
        expect(response.body).not_to match(disabled_input)
      end
    end
  end

  describe 'PATCH update' do
    let(:current_representation) { { id: target_connector_user_id, username: target.email, firstName: 'Target', lastName: 'User', email: target.email } }

    before do
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
    end

    it 'applies name/email changes locally and syncs them to Keycloak' do
      patch admin_user_path(target), params: {
        user: { first_name: 'Changed', last_name: 'Name', email: 'changed@example.com', notify_on_client_added: '1' },
      }

      target.reload
      expect(target.first_name).to eq('Changed')
      expect(target.last_name).to eq('Name')
      expect(target.email).to eq('changed@example.com')
      expect(target.notify_on_client_added).to be true
      expect(
        a_request(:put, target_url).
          with(body: current_representation.merge(firstName: 'Changed', lastName: 'Name', email: 'changed@example.com', emailVerified: false)),
      ).to have_been_made
    end

    it 'syncs a name change for a role-based (legacy) user, whose update writes associations after the save' do
      legacy = create(:user, first_name: 'Legacy', last_name: 'User')
      legacy.user_authentication_sources.find_or_create_by!(
        connector_id: connector_id,
        connector_user_id: 'kc-legacy-id',
      )
      legacy.update_column(:last_connector_id, connector_id)
      legacy_url = "#{api_url}/admin/realms/#{realm}/users/kc-legacy-id"
      legacy_representation = { id: 'kc-legacy-id', username: legacy.email, firstName: 'Legacy', lastName: 'User', email: legacy.email }
      stub_request(:get, legacy_url).to_return(status: 200, body: legacy_representation.to_json)
      stub_request(:put, legacy_url).to_return(status: 204)

      patch admin_user_path(legacy), params: { user: { first_name: 'Renamed' } }

      expect(legacy.reload.first_name).to eq('Renamed')
      expect(
        a_request(:put, legacy_url).with(body: legacy_representation.merge(firstName: 'Renamed')),
      ).to have_been_made
    end

    it 'does not call Keycloak when no name/email field changed' do
      patch admin_user_path(target), params: {
        user: { notify_on_client_added: '1' },
      }

      expect(a_request(:get, target_url)).not_to have_been_made
      expect(a_request(:put, target_url)).not_to have_been_made
    end

    context 'when the Keycloak push fails' do
      before do
        stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still saves the local change, pages Sentry, and warns beside the success' do
        patch admin_user_path(target), params: { user: { first_name: 'Changed' } }

        target.reload
        expect(target.first_name).to eq('Changed')
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
      end
    end

    it 'strips crafted name/email params for a locked (unlinked) profile and never calls Keycloak' do
      unlinked = create(:acl_user, first_name: 'Locked', last_name: 'User', email: 'locked@example.com')

      patch admin_user_path(unlinked), params: {
        user: { first_name: 'Hacked', last_name: 'Hacked', email: 'hacked@example.com', notify_on_client_added: '1' },
      }

      unlinked.reload
      expect(unlinked.first_name).to eq('Locked')
      expect(unlinked.last_name).to eq('User')
      expect(unlinked.email).to eq('locked@example.com')
      expect(unlinked.notify_on_client_added).to be true
      expect(a_request(:put, /#{Regexp.escape(api_url)}/)).not_to have_been_made
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

  describe 'authorization (require_can_edit_users!)' do
    # A signed-in user whose role grants no can_edit_users. The privileged, destructive actions
    # must be refused before any local change or IdP push, not merely hidden from the menu.
    let!(:viewer_role) { create(:role) }
    let!(:non_admin) { create(:acl_user, first_name: 'View', last_name: 'Only') }

    before do
      setup_access_control(non_admin, viewer_role, collection)
      stub_request(:put, target_url).to_return(status: 204)
      sign_in non_admin
    end

    it 'refuses to deactivate a user and pushes nothing to the IdP' do
      delete admin_user_path(target)

      expect(target.reload.active).to be true
      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to force a password change and pushes nothing to the IdP' do
      patch expire_password_admin_user_path(target)

      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to render the edit form' do
      get edit_admin_user_path(target)

      expect(response).to have_http_status(:redirect)
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
