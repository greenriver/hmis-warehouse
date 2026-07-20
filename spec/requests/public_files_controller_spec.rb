###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicFilesController, type: :request do
  let!(:user) { create :user }

  before(:each) { sign_in user }

  describe 'GET #show' do
    it 'downloads using the stored filename when present' do
      public_file = GrdaWarehouse::PublicFile.create!(
        name: 'client/hmis_consent',
        file: 'consent_form.pdf',
        content: 'x' * 200,
        content_type: 'application/pdf',
      )

      get public_file_path(id: public_file.id)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('consent_form.pdf')
    end

    it 'falls back to the name when no filename is stored' do
      public_file = GrdaWarehouse::PublicFile.create!(
        name: 'client/hmis_consent',
        content: 'x' * 200,
        content_type: 'application/pdf',
      )

      get public_file_path(id: public_file.id)

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('client%2Fhmis_consent')
    end
  end
end
