###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicLogosController, type: :request do
  around do |example|
    original_client = ENV['CLIENT']
    ENV['CLIENT'] = 'test'
    example.run
  ensure
    ENV['CLIENT'] = original_client
  end

  describe 'GET /logo/:logo' do
    before do
      GrdaWarehouse::Theme.active_theme.logo.attach(io: StringIO.new('fake logo content'), filename: 'logo.svg', content_type: 'image/svg+xml')
    end

    it 'serves an allowed image logo without authentication' do
      get logo_path(logo: 'logo')

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('fake logo content')
      expect(response.media_type).to eq('image/svg+xml')
    end

    it 'serves the logo with a sandboxing content security policy' do
      get logo_path(logo: 'logo')

      expect(response.headers['Content-Security-Policy']).to eq("default-src 'none'; style-src 'unsafe-inline'; img-src data:; sandbox")
    end

    it 'returns 404 for a stored logo with a non-image content type' do
      store_unvalidated_logo(GrdaWarehouse::Theme.active_theme, 'print_logo', body: 'console.log(1)', filename: 'logo.js', content_type: 'text/javascript')

      get logo_path(logo: 'print_logo')

      expect(response).to have_http_status(:not_found)
    end

    context 'with a cached etag from an earlier response' do
      let(:attachment) { store_unvalidated_logo(GrdaWarehouse::Theme.active_theme, 'print_logo', body: 'x', filename: 'logo.png', content_type: 'image/png') }

      def request_logo(headers = {})
        get logo_path(logo: 'print_logo'), headers: headers
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

      get logo_path(logo: 'logo')

      expect(response).to have_http_status(:not_found)
    end
  end
end
