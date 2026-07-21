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
    Delayed::Job.delete_all
  end

  after { Delayed::Job.delete_all }

  describe 'authorization' do
    context 'when the user lacks the upload permission' do
      let(:role) { create(:role, can_upload_dashboard_extras: false) }

      it 'denies access' do
        get new_data_source_non_hmis_upload_path(data_source)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET #new' do
    it 'renders successfully with the default importer' do
      get new_data_source_non_hmis_upload_path(data_source)
      expect(response).to have_http_status(:ok)
    end

    it 'renders successfully with the TPC importer' do
      allow(GrdaWarehouse::Config).to receive(:active_supplemental_enrollment_importer_class).and_return(SupplementalEnrollmentData::Tpc)
      get new_data_source_non_hmis_upload_path(data_source)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    let(:zip_upload) do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/lsa/fy2019/sample_hmis_export.zip'), 'application/zip')
    end

    it 'creates an upload and enqueues the import job' do
      expect do
        post data_source_non_hmis_uploads_path(data_source), params: { grda_warehouse_non_hmis_upload: { file: zip_upload } }
      end.to change(Delayed::Job, :count).by(1)

      upload = GrdaWarehouse::NonHmisUpload.last
      expect(upload.file).to eq('sample_hmis_export.zip')
      expect(upload.content_type).to eq('application/zip')
      expect(upload.content).to eq(File.binread(Rails.root.join('spec/fixtures/files/lsa/fy2019/sample_hmis_export.zip')))
      expect(flash[:notice]).to eq('Upload queued to start.')

      job = Delayed::Job.last
      handler = job.payload_object
      expect(handler).to be_a(Importing::NonHmisJob)
      expect(handler.instance_variable_get(:@upload).id).to eq(upload.id)
      expect(handler.instance_variable_get(:@data_source_id)).to eq(data_source.id)
      expect(upload.reload.delayed_job_id).to eq(job.id)
    end

    it 'rejects a request with no file attached' do
      expect do
        post data_source_non_hmis_uploads_path(data_source), params: { grda_warehouse_non_hmis_upload: { file: nil } }
      end.not_to change(Delayed::Job, :count)

      expect(flash[:alert]).to eq('You must attach a file in the form.')
    end

    it 'rejects a non-.zip upload' do
      pdf_upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.pdf'), 'application/pdf')

      expect do
        post data_source_non_hmis_uploads_path(data_source), params: { grda_warehouse_non_hmis_upload: { file: pdf_upload } }
      end.not_to change(Delayed::Job, :count)

      expect(flash[:alert]).to eq('Upload failed to queue, did you attach a file?')
    end
  end

  describe 'GET #show' do
    it 'downloads using the stored filename' do
      upload = GrdaWarehouse::NonHmisUpload.create!(
        data_source: data_source,
        file: 'export.zip',
        content: 'x' * 200,
        content_type: 'application/zip',
      )

      get data_source_non_hmis_upload_path(data_source_id: data_source.id, id: upload.id)

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('export.zip')
    end
  end
end
