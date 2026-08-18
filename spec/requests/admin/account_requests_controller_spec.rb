###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Admin::AccountRequestsController, :jwt_only, type: :request do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }

  let!(:admin_role) { create :admin_role }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:agency) { create :agency }
  let!(:target_role) { create(:role, can_view_clients: true) }

  before(:each) do
    # Backs the admin's own JWT session (JwtAuthenticationHelper#sign_in uses connector_id 'test').
    create(:idp_service_config, connector_id: 'test', api_url: api_url, keycloak_realm: realm)
    setup_access_control(admin_user, admin_role, collection)
    sign_in admin_user
  end

  let(:account_request) { create(:account_request, email: 'newcomer@example.com', first_name: 'New', last_name: 'Comer') }

  def approve(params = {})
    patch admin_account_request_path(account_request), params: {
      account_request: {
        agency_id: agency.id,
        role_ids: [target_role.id],
        access_group_ids: [],
      }.merge(params),
    }
  end

  context 'approving a request' do
    before { WebMock.disable_net_connect! }

    after { WebMock.allow_net_connect! }

    it 'creates a local-only, email-keyed user with the requested roles and no remote call' do
      expect { approve }.to change(User, :count).by(1)

      user = User.find_by(email: 'newcomer@example.com')
      expect(user).to be_present
      expect(user.agency_id).to eq(agency.id)
      expect(user.user_authentication_sources).to be_empty
      expect(user.last_connector_id).to be_nil
      expect(user.legacy_roles).to include(target_role)

      account_request.reload
      expect(account_request.status).to eq('accepted')
      expect(account_request.user_id).to eq(user.id)
      expect(account_request.accepted_by).to eq(admin_user.id)
    end

    it 'does not raise NoMethodError for invite! (the Devise-only path)' do
      approve
      expect(response).to have_http_status(:redirect)
    end
  end

  it 'requires an agency' do
    expect { approve(agency_id: '') }.not_to change(User, :count)
    account_request.reload
    expect(account_request.status).to eq('requested')
  end
end
