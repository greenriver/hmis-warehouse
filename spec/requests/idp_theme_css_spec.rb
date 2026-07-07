###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdpThemeCssController, type: :request do
  before(:all) do
    ENV['CLIENT'] = 'test'
  end

  describe 'GET /assets/idp/theme.css' do
    context 'when unauthenticated' do
      it 'does not redirect to sign in' do
        get idp_theme_css_path

        expect(response).not_to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:ok)
      end

      it 'responds with text/css' do
        get idp_theme_css_path

        expect(response.media_type).to eq('text/css')
      end
    end
  end
end
