###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::CurrentUser, type: :controller do
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
    allow(controller).to receive(:jwt_helper_for_request).and_return(jwt_helper)
  end

  let(:jwt_helper) do
    double(
      'Idp::JwtHelper',
      token?: true,
      valid?: true,
      connector_id: 'keycloak',
      expiration_time: 9_999_999_999,
    )
  end

  describe '#current_user' do
    it 'returns the resolved user' do
      user = double('User', id: 42)
      allow(User).to receive(:find_or_create_from_jwt).with(jwt_helper).and_return(user)

      get :index

      expect(response.body).to eq('42')
    end

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

  describe '#authenticated_user_from_jwt' do
    it 'resolves via find_or_create_from_jwt (the learning call), not find_from_jwt' do
      user = double('User', id: 7)
      expect(User).to receive(:find_or_create_from_jwt).with(jwt_helper).and_return(user)
      expect(User).not_to receive(:find_from_jwt)

      get :index

      expect(response.body).to eq('7')
    end

    it 'sets the last_connector_id cookie from the token' do
      user = double('User', id: 7)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :index

      expect(response.cookies['last_connector_id']).to eq('keycloak')
    end
  end

  describe '#authenticate_user!' do
    it 'sets current_user when a user is present' do
      user = double('User', id: 5)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :auth

      expect(response.body).to eq('authenticated:5')
    end

    it 'calls handle_unauthenticated when no user resolves' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      allow(controller).to receive(:handle_unauthenticated)

      get :auth

      expect(controller).to have_received(:handle_unauthenticated)
    end

    it 'does not consult active_for_authentication? (access is the IdP decision)' do
      # A double with no active_for_authentication? would raise if the method tried to call it.
      inactive_user = double('User', id: 9)
      allow(User).to receive(:find_or_create_from_jwt).and_return(inactive_user)

      expect { get :auth }.not_to raise_error
      expect(response.body).to eq('authenticated:9')
    end

    # Exercises the real handle_unauthenticated wiring (capture + redirect), including the
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

    it 'clears impersonation and returns the true user when permissions fail' do
      allow(impersonated_user).to receive(:impersonateable_by?).with(true_user).and_return(false)

      get :index

      expect(response.body).to eq('10')
    end

    it 'ignores impersonation when the JWT principal is not the stored true_user' do
      # Leftover session: the token now logs in a different user (77) than the one who
      # started impersonating (10), so the impersonation should be ignored.
      other_principal = double('User', id: 77)
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
