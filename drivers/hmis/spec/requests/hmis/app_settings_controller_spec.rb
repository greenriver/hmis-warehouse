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
  end
end
