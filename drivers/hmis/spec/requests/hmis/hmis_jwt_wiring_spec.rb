###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'

# Proves the HMIS request layer wires the JWT auth path correctly when a Deployment boots with
# AUTH_METHOD=jwt. Mirrors spec/requests/idp/warehouse_jwt_wiring_spec.rb, but every auth-failure
# path returns JSON (the SPA contract) rather than an HTML redirect/render. The JWT examples run
# only under the AUTH_METHOD=jwt CI process (they lean on the JwtAuthenticationHelper sign_in,
# included only when AuthMethod.jwt?).
RSpec.describe 'HMIS JWT wiring', type: :request, if: AuthMethod.jwt? do
  let(:ds) { create :hmis_primary_data_source }
  let(:headers) { { 'HOST' => ds.hmis } }

  describe 'authentication via a forwarded JWT' do
    it 'admits an authenticated JWT request through the filter chain (POST session_keepalive → 200)' do
      user = create(:hmis_user)
      # idp_token_holder resolves the holder via find_or_create_from_jwt; pin it so resolution is
      # deterministic (token→user correctness is covered by Idp::JwtCurrentUser's own spec).
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
      sign_in(user)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
    end

    it 'admits the frontend\'s plain credentialed GET session_keepalive (no CSRF header)' do
      user = create(:hmis_user)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
      sign_in(user)

      get hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
    end

    it 'returns a JSON 401 for an unauthenticated request (no forwarded token), not an HTML redirect' do
      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('unauthenticated')
    end

    it 'returns a JSON 403 for a locally-deactivated token holder (active = false)' do
      inactive = create(:hmis_user, active: false)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(inactive.id))
      sign_in(inactive)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('account_deactivated')
    end
  end

  # Mirrors the Devise impersonations_controller_spec setup, but drives the JWT arm:
  # impersonate_hmis_user / stop_impersonating_hmis_user back the Rails session via
  # Idp::ImpersonationManager, and the next request re-resolves (and re-validates) it.
  describe 'impersonation under JWT' do
    let(:user_group) { create(:hmis_user_group) }
    let(:admin_user) do
      user = create(:hmis_user, data_source: ds)
      create_access_control(user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
      user
    end
    let(:target_user) { create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) } }

    before do
      # The JWT holder is always the admin; impersonation targets are re-fetched from the session by
      # id, not from the token (so a single pinned holder exercises the whole round-trip).
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(admin_user.id))
      sign_in(admin_user)
    end

    it 'creates impersonation (session-backed) and reflects it in the same request' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers

      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed['id']).to eq(target_user.id.to_s)
      expect(parsed['impersonating']).to eq(true)
      expect(controller.current_hmis_user).to eq(target_user)
    end

    it 'round-trips: a follow-up request honors the stored impersonation, then destroy clears it' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)

      # Fresh request: current_hmis_user is re-resolved from the session (per-request re-validation)
      # to the impersonated user, and the whodunnit follows it while true_user stays the admin.
      get hmis_user_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(target_user)
      expect(controller.true_hmis_user).to eq(admin_user)
      expect(controller.send(:info_for_paper_trail)).to include(
        user_id: target_user.id,
        true_user_id: admin_user.id,
      )
      parsed = JSON.parse(response.body)
      expect(parsed['trueUser']).to eq('id' => admin_user.id.to_s, 'name' => admin_user.name)
      expect(parsed).to have_key('primaryIdp')

      delete hmis_impersonations_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(admin_user.id.to_s)
      expect(controller.current_hmis_user).to eq(admin_user)
    end
  end

  describe 'logout' do
    it 'returns the oauth2-proxy sign-out URL as a JSON redirect_url, not an HTTP redirect' do
      user = create(:hmis_user)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
      sign_in(user)

      delete destroy_hmis_user_session_path, headers: headers

      expect(response).to have_http_status(:ok)
      redirect_url = JSON.parse(response.body)['redirect_url']
      expect(redirect_url).to start_with('/oauth2/sign_out?rd=')
      expect(CGI.unescape(redirect_url.split('rd=').last)).to eq(root_path)
    end
  end

  describe '#info_for_paper_trail' do
    # Distinct current/true users so the whodunnit's audit-under-impersonation behavior is actually
    # exercised: user_id must follow the impersonated user, true_user_id the real one.
    it 'records the impersonated user as user_id and the real user as true_user_id' do
      impersonated_user = create :hmis_user
      true_user = create :hmis_user
      controller = Hmis::BaseController.new
      allow(controller).to receive(:current_hmis_user).and_return(impersonated_user)
      allow(controller).to receive(:true_hmis_user).and_return(true_user)
      allow(controller).to receive(:session).and_return(double(id: double(to_s: 'sess-1')))
      allow(controller).to receive(:request).and_return(double(uuid: 'req-1'))

      info = controller.send(:info_for_paper_trail)

      expect(info[:user_id]).to eq(impersonated_user.id)
      expect(info[:true_user_id]).to eq(true_user.id)
    end
  end
end
