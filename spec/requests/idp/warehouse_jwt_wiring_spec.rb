###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Phase 08 (L2.2) — proves the warehouse request layer wires the JWT auth path correctly when a
# Deployment boots with AUTH_METHOD=jwt, while the Devise path is unchanged. The JWT examples run
# only under the AUTH_METHOD=jwt CI process (they lean on the phase-07 JwtAuthenticationHelper, which
# is included only when AuthMethod.jwt?). This includes the paper-trail whodunnit regression: it
# asserts the JWT arm's current_user/true_user behavior, while the Devise arm keeps its warden.user
# whodunnit verbatim. The route-surface and forced-logout examples are mode-agnostic.
RSpec.describe 'Warehouse JWT wiring', type: :request do
  describe 'authentication via a forwarded JWT', if: AuthMethod.jwt? do
    let(:user) { create :user }

    before do
      # Keep this a focused wiring test: neutralize the post-auth setup gates so a fresh user
      # reaches the action, and resolve current_user deterministically from the mock token.
      allow(user).to receive(:training_required?).and_return(false)
      allow(user).to receive(:pending_compliance_requirements).and_return([])
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)
    end

    it 'authenticates a request carrying X-Forwarded-Access-Token (protected action → 200)' do
      sign_in(user)

      get session_keepalive_path

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include('expiration_time', 'remaining_seconds')
      expect(body['remaining_seconds']).to be > 0
    end

    it 'serves session_keepalive over POST too (the inactivity-modal renew button POSTs)' do
      sign_in(user)

      post session_keepalive_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('expiration_time', 'remaining_seconds')
    end

    it 'redirects an unauthenticated request to the oauth2-proxy sign-in (not a Devise form)' do
      get session_keepalive_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('/oauth2/sign_in')
    end

    describe '#info_for_paper_trail' do
      it 'records user_id and true_user_id from current_user/true_user' do
        user = create :user
        controller = ApplicationController.new
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:true_user).and_return(user)
        allow(controller).to receive(:session).and_return(double(id: double(to_s: 'sess-1')))
        allow(controller).to receive(:request).and_return(double(uuid: 'req-1'))

        info = controller.send(:info_for_paper_trail)

        expect(info[:user_id]).to eq(user.id)
        expect(info[:true_user_id]).to eq(user.id)
        expect(info).not_to have_key(:warden)
      end
    end
  end

  # Describe the connection class directly: a :channel group mixes in both Connection and Channel
  # TestCase behaviors, so `tests` resolves to the Channel variant (sets _channel_class). Naming the
  # class here makes it the described_class, which connection_class falls back to (else nil <= raises).
  describe ApplicationCable::Connection, type: :channel, if: AuthMethod.jwt? do
    let(:user) { create :user }

    it 'accepts a connection with a valid forwarded token' do
      jwt_helper = instance_double(Idp::JwtHelper, token?: true, valid?: true)
      allow(Idp::JwtHelper).to receive(:new).and_return(jwt_helper)
      allow(User).to receive(:find_from_jwt).with(jwt_helper).and_return(user)
      allow(user).to receive(:active?).and_return(true)

      connect env: { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'forwarded-token' }

      expect(connection.current_user).to eq(user)
    end

    it 'rejects a connection with no forwarded token' do
      expect { connect }.to have_rejected_connection
    end
  end

  describe "rack-attack's authenticated? helper", if: AuthMethod.jwt? do
    it 'is true for a valid forwarded token' do
      allow(Idp::JwtHelper).to receive(:authenticated?).with('good-token').and_return(true)
      request = Rack::Attack::Request.new('QUERY_STRING' => '', 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'good-token')

      expect(request.authenticated?).to be(true)
    end

    it 'is false with no forwarded token' do
      request = Rack::Attack::Request.new('QUERY_STRING' => '', 'HTTP_X_FORWARDED_ACCESS_TOKEN' => nil)

      expect(request.authenticated?).to be(false)
    end
  end

  describe 'route surface' do
    it 'mounts /oauth/user-data only under Devise (A4)' do
      if AuthMethod.jwt?
        expect { Rails.application.routes.recognize_path('/oauth/user-data') }.
          to raise_error(ActionController::RoutingError)
      else
        expect(Rails.application.routes.recognize_path('/oauth/user-data')).
          to include(controller: 'oauth', action: 'user')
      end
    end

    it 'keeps the shared session route names in both modes' do
      expect(Rails.application.routes.url_helpers).to respond_to(:session_keepalive_path)
      expect(Rails.application.routes.url_helpers).to respond_to(:destroy_user_session_path)
    end
  end

  # Forced-logout machinery was dropped (2026-06-08) and built nowhere — guard against it creeping back.
  describe 'forced-logout is absent' do
    it 'registers no check_token_denylist! before-action' do
      filters = ApplicationController._process_action_callbacks.map(&:filter)
      expect(filters).not_to include(:check_token_denylist!)
    end

    it 'does not route token_denylisted' do
      expect { Rails.application.routes.recognize_path('/token_denylisted') }.
        to raise_error(ActionController::RoutingError)
    end
  end
end
