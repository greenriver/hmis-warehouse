###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Theme::LogoController, type: :request do
  before(:all) do
    around do |example|
      original_client = ENV['CLIENT']
      ENV['CLIENT'] = 'test'
      example.run
    ensure
      ENV['CLIENT'] = original_client
    end
  end

  describe 'GET /theme/logo/:logo' do
    context 'when unauthenticated' do
      it 'does not redirect to sign in' do
        get theme_logo_path(logo: 'logo')

        expect(response).not_to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:ok)
      end

      it 'serves the same logo regardless of the requested type' do
        get theme_logo_path(logo: 'warehouse')
        warehouse_body = response.body

        get theme_logo_path(logo: 'hmis')

        expect(response.body).to eq(warehouse_body)
      end
    end
  end
end
