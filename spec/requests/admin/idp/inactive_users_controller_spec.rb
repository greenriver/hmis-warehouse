###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require 'nokogiri'

# JWT-arm inactive-user (reactivation) management.
RSpec.describe Admin::Idp::InactiveUsersController, :jwt_only, type: :request do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:target_connector_user_id) { 'kc-target-id' }

  let!(:admin_role) { create :admin_role }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User', active: false) }

  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{target_connector_user_id}" }

  let(:search_query) { create(:grda_warehouse_client_search_query, created_by: admin_user, params: { q: 'Target' }) }

  before(:each) do
    setup_access_control(admin_user, admin_role, collection)

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

  # The suite runs with net connect allowed, so restore it rather than leaving this file's
  # disable_net_connect! in place for later specs. Stubs are reset by webmock/rspec.
  after(:each) { WebMock.allow_net_connect! }

  describe 'PATCH reactivate' do
    let(:current_representation) { { id: target_connector_user_id, username: target.email } }

    before do
      stub_request(:get, target_url).to_return(status: 200, body: current_representation.to_json)
      stub_request(:put, target_url).to_return(status: 204)
    end

    it 'restores the local active flag and re-enables the account in Keycloak' do
      patch reactivate_admin_inactive_user_path(target)

      target.reload
      expect(target.active).to be true
      expect(target.expired_at).to be_nil
      expect(a_request(:put, target_url).with(body: current_representation.merge(enabled: true))).to have_been_made
      expect(response).to redirect_to(action: :index)
    end

    it 'records a PaperTrail version for the reactivation, so it shows up in Edit History' do
      PaperTrail.enabled = true
      begin
        expect do
          patch reactivate_admin_inactive_user_path(target)
        end.to change { target.versions.count }.by(1)
      ensure
        PaperTrail.enabled = false
      end

      version = target.versions.last
      expect(version.event).to eq('update')
      expect(version.changeset.symbolize_keys).to include(active: [false, true])
    end

    it 'sends no Devise reset-password email (Keycloak owns credentials)' do
      expect do
        patch reactivate_admin_inactive_user_path(target)
      end.not_to(change { ActionMailer::Base.deliveries.size })
    end

    context 'when the Keycloak push fails' do
      before do
        stub_request(:put, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      # The local reactivation and the push share a transaction, so a refused push rolls the local
      # side back rather than admitting the user here while Keycloak still has them disabled.
      it 'rolls the local reactivation back, pages Sentry, and reports nothing changed' do
        patch reactivate_admin_inactive_user_path(target)

        target.reload
        expect(target.active).to be false
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to match(/Nothing was changed/)
        expect(flash[:notice]).to be_blank
        expect(response).to redirect_to(action: :index)
      end
    end

    # Mirror of the deactivate case: a user pointed at a connector with no management API. The local
    # `active` flag is what admits them to the Warehouse, so restoring it must not be held hostage to
    # an IdP link that no longer exists.
    context "when the user's connector config has been deactivated" do
      before do
        Idp::ServiceConfig.find_by(connector_id: connector_id).update_column(:active, false)
      end

      it 'still restores local access, with no IdP call' do
        patch reactivate_admin_inactive_user_path(target)

        expect(target.reload.active).to be true
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).to be_blank
      end
    end

    # The sibling of the deactivated-config case: the connector is live, but there is no identity row
    # to push to, so the link is just as dead and the outcome is the same — local access restored,
    # because that is what admits them to the Warehouse — plus a warning, since the missing row needs
    # an admin to repair it.
    context 'when the user has no IdP identity on file' do
      before do
        target.user_authentication_sources.destroy_all
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'restores local access, attempts no IdP call, and warns that nothing was re-enabled there' do
        patch reactivate_admin_inactive_user_path(target)

        expect(target.reload.active).to be true
        expect(a_request(:put, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).to match(/no identity on file/)
        # A missing row is a data condition, not a failure to reach the IdP — nothing to page on.
        expect(Sentry).not_to have_received(:capture_exception_with_info)
      end
    end

    it 'refuses to reactivate a user who is not currently inactive' do
      patch reactivate_admin_inactive_user_path(admin_user)

      expect(response).to have_http_status(:not_found)
      expect(admin_user.reload.active).to be true
      expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
    end
  end

  # L28: reactivate inert — idp_reactivate! returns :unmanaged (not :identity_missing; identity is on
  # file), so local access restores with no Admin API call and no warning. app-1kz in the field.
  describe 'authenticate-only connector (manage_users:false, app-1kz)' do
    before(:each) do
      # Flip the config the shared setup created (a second active row for this connector would collide).
      Idp::ServiceConfig.find_by(connector_id: connector_id).update!(manage_users: false)
    end

    it 'restores local access with no Admin API call, no warning, and no raise' do
      patch reactivate_admin_inactive_user_path(target)

      expect(target.reload.active).to be true
      expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
      expect(flash[:alert]).to be_blank
      expect(response).to redirect_to(action: :index)
    end
  end

  describe 'GET index' do
    let!(:legacy_role) { create(:role, name: 'Case Manager Reviewer') }

    before { target.legacy_roles << legacy_role }

    it 'lists inactive users with their legacy-role names' do
      get admin_inactive_users_path

      expect(response).to have_http_status(:ok)
      target_row = Nokogiri::HTML(response.body).css('tbody tr').find { |row| row.text.include?(target.name) }
      expect(target_row).not_to be_nil
      expect(target_row.text).to include(legacy_role.name)
    end

    # Anchored on the inactive user being listed, because an empty table satisfies the exclusion on
    # its own and a scope narrowed to nothing would read as a pass.
    it 'excludes active users' do
      get admin_inactive_users_path

      listed = Nokogiri::HTML(response.body).css('tbody').text
      expect(listed).to include(target.email)
      expect(listed).not_to include(admin_user.email)
    end
  end

  # Search results are reached by a separate route from the browse page, and `perform_search` ends in
  # `render :index`, so the controller that handles the route decides which arm's page the admin sees.
  # See the route declaration in config/routes.rb.
  describe 'GET search' do
    it 'finds the inactive user and offers the IdP re-enable, not a password reset and reset email' do
      get inactive_user_search_query_admin_inactive_users_path(id: search_query.id)

      expect(response).to have_http_status(:ok)
      target_row = Nokogiri::HTML(response.body).css('tbody tr').find { |row| row.text.include?(target.name) }
      expect(target_row).not_to be_nil
      # The confirm text is the admin-visible difference between the arms' pages: the Devise-arm wording
      # promises credentials the IdP owns here.
      expect(response.body).to include('re-enabled in your identity provider')
      expect(response.body).not_to include('password will be set to something random')
    end

    # The admin is renamed to match the query, so an unscoped search would list them. Asserted on email
    # because the rename makes both users' display names identical.
    it 'stays scoped to inactive users' do
      admin_user.update!(first_name: 'Target')
      get inactive_user_search_query_admin_inactive_users_path(id: search_query.id)

      listed = Nokogiri::HTML(response.body).css('tbody').text
      expect(listed).to include(target.email)
      expect(listed).not_to include(admin_user.email)
    end

    it 'reports a missing search query rather than rendering an empty result set' do
      get inactive_user_search_query_admin_inactive_users_path(id: SecureRandom.uuid)

      expect(response).to redirect_to(admin_inactive_users_path)
      expect(flash[:error]).to eq('Search query not found')
    end
  end

  describe 'authorization (require_can_edit_users!)' do
    # A signed-in user whose role grants no can_edit_users. The privileged reactivate action must
    # be refused before any local change or IdP push, and the list itself must not render. Every
    # action here redirects on the way out, reactivate included, so the refusal is asserted on the
    # redirect target and alert rather than on the status.
    let!(:viewer_role) { create(:role) }
    let!(:non_admin) { create(:acl_user, first_name: 'View', last_name: 'Only') }

    before do
      setup_access_control(non_admin, viewer_role, collection)
      stub_request(:put, target_url).to_return(status: 204)
      sign_in non_admin
    end

    it 'refuses to reactivate a user and pushes nothing to the IdP' do
      patch reactivate_admin_inactive_user_path(target)

      expect(target.reload.active).to be false
      expect(a_request(:put, target_url)).not_to have_been_made
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Sorry you are not authorized to do that')
    end

    it 'refuses to list inactive users' do
      get admin_inactive_users_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Sorry you are not authorized to do that')
    end

    # Search is a second route into the same list, so the guard has to hold there too.
    it 'refuses to render search results' do
      get inactive_user_search_query_admin_inactive_users_path(id: search_query.id)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Sorry you are not authorized to do that')
    end
  end
end
