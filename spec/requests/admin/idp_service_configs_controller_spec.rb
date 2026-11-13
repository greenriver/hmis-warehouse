###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# Regression guard: the controller lives in `module Admin`, so an unqualified
# `Idp::ServiceConfig` resolves against the `Admin::Idp` namespace (created by
# Admin::Idp::UsersController) before the top-level `::Idp`. The references must
# stay fully-qualified (`::Idp::...`) or these pages raise
# `uninitialized constant Admin::Idp::ServiceConfig`. Every action below touches
# one of those references (directly, or via idp_service_config_scope), so a
# regression anywhere in the controller shows up as a 500 in one of these examples.
RSpec.describe Admin::IdpServiceConfigsController, type: :request do
  let!(:admin_role) { create :admin_role, can_manage_config: true }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:config) { create(:idp_service_config, connector_id: 'test', provider: 'keycloak') }

  let(:valid_params) do
    {
      idp_service_config: {
        provider: 'keycloak',
        connector_id: 'new-connector',
        name: 'New Keycloak Config',
        api_url: 'http://keycloak.test:8080',
        service_token: 'a-secret-token',
        client_id: 'rails-service-account',
        keycloak_realm: 'openpath',
        active: true,
      },
    }
  end

  before(:each) do
    setup_access_control(admin_user, admin_role, collection)
    sign_in admin_user
  end

  describe 'as an authorized admin' do
    it 'renders the index with the configured records (resolves ::Idp::ServiceConfig)' do
      get admin_idp_service_configs_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(config.name)
    end

    it 'renders the new form (resolves ::Idp::ServiceFactory)' do
      get new_admin_idp_service_config_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('keycloak') # provider select populated from Idp::ServiceFactory
    end

    it 'renders the edit form for an existing config' do
      get edit_admin_idp_service_config_path(config)
      expect(response).to have_http_status(200)
      expect(response.body).to include(config.name)
    end

    it 'creates a config from permitted params and redirects to the index' do
      expect do
        post admin_idp_service_configs_path, params: valid_params
      end.to change(::Idp::ServiceConfig, :count).by(1)

      created = ::Idp::ServiceConfig.order(:id).last
      expect(created.connector_id).to eq('new-connector')
      expect(created.service_token).to eq('a-secret-token')
      expect(response).to redirect_to(admin_idp_service_configs_path)
    end

    it 're-renders the new form without persisting when required params are missing' do
      expect do
        post admin_idp_service_configs_path, params: { idp_service_config: valid_params[:idp_service_config].merge(name: '') }
      end.not_to change(::Idp::ServiceConfig, :count)

      expect(response).to have_http_status(200)
      expect(response.body).to include('can&#39;t be blank')
    end

    it 'ignores unpermitted attributes on create (e.g. id, deleted_at)' do
      post admin_idp_service_configs_path, params: {
        idp_service_config: valid_params[:idp_service_config].merge(id: config.id, deleted_at: Time.current),
      }

      created = ::Idp::ServiceConfig.order(:id).last
      expect(created.id).not_to eq(config.id)
      expect(created.deleted_at).to be_nil
    end

    it 'updates permitted attributes on an existing config' do
      patch admin_idp_service_config_path(config), params: { idp_service_config: { name: 'Renamed Config' } }

      expect(config.reload.name).to eq('Renamed Config')
      expect(response).to redirect_to(admin_idp_service_configs_path)
    end

    it 'soft-deletes the config on destroy' do
      delete admin_idp_service_config_path(config)

      expect(::Idp::ServiceConfig.find_by(id: config.id)).to be_nil
      expect(::Idp::ServiceConfig.with_deleted.find(config.id).deleted_at).to be_present
      expect(response).to redirect_to(admin_idp_service_configs_path)
    end

    describe 'POST test (connectivity check)' do
      let(:token_url) { "#{config.api_url}/realms/#{config.keycloak_realm}/protocol/openid-connect/token" }
      let(:realm_url) { "#{config.api_url}/admin/realms/#{config.keycloak_realm}/users?max=1" }

      before do
        WebMock.disable_net_connect!
        stub_request(:post, token_url).to_return(
          status: 200,
          body: { access_token: 'test-token', expires_in: 300 }.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
      end

      after do
        WebMock.reset!
        WebMock.allow_net_connect!
      end

      it 'flashes success and redirects when the connection check succeeds' do
        stub_request(:get, realm_url).to_return(status: 200, body: { realm: config.keycloak_realm }.to_json)

        post test_admin_idp_service_config_path(config)

        expect(flash[:success]).to include('Connection successful')
        expect(response).to redirect_to(admin_idp_service_configs_path)
      end

      it 'flashes the failure message and redirects when the connection check fails' do
        stub_request(:get, realm_url).to_return(status: 401)

        post test_admin_idp_service_config_path(config)

        expect(flash[:error]).to include('Authentication failed')
        expect(response).to redirect_to(admin_idp_service_configs_path)
      end

      it 'rescues Idp::ServiceError from a misconfigured record instead of raising' do
        config.update_column(:keycloak_realm, nil)

        post test_admin_idp_service_config_path(config)

        expect(flash[:error]).to include('Connection failed').and include('missing: realm')
        expect(response).to redirect_to(admin_idp_service_configs_path)
        expect(a_request(:get, realm_url)).not_to have_been_made
      end
    end
  end

  describe 'without can_manage_config' do
    let!(:viewer_role) { create(:role) }
    let!(:non_admin) { create(:acl_user, first_name: 'View', last_name: 'Only') }

    before do
      setup_access_control(non_admin, viewer_role, collection)
      sign_in non_admin
    end

    it 'refuses index' do
      get admin_idp_service_configs_path
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to create a config' do
      expect do
        post admin_idp_service_configs_path, params: valid_params
      end.not_to change(::Idp::ServiceConfig, :count)
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to render the edit form' do
      get edit_admin_idp_service_config_path(config)
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to update a config' do
      patch admin_idp_service_config_path(config), params: { idp_service_config: { name: 'Hacked' } }
      expect(config.reload.name).not_to eq('Hacked')
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses to destroy a config' do
      delete admin_idp_service_config_path(config)
      expect(::Idp::ServiceConfig.find_by(id: config.id)).to be_present
      expect(response).to have_http_status(:redirect)
    end

    it 'refuses the connectivity test and makes no external request' do
      WebMock.disable_net_connect!
      post test_admin_idp_service_config_path(config)
      expect(response).to have_http_status(:redirect)
      WebMock.allow_net_connect!
    end
  end
end
