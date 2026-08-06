###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require 'nokogiri'

# JWT-arm admin user management. On this arm the route-level seam mounts Admin::Idp::UsersController
# and JwtAuthenticationHelper#sign_in is active.
RSpec.describe Admin::Idp::UsersController, :jwt_only, type: :request do
  # Keycloak/IdP scaffolding: a creation-capable 'test' connector backed by DB credentials,
  # a stubbed token endpoint, and WebMock net isolation.
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }
  let(:users_url) { "#{api_url}/admin/realms/#{realm}/users" }

  before(:each) do
    # DB-managed Keycloak credentials for the 'test' connector so it resolves to a real
    # KeycloakService rather than a NullService and reports itself as creation-capable.
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )

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

  let(:target_connector_user_id) { 'kc-target-id' }

  let!(:admin_role) { create :admin_role }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User') }

  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{target_connector_user_id}" }

  before(:each) do
    setup_access_control(admin_user, admin_role, collection)

    target.user_authentication_sources.find_or_create_by!(
      connector_id: connector_id,
      connector_user_id: target_connector_user_id,
    )
    target.update_column(:last_connector_id, connector_id)

    sign_in admin_user
  end

  describe 'IdP-backed user creation' do
    let(:new_email) { 'newbie@example.com' }
    let(:new_kc_id) { 'kc-new-id' }
    let(:actions_url) { "#{users_url}/#{new_kc_id}/execute-actions-email" }
    let(:params) { { user: { first_name: 'New', last_name: 'Bie', email: new_email, connector_id: connector_id } } }

    describe 'GET index' do
      it 'offers an "Add a User Account" button linking to the create form' do
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
      context 'when the email is new to the IdP' do
        before do
          stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
          stub_request(:post, users_url).to_return(status: 201, headers: { 'Location' => "#{users_url}/#{new_kc_id}" })
          stub_request(:put, actions_url).to_return(status: 204)
        end

        it 'creates the local user, provisions and links the IdP, sends the setup email, and redirects to edit' do
          expect { post admin_users_path, params: params }.to change(User, :count).by(1)

          user = User.find_by(email: new_email)
          expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to include([connector_id, new_kc_id])
          expect(user.last_connector_id).to eq(connector_id)
          expect(a_request(:post, users_url)).to have_been_made
          expect(a_request(:put, actions_url).with(body: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'].to_json)).to have_been_made
          expect(response).to redirect_to(edit_admin_user_path(user))
          expect(flash[:notice]).to match(/setup email has been sent/)
          expect(flash[:notice]).to match(/roles and access/i)
        end
      end

      context 'when the email already exists in the IdP' do
        let(:existing_kc_id) { 'kc-existing-id' }
        let(:existing_actions_url) { "#{users_url}/#{existing_kc_id}/execute-actions-email" }

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

        it 're-renders the form and never provisions the IdP' do
          expect { post admin_users_path, params: params }.not_to change(User, :count)

          expect(a_request(:get, users_url)).not_to have_been_made
          expect(a_request(:post, users_url)).not_to have_been_made
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when the IdP rejects the account creation' do
        before do
          stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
          stub_request(:post, users_url).to_return(status: 409, body: { errorMessage: 'User exists with same username' }.to_json)
        end

        # A 409 means the realm already has that address on another account — a form problem, so it
        # lands on the email field rather than reading as a broken connector.
        it 'does not create the local user and reports the conflict on the email field' do
          expect { post admin_users_path, params: params }.not_to change(User, :count)

          expect(response).to have_http_status(:ok)
          expect(response.body).to match(/already registered with Keycloak/)
          expect(a_request(:put, /execute-actions-email/)).not_to have_been_made
        end
      end
    end

    # JWT is on (routes mounted), but no active connector reports itself creation-capable, so
    # require_user_creation_available! sends the admin back to the index instead of the form.
    describe 'when no connector can provision accounts' do
      before do
        allow_any_instance_of(::Idp::KeycloakService).to receive(:supports_user_creation?).and_return(false)
      end

      it 'redirects GET new to the index with an unavailable alert' do
        get new_admin_user_path

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:alert]).to match(/not available/i)
      end

      it 'redirects POST create to the index without creating a user' do
        expect { post admin_users_path, params: params }.not_to change(User, :count)

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:alert]).to match(/not available/i)
      end
    end
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

  # Search results are reached by a separate route from the browse page, and `perform_search` ends in
  # `render :index`, so the controller that handles the route decides which arm's page the admin sees.
  # See the route declaration in config/routes.rb.
  describe 'GET search' do
    let(:search_query) { create(:grda_warehouse_client_search_query, created_by: admin_user, params: { q: 'Target' }) }

    # Routed at the Devise arm's controller this raised NameError on
    # app/views/admin/users/index.haml's unconditional new_user_invitation_path, which is not routed
    # under JWT — so the 200 is the assertion, not incidental setup.
    it 'renders the JWT arm’s page rather than raising on a Devise-only route helper' do
      get user_search_query_admin_users_path(id: search_query.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.email)
      # The create button is the arm's marker: this arm links its own form, the Devise arm links the
      # invitation flow.
      expect(response.body).to include(new_admin_user_path)
    end

    it 'offers the IdP-worded password reset, not the Devise arm’s immediate-logout wording' do
      get user_search_query_admin_users_path(id: search_query.id)

      expect(response.body).to include('will be required to choose a new password on next login')
      expect(response.body).not_to include('will be immediately logged out')
    end

    # Anchored on the linked user being listed, because an empty table satisfies the exclusion on its
    # own and a scope narrowed to nothing would read as a pass.
    it 'stays scoped to active users' do
      inactive = create(:acl_user, first_name: 'Target', last_name: 'Inactive', active: false)

      get user_search_query_admin_users_path(id: search_query.id)

      listed = Nokogiri::HTML(response.body).css('tbody').text
      expect(listed).to include(target.email)
      expect(listed).not_to include(inactive.email)
    end

    it 'reports a missing search query rather than rendering an empty result set' do
      get user_search_query_admin_users_path(id: SecureRandom.uuid)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:error]).to eq('Search query not found')
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

      # The local deactivation and the push share a transaction, so a refused push rolls the local
      # side back rather than leaving the account disabled here and enabled in Keycloak.
      it 'rolls the local deactivation back, pages Sentry, and says the user still has access' do
        delete admin_user_path(target)

        expect(target.reload.active).to be true
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to match(/still has access/)
        expect(flash[:notice]).to be_blank
      end
    end

    # Deactivating the connector config leaves the user pointed at a connector with no management
    # API. Local revocation is what cuts off access to the Warehouse, so it must not be held hostage
    # to an IdP link that no longer exists.
    context "when the user's connector config has been deactivated" do
      before do
        Idp::ServiceConfig.find_by(connector_id: connector_id).update_column(:active, false)
      end

      it 'still revokes local access, with no IdP call' do
        delete admin_user_path(target)

        expect(target.reload.active).to be false
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_present
      end
    end

    # The sibling of the deactivated-config case: the connector is live, but there is no identity row
    # to push to, so the link is just as dead and the outcome is the same — local access revoked,
    # because the local flag is what admits them to the Warehouse — plus a warning, since the missing
    # row needs an admin to repair it and may have pointed at an account still enabled in the IdP.
    # Matches Admin::Idp::InactiveUsersController#reactivate, so the two directions agree.
    context 'when the connector is live but the user has no identity row' do
      before do
        target.user_authentication_sources.destroy_all
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'revokes local access, attempts no IdP call, and warns that nothing was disabled there' do
        delete admin_user_path(target)

        expect(target.reload.active).to be false
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).to match(/no identity on file/)
        # A missing row is a data condition, not a failure to reach the IdP — nothing to page on.
        expect(Sentry).not_to have_received(:capture_exception_with_info)
      end
    end

    # A config that is still active but can't be turned into a service (client_id and keycloak_realm
    # aren't validated on Idp::ServiceConfig) is not the same as a connector that was retired: there
    # is an IdP holding this account that we are failing to reach. Revoking locally anyway would
    # leave the account enabled there with nothing to say so.
    context "when the user's connector config is active but unusable" do
      before do
        Idp::ServiceConfig.find_by(connector_id: connector_id).update_column(:client_id, nil)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'refuses to revoke local access, pages Sentry, and says the user still has access' do
        delete admin_user_path(target)

        expect(target.reload.active).to be true
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to match(/still has access/)
        expect(flash[:notice]).to be_blank
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

    # Same gate as deactivate/reactivate: a retired connector has no management API, so there is
    # nothing to push and nothing to warn about.
    context "when the user's connector config has been deactivated" do
      before do
        Idp::ServiceConfig.find_by(connector_id: connector_id).update_column(:active, false)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'silently no-ops: no HTTP, no Sentry, no warning, no success claim' do
        patch expire_password_admin_user_path(target)

        expect(Sentry).not_to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to be_blank
        expect(a_request(:put, target_url)).not_to have_been_made
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
        # The field has to be on the page before its lack of a disabled attribute means anything —
        # otherwise a form that dropped the input entirely reads as a pass.
        expect(response.body).to match(/<input[^>]*name="user\[#{field}\]"/)
        disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
        expect(response.body).not_to match(disabled_input)
      end
    end
  end

  describe 'PATCH update' do
    let(:current_representation) { { id: target_connector_user_id, username: target.email, firstName: 'Target', lastName: 'User', email: target.email } }
    let(:target_actions_url) { "#{target_url}/execute-actions-email" }

    before do
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
      stub_request(:put, target_actions_url).to_return(status: 204)
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
      expect(a_request(:put, target_actions_url).with(body: ['VERIFY_EMAIL'].to_json)).to have_been_made
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

      # The local save and the push share a transaction, so a refused push takes the save with it.
      it 'saves nothing locally, pages Sentry, and re-renders saying so' do
        patch admin_user_path(target), params: { user: { first_name: 'Changed' } }

        expect(target.reload.first_name).to eq('Target')
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(response.body).to match(/Nothing was saved/)
      end
    end

    # Keycloak answers 409 when the address belongs to another account in the realm. That is a form
    # problem, not a broken connector: it names the field and never pages.
    context 'when the email is already registered to a different account in the IdP' do
      before do
        stub_request(:put, target_url).to_return(
          status: 409,
          body: { errorMessage: 'User exists with same email' }.to_json,
        )
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'saves nothing locally and reports the conflict on the email field' do
        patch admin_user_path(target), params: { user: { email: 'taken@example.com' } }

        expect(target.reload.email).not_to eq('taken@example.com')
        expect(response.body).to match(/already registered with Keycloak/)
        expect(Sentry).not_to have_received(:capture_exception_with_info)
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
    # A signed-in user whose role grants no can_edit_users. Every action must be refused before any
    # local change or IdP push, not merely hidden from the menu. An unauthenticated bounce is also a
    # redirect, so the refusal is asserted on the redirect target and alert rather than the status.
    let!(:viewer_role) { create(:role) }
    let!(:non_admin) { create(:acl_user, first_name: 'View', last_name: 'Only') }

    let(:refusal) { 'Sorry you are not authorized to do that' }

    before do
      setup_access_control(non_admin, viewer_role, collection)
      stub_request(:put, target_url).to_return(status: 204)
      sign_in non_admin
    end

    it 'refuses to deactivate a user and pushes nothing to the IdP' do
      delete admin_user_path(target)

      expect(target.reload.active).to be true
      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    it 'refuses to force a password change and pushes nothing to the IdP' do
      patch expire_password_admin_user_path(target)

      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    # new and create carry require_user_creation_available! of their own, and create provisions an
    # account in the remote IdP, so require_can_edit_users! has to be the filter that runs first.
    it 'refuses to render the create form' do
      get new_admin_user_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    it 'refuses to create a user and provisions nothing in the IdP' do
      expect do
        post admin_users_path, params: { user: { first_name: 'New', last_name: 'Bie', email: 'newbie@example.com', connector_id: connector_id } }
      end.not_to change(User, :count)

      expect(a_request(:get, users_url)).not_to have_been_made
      expect(a_request(:post, users_url)).not_to have_been_made
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    it 'refuses to update a profile and pushes nothing to the IdP' do
      patch admin_user_path(target), params: { user: { first_name: 'Hacked', email: 'hacked@example.com' } }

      target.reload
      expect(target.first_name).to eq('Target')
      expect(target.email).not_to eq('hacked@example.com')
      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    # The list itself carries every active user's email, so the guard has to hold on the plain browse
    # page and not only on the actions reached from it.
    it 'refuses to list users' do
      get admin_users_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
      expect(response.body).not_to include(target.email)
    end

    # Search is a second route into the same list, so the guard has to hold there too.
    it 'refuses to render search results' do
      search_query = create(:grda_warehouse_client_search_query, created_by: admin_user, params: { q: 'Target' })

      get user_search_query_admin_users_path(id: search_query.id)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
    end

    it 'refuses to render the edit form' do
      get edit_admin_user_path(target)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(refusal)
      expect(response.body).not_to include(target.email)
    end
  end

  describe 'Devise-only routes are absent under JWT' do
    it 'does not generate helpers for unlock, invitations, or locations' do
      expect { unlock_admin_user_path(target) }.to raise_error(NoMethodError)
      expect { admin_user_resend_invitation_path(target) }.to raise_error(NoMethodError)
      expect { admin_user_locations_path(target) }.to raise_error(NoMethodError)
    end
  end

  # Authenticate-only connector (active config, manage_users:false — app-1kz). Ledger rows L4/L8/L18/L23.
  describe 'authenticate-only connector (manage_users:false, app-1kz)' do
    before(:each) do
      # Flip the config the shared setup created (a second active row for this connector would collide).
      Idp::ServiceConfig.find_by(connector_id: connector_id).update!(manage_users: false)
    end

    describe 'GET edit' do # L4: profile locked
      it 'renders the name/email fields disabled, since the connector accepts no profile writes' do
        get edit_admin_user_path(target)

        expect(response).to have_http_status(:ok)
        ['first_name', 'last_name', 'email'].each do |field|
          # The field has to be on the page before its disabled attribute means anything — a form that
          # dropped the input entirely would otherwise read as a pass.
          expect(response.body).to match(/<input[^>]*name="user\[#{field}\]"/)
          disabled_input = /<input[^>]*name="user\[#{field}\]"[^>]*disabled|<input[^>]*disabled[^>]*name="user\[#{field}\]"/
          expect(response.body).to match(disabled_input)
        end
      end
    end

    # L8: update inert — identity params stripped and idp_update_profile! no-ops (two independent guards).
    describe 'PATCH update' do
      it 'ignores submitted name/email changes, saves local fields, calls no Admin API, and does not raise' do
        patch admin_user_path(target), params: {
          user: { first_name: 'Changed', last_name: 'Name', email: 'changed@example.com', notify_on_client_added: '1' },
        }

        target.reload
        expect(target.first_name).to eq('Target')
        expect(target.email).not_to eq('changed@example.com')
        expect(target.notify_on_client_added).to be true # a local-only field still saves
        expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
        expect(response).not_to have_http_status(:error)
      end
    end

    # L18: force-password inert — idp_force_password_change! returns false before any HTTP.
    describe 'PATCH expire_password' do
      it 'silently no-ops: no Admin API call, no success claim, no warning, and no raise' do
        allow(Sentry).to receive(:capture_exception_with_info)

        patch expire_password_admin_user_path(target)

        expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
        expect(Sentry).not_to have_received(:capture_exception_with_info)
        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
        expect(response).to redirect_to(action: :index)
      end
    end

    # L23: deactivate inert — idp_deactivate! returns :unmanaged (not :identity_missing; the identity
    # is on file), so local access still revokes with no Admin API call and no warning.
    describe 'DELETE destroy (deactivate)' do
      it 'revokes local access with no Admin API call, no warning, and no raise' do
        delete admin_user_path(target)

        expect(target.reload.active).to be false
        expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
        expect(flash[:alert]).to be_blank
        expect(response).to redirect_to(action: :index)
      end
    end
  end
end
