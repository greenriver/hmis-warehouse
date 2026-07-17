###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Theme::LogoController, type: :request do
  around do |example|
    original_client = ENV['CLIENT']
    ENV['CLIENT'] = 'test'
    example.run
  ensure
    ENV['CLIENT'] = original_client
  end

  describe 'GET /theme/logo/:logo' do
    context 'when unauthenticated' do
      before do
        # Attach a real blob directly rather than relying on GrdaWarehouse::Theme's
        # on-disk default-logo fallback, which reads from app/assets/images/theme/logo/ --
        # a client-specific, .gitignore'd directory that isn't present in CI checkouts.
        GrdaWarehouse::Theme.active_theme.logo.attach(io: StringIO.new('fake logo content'), filename: 'logo.svg', content_type: 'image/svg+xml')
      end

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
