# frozen_string_literal: true

require 'rails_helper'
if ENV['OKTA_DOMAIN'].present?
  # Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
  RSpec.describe Users::OmniauthCallbacksController, type: :request do
    describe 'GET /users/auth/:provider protects against CVE-2015-9284' do
      it do
        get '/users/auth/okta'
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'okta auth request has no smoke' do
      it do
        post '/users/auth/okta'
        expect(response.location).to match("https://#{ENV['OKTA_DOMAIN']}/oauth2/default/v1/authorize")
        uri = URI.parse(response.location)
        expect(uri.hostname).to eq(ENV['OKTA_DOMAIN'])
        redir = CGI.parse(uri.query)['redirect_uri'][0]
        expect(redir).to eq('http://www.example.com/users/auth/okta/callback')
      end
    end

    describe 'okta callback' do
      let(:user) { create(:user) }
      let(:auth_hash) do
        OmniAuth::AuthHash.new(
          'provider' => 'wh_okta',
          'uid' => '1234',
          'info' => {
            'email' => user.email,
            'first_name' => user.first_name,
            'last_name' => user.last_name,
          },
          'extra' => {
            'raw_info' => {},
          },
          'credentials' => {},
        )
      end

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:wh_okta] = auth_hash
        Rails.application.env_config['omniauth.auth'] = auth_hash
      end

      after do
        OmniAuth.config.test_mode = false
        OmniAuth.config.mock_auth[:wh_okta] = nil
      end

      it 'successfully authenticates and creates login activity record' do
        expect do
          get '/users/auth/okta/callback'
        end.to change(LoginActivity, :count).by(1)

        activity = LoginActivity.where(user: user, scope: 'user', success: true).order(:created_at).sole
        expect(activity).to have_attributes(user: user, success: true, scope: 'user')
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
