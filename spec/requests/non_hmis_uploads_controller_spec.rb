###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NonHmisUploadsController, type: :request do
  let(:data_source) { create(:source_data_source) }
  let(:role) { create(:role, can_upload_dashboard_extras: true) }
  let(:user) do
    u = create(:user)
    u.legacy_roles << role
    u
  end

  before do
    allow(GrdaWarehouse::DataSource).to receive(:viewable_by).with(user).and_return(
      GrdaWarehouse::DataSource.where(id: data_source.id),
    )
    sign_in user
  end

  describe 'GET new' do
    # Regression: the form partial called `f.hidden_field :file_cache`, a method
    # CarrierWave used to generate on mounted uploaders. Removing CarrierWave
    # (#6883) left the call in place, so the page 500'd with a NoMethodError.
    it 'renders the upload form with a real file input' do
      get new_data_source_non_hmis_upload_path(data_source)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="file"')
    end
  end

  describe 'POST create' do
    let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.pdf'), 'application/pdf') }

    it 'attaches the uploaded file to ActiveStorage' do
      expect do
        post data_source_non_hmis_uploads_path(data_source), params: { grda_warehouse_non_hmis_upload: { file: upload } }
      end.to change(GrdaWarehouse::NonHmisUpload, :count).by(1)

      expect(response).to redirect_to(data_source_non_hmis_uploads_path(data_source))
      created = GrdaWarehouse::NonHmisUpload.order(:id).last
      expect(created.upload_file).to be_attached
    end
  end
end
