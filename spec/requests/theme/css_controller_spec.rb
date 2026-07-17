###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Theme::CssController, type: :request do
  # active_theme keys off ENV['CLIENT']; set it per-example and restore the
  # original afterward so we don't leak process state into other spec files.
  around do |example|
    original_client = ENV['CLIENT']
    ENV['CLIENT'] = 'test'
    example.run
  ensure
    ENV['CLIENT'] = original_client
  end

  describe 'GET /theme/css' do
    context 'when unauthenticated' do
      it 'does not redirect to sign in' do
        get theme_css_path

        expect(response).not_to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:ok)
      end

      it 'responds with text/css' do
        get theme_css_path

        expect(response.media_type).to eq('text/css')
      end
    end
  end
end
