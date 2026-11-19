###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AppSettingsController, type: :request do
  let!(:data_source) { create(:hmis_data_source, hmis: 'www.example.com') }

  describe 'GET /hmis/app_settings' do
    it 'reports the deployment auth method so the SPA can choose a login flow' do
      get hmis_app_settings_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['authMethod']).to eq(AuthMethod.jwt? ? 'jwt' : 'devise')
    end

    describe 'logoPath' do
      around do |example|
        original_client = ENV['CLIENT']
        ENV['CLIENT'] = 'test'
        example.run
      ensure
        ENV['CLIENT'] = original_client
      end

      let!(:theme) { create(:theme) }

      before do
        theme.logo.attach(io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"/>'), filename: 'logo.svg', content_type: 'image/svg+xml')
      end

      it 'points at the HMIS logo endpoint when the stored HMIS logo is an allowed image' do
        theme.hmis_logo.attach(io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"/>'), filename: 'hmis.svg', content_type: 'image/svg+xml')

        get hmis_app_settings_path

        expect(JSON.parse(response.body)['logoPath']).to eq(logo_path('hmis_logo'))
      end

      it 'still points at the logo endpoint, which serves the main logo, when the stored HMIS logo is not an allowed type' do
        store_unvalidated_logo(theme, 'hmis_logo', content_type: 'text/javascript')

        get hmis_app_settings_path
        logo_url = JSON.parse(response.body)['logoPath']
        get logo_url

        expect(logo_url).to eq(logo_path('hmis_logo'))
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('image/svg+xml')
      end

      it 'omits logoPath when no served logo exists' do
        theme.logo.purge
        store_unvalidated_logo(theme, 'logo', content_type: 'text/html')

        get hmis_app_settings_path

        expect(JSON.parse(response.body)['logoPath']).to be_nil
      end
    end
  end
end
