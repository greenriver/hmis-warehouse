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
  end
end
