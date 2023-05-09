require 'rails_helper'
if ENV['OKTA_DOMAIN'].present?
  # Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
  RSpec.describe Users::OmniauthCallbacksController, type: :request do
    describe 'GET /users/auth/:provider protects against CVE-2015-9284' do
      it do
        expect do
          get '/users/auth/okta'
        end.to raise_error(ActionController::RoutingError)
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
  end
end
