###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require 'nokogiri'

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

      it 'still restores local access, pages Sentry, and warns beside the success notice' do
        patch reactivate_admin_inactive_user_path(target)

        target.reload
        expect(target.active).to be true # authoritative local flip commits
        expect(target.expired_at).to be_nil
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).to be_present
        expect(response).to redirect_to(action: :index)
      end
    end

    it 'refuses to reactivate a user who is not currently inactive' do
      patch reactivate_admin_inactive_user_path(admin_user)

      expect(response).to have_http_status(:not_found)
      expect(admin_user.reload.active).to be true
      expect(a_request(:put, /\/admin\/realms\/#{realm}\/users\//)).not_to have_been_made
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

    it 'excludes active users' do
      get admin_inactive_users_path

      rows = Nokogiri::HTML(response.body).css('tbody tr')
      expect(rows.none? { |row| row.text.include?(admin_user.name) }).to be true
    end
  end

  describe 'authorization (require_can_edit_users!)' do
    # A signed-in user whose role grants no can_edit_users. The privileged reactivate action must
    # be refused before any local change or IdP push, and the list itself must not render.
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
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to list inactive users' do
      get admin_inactive_users_path

      expect(response).to have_http_status(:redirect)
    end
  end
end
