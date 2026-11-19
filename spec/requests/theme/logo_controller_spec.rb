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

      it 'serves the logo with a sandboxing content security policy' do
        get theme_logo_path(logo: 'logo')

        expect(response.headers['Content-Security-Policy']).to eq("default-src 'none'; style-src 'unsafe-inline'; img-src data:; sandbox")
      end

      it 'returns 404 for a stored logo with a non-image content type' do
        store_unvalidated_logo(GrdaWarehouse::Theme.active_theme, 'print_logo', body: 'console.log(1)', filename: 'logo.js', content_type: 'text/javascript')

        get theme_logo_path(logo: 'print_logo')

        expect(response).to have_http_status(:not_found)
      end

      context 'with a cached etag from an earlier response' do
        let(:attachment) { store_unvalidated_logo(GrdaWarehouse::Theme.active_theme, 'print_logo', body: 'x', filename: 'logo.png', content_type: 'image/png') }

        def request_logo(headers = {})
          get theme_logo_path(logo: 'print_logo'), headers: headers
        end

        it 'returns 304 when the blob is unchanged' do
          attachment
          request_logo
          etag = response.headers['ETag']

          request_logo('If-None-Match' => etag)

          expect(response).to have_http_status(:not_modified)
        end

        it 'returns 404 rather than 304 when the blob has since become a non-image type' do
          attachment
          request_logo
          etag = response.headers['ETag']
          attachment.blob.update_column(:content_type, 'text/javascript')

          request_logo('If-None-Match' => etag)

          expect(response).to have_http_status(:not_found)
        end
      end

      it 'returns 404 when the main logo is a non-image type' do
        GrdaWarehouse::Theme.active_theme.logo.purge
        store_unvalidated_logo(GrdaWarehouse::Theme.active_theme, 'logo', body: '<html></html>', filename: 'logo.html', content_type: 'text/html')

        get theme_logo_path(logo: 'logo')

        expect(response).to have_http_status(:not_found)
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
