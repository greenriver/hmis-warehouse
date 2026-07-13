###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Proves the /api/superset/user_roles route + Api::SupersetController are wired correctly under
# AUTH_METHOD=jwt: a valid bearer token resolves the user read-only (no provisioning) and returns
# the role payload Superset needs; the route is entirely absent under Devise, mirroring how
# /oauth/user-data is absent under JWT (spec/requests/idp/warehouse_jwt_wiring_spec.rb).
RSpec.describe 'Superset JWT wiring', type: :request do
  describe 'GET /api/superset/user_roles', if: AuthMethod.jwt? do
    let(:user) { create(:user, superset_roles: ['Report Runner']) }

    it 'returns the role payload for a valid bearer token' do
      token = sign_in(user)

      get '/api/superset/user_roles', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'id' => user.id,
        'first_name' => user.first_name,
        'last_name' => user.last_name,
        'email' => user.email,
        'superset_roles' => user.superset_roles,
      )
    end

    it 'returns 401 with no bearer token' do
      get '/api/superset/user_roles'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with an invalid token' do
      # Stub at the Idp::JwtHelper boundary (as the connection.rb/wiring specs do) rather than
      # handing the real class a malformed string: WebMock.allow_net_connect! is on globally, so an
      # unstubbed token would try a real JWKS fetch instead of exercising this controller's 401 path.
      invalid_helper = instance_double(Idp::JwtHelper, token?: true, valid?: false)
      allow(Idp::JwtHelper).to receive(:new).with(access_token: 'not-a-real-token').and_return(invalid_helper)

      get '/api/superset/user_roles', headers: { 'Authorization' => 'Bearer not-a-real-token' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 for an expired (no longer valid) token' do
      token = sign_in(user)
      # sign_in stubs Idp::JwtHelper.new to return a single shared double for this token, so the
      # instance below IS the one the controller resolves. Re-stubbing valid? on it to false makes
      # an otherwise-good token read as expired.
      controller_helper = Idp::JwtHelper.new(access_token: token)
      allow(controller_helper).to receive(:valid?).and_return(false)

      get '/api/superset/user_roles', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 for an inactive user with an otherwise-valid token' do
      user.update!(active: false)
      token = sign_in(user)

      get '/api/superset/user_roles', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    # Regression guard: Superset forwards a live end-user token, so the resolved user may have
    # outstanding onboarding. If this endpoint rode ApplicationController, require_training! /
    # require_compliance_agreement! would redirect (302 -> HTML) instead of returning the role
    # JSON. Prove those filters are not in the chain, so a user with a pending compliance
    # requirement still gets 200 + JSON.
    it 'still returns the JSON payload when the resolved user has outstanding onboarding' do
      allow_any_instance_of(User).to receive(:pending_compliance_requirements).and_return([double('requirement')])
      token = sign_in(user)

      get '/api/superset/user_roles', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('superset_roles' => user.superset_roles)
    end
  end

  describe 'route surface' do
    it 'mounts /api/superset/user_roles only under JWT' do
      if AuthMethod.jwt?
        expect(Rails.application.routes.recognize_path('/api/superset/user_roles', method: :get)).
          to include(controller: 'api/superset', action: 'user_roles')
      else
        expect { Rails.application.routes.recognize_path('/api/superset/user_roles', method: :get) }.
          to raise_error(ActionController::RoutingError)
      end
    end
  end
end
