###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::PublicFilesController, type: :request do
  let(:role) { create(:role, can_manage_config: true) }
  let(:user) do
    u = create(:user)
    u.legacy_roles << role
    u
  end

  before { sign_in user }

  describe 'GET index' do
    # Regression: `f.input :file` had no `as: :file`. `file` is a plain varchar
    # column (CarrierWave used to make simple_form auto-detect it as a file
    # input); once CarrierWave was removed (#6883) it rendered as a text field,
    # so browser submissions carried an empty string instead of an upload.
    it 'renders the upload form with a real file input' do
      get admin_public_files_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="file"')
    end
  end

  describe 'POST create' do
    let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg') }

    it 'attaches the uploaded file to ActiveStorage' do
      expect do
        post admin_public_files_path, params: { grda_warehouse_public_file: { name: 'client/hmis_consent', file: upload } }
      end.to change(GrdaWarehouse::PublicFile, :count).by(1)

      created = GrdaWarehouse::PublicFile.order(:id).last
      expect(created.public_file).to be_attached
    end
  end
end
