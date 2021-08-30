require 'rails_helper'
if ENV['OKTA_DOMAIN'].present?
  # Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
  RSpec.describe Users::OmniauthCallbacksController, type: :request do
    describe 'GET /users/auth/:provider protects against CVE-2015-9284' do
      it do
        get '/users/auth/okta'
        expect(response).to redirect_to(root_path)
      end
    end

    # Fixed with update to 2.0.4
    # describe 'POST /auth/:provider without CSRF token protects against CVE-2015-9284' do
    #   before do
    #     @allow_forgery_protection = ActionController::Base.allow_forgery_protection
    #     ActionController::Base.allow_forgery_protection = true
    #   end

    #   it do
    #     expect do
    #       post '/users/auth/okta'
    #     end.to raise_error(ActionController::InvalidAuthenticityToken)
    #   end

    #   after do
    #     ActionController::Base.allow_forgery_protection = @allow_forgery_protection
    #   end
    # end
  end
end
