###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm inactive-user (reactivation) management. Requires an AUTH_METHOD=jwt boot (CI step).
RSpec.describe Admin::Idp::InactiveUsersController, type: :request, if: AuthMethod.jwt? do
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

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  describe 'PATCH reactivate' do
    before { stub_request(:put, target_url).to_return(status: 204) }

    it 'restores the local active flag and re-enables the account in Keycloak' do
      patch reactivate_admin_inactive_user_path(target)

      target.reload
      expect(target.active).to be true
      expect(target.expired_at).to be_nil
      expect(a_request(:put, target_url).with(body: { enabled: true })).to have_been_made
      expect(response).to redirect_to(action: :index)
    end

    it 'sends no Devise reset-password email (Keycloak owns credentials)' do
      expect do
        patch reactivate_admin_inactive_user_path(target)
      end.not_to(change { ActionMailer::Base.deliveries.size })
    end
  end

  describe 'GET index' do
    before { target.legacy_roles << admin_role }

    it 'lists inactive users with their legacy-role names' do
      get admin_inactive_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Target')
      expect(response.body).to include(admin_role.name)
    end
  end
end
