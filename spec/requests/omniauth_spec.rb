require 'rails_helper'

# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
RSpec.describe Users::OmniauthCallbacksController, type: :request do
  describe 'GET /users/auth/:provider' do
    it do
      get '/users/auth/okta'
      expect(response).not_to have_http_status(:redirect)
    end
  end

  describe 'POST /auth/:provider without CSRF token' do
    before do
      @allow_forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
    end

    it do
      expect do
        post '/users/auth/okta'
      end.to raise_error(ActionController::InvalidAuthenticityToken)
    end

    after do
      ActionController::Base.allow_forgery_protection = @allow_forgery_protection
    end
  end
end
