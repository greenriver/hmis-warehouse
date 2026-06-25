###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::CurrentUser, type: :controller, if: AuthMethod.jwt? do
  controller(ActionController::Base) do
    include Idp::CurrentUser

    def index
      render plain: current_user&.id.to_s
    end

    def auth
      authenticate_user!
      render plain: "authenticated:#{current_user&.id}" unless performed?
    end

    def who
      render plain: "#{true_user&.id}/#{impersonating?}"
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'auth' => 'anonymous#auth'
      get 'who' => 'anonymous#who'
    end
    allow(controller).to receive(:idp_jwt_helper_for_request).and_return(jwt_helper)
  end

  let(:jwt_helper) do
    instance_double(
      Idp::JwtHelper,
      token?: true,
      valid?: true,
      connector_id: 'keycloak',
      expiration_time: 9_999_999_999,
    )
  end

  describe '#current_user' do
    it 'is nil when the token is invalid' do
      allow(jwt_helper).to receive(:valid?).and_return(false)

      get :index

      expect(response.body).to eq('')
    end

    it 'is nil when no token is present' do
      allow(jwt_helper).to receive(:token?).and_return(false)

      get :index

      expect(response.body).to eq('')
    end
  end

  describe '#idp_authenticated_user_from_jwt' do
    it 'resolves via find_or_create_from_jwt (the learning call), not find_from_jwt' do
      user = double('User', id: 7, active?: true)
      expect(User).to receive(:find_or_create_from_jwt).with(jwt_helper).and_return(user)
      expect(User).not_to receive(:find_from_jwt)

      get :index

      expect(response.body).to eq('7')
    end

    it 'sets the last_connector_id cookie from the token' do
      user = double('User', id: 7, active?: true)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :index

      expect(response.cookies['last_connector_id']).to eq('keycloak')
    end
  end

  describe '#authenticate_user!' do
    it 'sets current_user when a user is present' do
      user = double('User', id: 5, active?: true)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :auth

      expect(response.body).to eq('authenticated:5')
    end

    # Kill-switch: a locally-deactivated user (active? == false) is denied even with a valid token.
    # We must NOT treat them as merely unauthenticated — a redirect to sign-in would loop off the
    # still-valid IdP token — so authenticate_user! routes to the terminal deactivated page instead.
    # This exercises the REAL idp_handle_deactivated (handler not stubbed): the 403 + deactivated
    # template prove it ran, and `not redirect` proves it did NOT fall through to the unauthenticated
    # sign-in redirect. render_template asserts the chosen template without needing render_views, so
    # the view's Translation.translate calls don't run here.
    it 'renders a terminal 403 deactivated page (not a sign-in redirect) for a deactivated user' do
      inactive_user = double('User', id: 9, active?: false)
      allow(User).to receive(:find_or_create_from_jwt).and_return(inactive_user)

      get :auth

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('errors/account_deactivated')
    end

    it 'current_user is nil for a deactivated user' do
      inactive_user = double('User', id: 9, active?: false)
      allow(User).to receive(:find_or_create_from_jwt).and_return(inactive_user)

      get :index

      expect(response.body).to eq('')
    end

    # Exercises the real idp_handle_unauthenticated wiring (capture + redirect), including the
    # real Idp::Oauth2ProxySignInPath builder. No last_connector_id cookie is set here, so
    # only the rd parameter appears.
    it 'captures the original URL and redirects to the oauth2 sign-in path when unauthenticated' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      redirect = instance_double(Idp::PostAuthRedirect, capture: '/some/path')
      allow(Idp::PostAuthRedirect).to receive(:new).and_return(redirect)

      get :auth

      expect(redirect).to have_received(:capture)
      expect(response).to redirect_to('/oauth2/sign_in?rd=%2Fsome%2Fpath')
    end
  end

  describe 'impersonation' do
    let(:true_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(10)
        allow(u).to receive(:can_impersonate_users?).and_return(true)
        allow(u).to receive(:active?).and_return(true)
      end
    end
    let(:impersonated_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(20)
        allow(u).to receive(:impersonateable_by?).with(true_user).and_return(true)
      end
    end

    before do
      allow(User).to receive(:find_or_create_from_jwt).and_return(true_user)
      allow(User).to receive(:find_by).with(id: 10).and_return(true_user)
      allow(User).to receive(:find_by).with(id: 20).and_return(impersonated_user)

      impersonation = double('Idp::ImpersonationManager')
      allow(impersonation).to receive(:get).and_return(
        true_user_id: 10,
        impersonated_user_id: 20,
      )
      allow(impersonation).to receive(:clear)
      allow(Idp::ImpersonationManager).to receive(:new).and_return(impersonation)
    end

    it 'current_user returns the impersonated user when permissions validate' do
      get :index

      expect(response.body).to eq('20')
    end

    it 'true_user returns the true user and impersonating? is true' do
      get :who

      expect(response.body).to eq('10/true')
    end

    it 'clears impersonation and returns the true user when the target is not impersonateable_by? the true_user' do
      allow(impersonated_user).to receive(:impersonateable_by?).with(true_user).and_return(false)

      get :index

      expect(response.body).to eq('10')
    end

    # Guards the can_impersonate_users? gate independently of impersonateable_by?: a true_user who
    # lost (or never had) impersonation privilege must fall back to themselves even though the target
    # would otherwise admit them. Without this, deleting the can_impersonate_users? check in
    # idp_validate_impersonation_permissions still passes the suite (impersonateable_by? alone admits).
    it 'clears impersonation and returns the true user when the true_user cannot impersonate' do
      allow(true_user).to receive(:can_impersonate_users?).and_return(false)

      get :index

      expect(response.body).to eq('10')
    end

    it 'ignores impersonation when the JWT principal is not the stored true_user' do
      # Leftover session: the token now logs in a different user (77) than the one who
      # started impersonating (10), so the impersonation should be ignored.
      other_principal = double('User', id: 77, active?: true)
      allow(User).to receive(:find_or_create_from_jwt).and_return(other_principal)

      get :index

      expect(response.body).to eq('77')
    end
  end

  describe 'dropped methods (regression guard for the subtractions)' do
    it 'does not define forced-logout / provisioning / activity methods' do
      [:check_token_denylist!, :handle_denylisted_token, :ensure_authentication_source, :update_user_activity, :handle_inactive_user].each do |method_name|
        expect(controller.respond_to?(method_name, true)).to be(false), "expected #{method_name} not to be defined"
      end
    end
  end
end
