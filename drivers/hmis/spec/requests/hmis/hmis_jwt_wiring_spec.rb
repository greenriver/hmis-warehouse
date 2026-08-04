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
#
# find_or_create_from_jwt is deliberately NOT stubbed: sign_in provisions a real
# Idp::UserAuthenticationSource for the token's (connector_id, connector_user_id), so the real
# Idp::UserProvisioner resolves the holder off the token's own claims. Pinning the return value
# would make token→holder resolution unfalsifiable — resolving the wrong user, or ignoring the
# token entirely, would still pass. The one exception is the no-warehouse-account example, which
# stubs nil to force a branch that has no reachable fixture.
RSpec.describe 'HMIS JWT wiring', type: :request, if: AuthMethod.jwt? do
  let(:ds) { create :hmis_primary_data_source }
  let(:headers) { { 'HOST' => ds.hmis } }

  describe 'authentication via a forwarded JWT' do
    it 'admits an authenticated JWT request through the filter chain (POST session_keepalive → 200)' do
      user = create(:hmis_user)
      sign_in(user)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
      # The holder resolved off the token's claims, not off whichever user the DB happened to
      # return: set_app_user_header reports current_hmis_user, so this is what makes the
      # unstubbed resolution above load-bearing.
      expect(response.headers['X-app-user-id'].to_s).to eq(user.id.to_s)
    end

    # GET rather than POST because SessionKeepalivesController aliases show to create, and the SPA
    # polls the GET. Not a CSRF assertion — config.action_controller.allow_forgery_protection is
    # false in test, and Rails never verifies the token on GET anyway.
    it 'admits the aliased GET session_keepalive as well as the POST' do
      user = create(:hmis_user)
      sign_in(user)

      get hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
      expect(response.headers['X-app-user-id'].to_s).to eq(user.id.to_s)
    end

    # Not a JSON 401: nothing authenticates its own callers here, so a tokenless request means the
    # proxy was bypassed, and a 401 would disguise that as an ordinary signed-out client.
    it 'raises on a request with no forwarded token rather than answering with a JSON 401' do
      expect { post hmis_session_keepalive_path, headers: headers }.
        to raise_error(Idp::UnauthenticatedRequestError)
    end

    # A good token whose holder has no warehouse account does get JSON, but 403 rather than 401:
    # signing in again can't produce an account.
    it 'returns a JSON 403 for a good token whose holder has no warehouse account' do
      # The one stubbed resolution in the file: Idp::UserProvisioner returns nil only when neither
      # the connector link nor the email matches, and sign_in provisions both, so there is no
      # fixture that reaches this branch for real.
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      sign_in(create(:hmis_user))

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('no_warehouse_account')
    end

    # The one auth failure the HMIS arm doesn't answer with JSON: the raise bypasses the
    # idp_handle_unauthenticated override on purpose. A 401 would tell the SPA to show a sign-in
    # screen for a problem no user can sign their way out of.
    it 'raises on a refused forwarded token instead of answering with a JSON 401' do
      refused = instance_double(
        Idp::JwtHelper,
        token?: true,
        valid?: false,
        invalid_reason: :invalid_audience,
        invalid_reason_details: { reason: :invalid_audience, expected_audiences: ['hmis'], actual_audience: 'other' },
      )
      allow(Idp::JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
        kwargs[:access_token] == 'refused-token' ? refused : original_method.call(**kwargs)
      end

      expect { post hmis_session_keepalive_path, headers: headers.merge('HTTP_X_FORWARDED_ACCESS_TOKEN' => 'refused-token') }.
        to raise_error(Idp::ForwardedTokenError, /invalid_audience/)
    end

    it 'returns a JSON 403 for a locally-deactivated token holder (active = false)' do
      inactive = create(:hmis_user, active: false)
      sign_in(inactive)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('account_deactivated')
    end
  end

  # The only route in this file that skips authenticate_hmis_user! (Hmis::UsersController:10), so
  # it is the one place where "no usable user" has to answer 200-with-no-user instead of raising or
  # rendering a JSON error. It's the SPA's bootstrap probe, and oauth2-proxy lists it as a
  # skip_auth_route, so it legitimately arrives with no token at all.
  describe 'GET /hmis/user.json' do
    it 'answers 200 with no user for a tokenless request, rather than raising as guarded routes do' do
      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      # Not merely "no id": the whole payload, so a future change that leaks another user's
      # values onto the signed-out bootstrap fails here.
      expect(JSON.parse(response.body)).to eq('impersonating' => false)
      expect(response.headers['X-app-user-id']).to be_blank
    end

    it 'answers 200 with no user for a deactivated holder, rather than the JSON 403 guarded routes return' do
      sign_in(create(:hmis_user, active: false))

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('impersonating' => false)
    end

    it 'reflects the actual primaryIdp connector value, not just its presence' do
      user = create(:hmis_user)
      sign_in(user)
      # sign_in (JwtAuthenticationHelper) provisions a real Authentication Source and sets
      # last_connector_id on the user; assert against that value rather than a hardcoded
      # literal, so this proves current_user_api_values surfaces the actual DB-backed
      # connector id (and would fail if it started always returning nil).
      expected_connector_id = user.reload.last_connector_id
      expect(expected_connector_id).to be_present

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['primaryIdp']).to eq(expected_connector_id)
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
      # id, not from the token, so one holder exercises the whole round-trip.
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
      expect(parsed).to have_key('primaryIdp')

      delete hmis_impersonations_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(admin_user.id.to_s)
      expect(controller.current_hmis_user).to eq(admin_user)
    end

    # The header comment above claims the next request re-VALIDATES the stored impersonation, but
    # the round-trip above only proves it re-resolves. Without this example, deleting the
    # idp_validate_impersonation_permissions guard (Idp::JwtAuthentication:218) leaves the whole
    # file green, and an admin whose can_impersonate_users? was revoked keeps reading a client's
    # record as that client for the life of the session.
    it 'drops the stored impersonation once the admin loses can_impersonate_users?' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)
      # Guard against a vacuous pass below: the impersonation really is in force first.
      get hmis_user_path, headers: headers
      expect(controller.current_hmis_user).to eq(target_user)

      # Revoke through the role that granted it, using the suite's own helper, rather than stubbing
      # can_impersonate_users? — so the real permission lookup is what changes its mind.
      remove_permissions(admin_user.access_controls.first, :can_impersonate_users)
      expect(Hmis::User.find(admin_user.id).can_impersonate_users?).to eq(false)

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(admin_user)
      expect(controller.impersonating?).to eq(false)
      expect(JSON.parse(response.body)['id']).to eq(admin_user.id.to_s)
    end

    # idp_sync_session_principal! (Idp::JwtAuthentication:161) is what keeps a browser's session from
    # carrying across holders. Nothing else rotates the Rails session under JWT — there is no
    # sign-in event — so the session id is what PaperTrail and Hmis::ActivityLog would keep
    # attributing the new holder's actions to.
    #
    # The session ID is the assertion that makes this example load-bearing. Asserting only that the
    # impersonation didn't carry over does NOT work: the belt-and-braces true_user_id check at
    # Idp::JwtAuthentication:207-210 clears a foreign impersonation on its own, so deleting
    # `reset_session if stamped.present?` still yields the right current_hmis_user. Verified by
    # mutation — that version of this example stayed green.
    it 'rotates the session id when a different token holder arrives on the same cookie' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)
      admin_session_id = session.id.to_s
      expect(admin_session_id).to be_present

      # A second holder, same cookie jar: sign_in swaps the forwarded token but leaves the
      # @session_headers the helper has been carrying.
      other_user = create(:hmis_user, data_source: ds)
      sign_in(other_user)

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(session.id.to_s).not_to eq(admin_session_id)
      expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(other_user.id)
      # And the previous holder's impersonation is gone rather than inherited.
      expect(controller.current_hmis_user).to eq(other_user)
      expect(controller.impersonating?).to eq(false)
    end
  end

  describe 'logout' do
    it 'returns the oauth2-proxy sign-out URL as a JSON redirect_url, not an HTTP redirect' do
      user = create(:hmis_user)
      sign_in(user)

      delete destroy_hmis_user_session_path, headers: headers

      expect(response).to have_http_status(:ok)
      redirect_url = JSON.parse(response.body)['redirect_url']
      expect(redirect_url).to start_with('/oauth2/sign_out?rd=')
      expect(CGI.unescape(redirect_url.split('rd=').last)).to eq(root_path)
    end

    it 'clears session-stored impersonation, mirroring Devise sign_out, even though the JWT/oauth2-proxy credential is untouched' do
      user_group = create(:hmis_user_group)
      admin_user = create(:hmis_user, data_source: ds)
      create_access_control(admin_user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
      target_user = create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }

      sign_in(admin_user)

      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)

      delete destroy_hmis_user_session_path, headers: headers
      expect(response).to have_http_status(:ok)

      # Same JWT holder (admin_user) signs back in on what the server sees as the same
      # session/cookie jar; if logout hadn't cleared the impersonation, it would silently resume.
      get hmis_user_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(admin_user)
      expect(controller.impersonating?).to eq(false)
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
