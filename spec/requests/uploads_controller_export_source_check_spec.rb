###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadsController, type: :request do
  let(:data_source) { create(:source_data_source, short_name: 'HV', source_id: 'MA-500') }
  let(:role) { create(:role, name: 'uploader', can_upload_hud_zips: true, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let(:user) { create(:acl_user) }
  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir('uploads-export-source-check')
  end

  let(:enqueued_job) { instance_double(Importing::HudZip::HmisAutoMigrateJob, provider_job_id: 42) }

  # Real access control rather than a stubbed scope, so removing the data source
  # scoping from set_data_source fails these instead of going unnoticed.
  before do
    collection.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  after(:each) { FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir) }

  def export_csv(source_id: 'MA-500')
    <<~CSV
      ExportID,SourceType,SourceID,SourceName,ExportStartDate,ExportEndDate
      EX-1,3,#{source_id},Example Vendor,2026-01-01,2026-06-30
    CSV
  end

  def zip_upload(contents: export_csv, name: 'export.zip', entry: 'Export.csv')
    path = File.join(tmp_dir, name)
    Zip::File.open(path, create: true) do |zip|
      zip.get_output_stream(entry) { |f| f.write(contents) }
    end
    Rack::Test::UploadedFile.new(path, 'application/zip')
  end

  def post_create(file:, short_name: 'HV')
    post data_source_uploads_path(data_source), params: {
      grda_warehouse_upload: { hmis_zip: file, short_name_confirmation: short_name, dry_run: '0' },
    }
  end

  describe 'authorization' do
    it 'refuses a user without can_upload_hud_zips' do
      unprivileged = create(:acl_user)
      setup_access_control(unprivileged, create(:role, name: 'viewer', can_view_projects: true), collection)
      sign_in unprivileged

      expect { post_create(file: zip_upload) }.not_to change(GrdaWarehouse::Upload, :count)

      expect(response).not_to have_http_status(:ok)
    end

    it 'refuses a user with the permission but no grant on this data source' do
      ungranted = create(:acl_user)
      setup_access_control(ungranted, role, create(:collection))
      sign_in ungranted

      expect { post_create(file: zip_upload) }.not_to change(GrdaWarehouse::Upload, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST create' do
    it 'rejects a mismatched short_name without creating an Upload' do
      expect do
        post_create(file: zip_upload, short_name: 'WRONG')
      end.not_to change(GrdaWarehouse::Upload, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('does not match this data source')
    end

    it 'accepts the short_name case-insensitively and with surrounding whitespace' do
      allow(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).and_return(enqueued_job)

      expect { post_create(file: zip_upload, short_name: ' hv ') }.to change(GrdaWarehouse::Upload, :count).by(1)

      expect(response).to redirect_to(action: :index)
    end

    it 'enqueues when the SourceID matches' do
      expect(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).
        with(hash_including(source_id_override: false)).and_return(enqueued_job)

      expect { post_create(file: zip_upload) }.to change(GrdaWarehouse::Upload, :count).by(1)

      expect(response).to redirect_to(action: :index)
      expect(GrdaWarehouse::Upload.order(:id).last.delayed_job_id).to eq(42)
    end

    it 'holds a mismatched SourceID for confirmation' do
      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)

      post_create(file: zip_upload(contents: export_csv(source_id: 'MA-999')))

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Observed SourceID.*?<td>\s*MA-999\s*<\/td>/m)
      expect(response.body).to match(/Expected SourceID.*?<td>\s*MA-500\s*<\/td>/m)
      expect(GrdaWarehouse::Upload.order(:id).last.delayed_job_id).to be_nil
    end

    it 'holds a blank SourceID for confirmation' do
      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)

      post_create(file: zip_upload(contents: export_csv(source_id: '')))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Confirm and Import')
    end

    it 'holds an unreadable archive for confirmation' do
      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)
      path = File.join(tmp_dir, 'export.7z')
      File.binwrite(path, 'not readable here')

      post_create(file: Rack::Test::UploadedFile.new(path, 'application/x-7z-compressed'))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('SourceID could not be read from this file')
    end

    it 'destroys the Upload when the zip is malformed' do
      path = File.join(tmp_dir, 'broken.zip')
      File.binwrite(path, 'this is not a zip file')

      post_create(file: Rack::Test::UploadedFile.new(path, 'application/zip'))

      expect(response.body).to include('could not be read as a zip archive')
      expect(GrdaWarehouse::Upload.count).to eq(0)
    end

    it 'refuses when imports are disabled for the data source' do
      data_source.update!(disable_imports: true)

      expect do
        post_create(file: zip_upload)
      end.not_to change(GrdaWarehouse::Upload, :count)

      expect(response).to redirect_to(data_source_uploads_path(data_source))
    end

    # dry_run is not a column on uploads, so the hidden field on the confirmation
    # form is the only thing carrying it across the two phases.
    it 'carries dry_run into the confirmation form' do
      post data_source_uploads_path(data_source), params: {
        grda_warehouse_upload: {
          hmis_zip: zip_upload(contents: export_csv(source_id: 'MA-999')),
          short_name_confirmation: 'HV',
          dry_run: '1',
        },
      }

      expect(response.body).to match(/<input[^>]*name="grda_warehouse_upload\[dry_run\]"[^>]*value="1"/)
    end

    it 'destroys the Upload when Export.csv is missing' do
      post_create(file: zip_upload(contents: "PersonalID\n1\n", entry: 'Client.csv'))

      expect(response.body).to include('does not contain an Export.csv')
      expect(GrdaWarehouse::Upload.count).to eq(0)
    end
  end

  describe 'POST confirm' do
    let!(:upload) do
      post_create(file: zip_upload(contents: export_csv(source_id: 'MA-999')))
      GrdaWarehouse::Upload.order(:id).last
    end

    def post_confirm(acknowledge: '1')
      post confirm_data_source_upload_path(data_source, upload), params: {
        acknowledge: acknowledge,
        grda_warehouse_upload: { dry_run: '1' },
      }
    end

    it 'writes the audit record and enqueues with the override' do
      expect(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).
        with(hash_including(source_id_override: true, dry_run: true)).and_return(enqueued_job)

      post_confirm

      expect(response).to redirect_to(action: :index)
      upload.reload
      expect(upload.export_source_check['typed_short_name']).to eq('HV')
      expect(upload.export_source_check['data_source_source_id']).to eq('MA-500')
      expect(upload.export_source_check['file_source_id']).to eq('MA-999')
      expect(upload.export_source_check['file_source_name']).to eq('Example Vendor')
      expect(upload.export_source_check['check_error']).to be_nil
      expect(upload.export_source_check['acknowledged_by_user_id']).to eq(user.id)
      expect(upload.source_id_overridden?).to be true
      expect(upload.delayed_job_id).to eq(42)
    end

    # An unverifiable archive records no observed SourceID, but the Loader expands
    # the file and can compare it itself, so confirming must leave that check on.
    it 'does not override the check when confirming an unverifiable archive' do
      path = File.join(tmp_dir, 'unverifiable.7z')
      File.binwrite(path, 'not readable here')
      post_create(file: Rack::Test::UploadedFile.new(path, 'application/x-7z-compressed'))
      seven_zip = GrdaWarehouse::Upload.order(:id).last

      expect(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).
        with(hash_including(source_id_override: false)).and_return(enqueued_job)

      post confirm_data_source_upload_path(data_source, seven_zip), params: { acknowledge: '1' }

      expect(seven_zip.reload.export_source_check['file_source_id']).to be_nil
      expect(seven_zip.export_source_check['check_error']).to eq('unverifiable')
      expect(seven_zip.source_id_overridden?).to be false
    end

    # Re-posting would queue a second import of the same file; the job's advisory
    # lock serializes the two but runs both.
    it 'refuses a second confirmation of the same upload' do
      expect(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).
        once.and_return(enqueued_job)

      post_confirm
      post_confirm

      expect(response).to redirect_to(action: :index)
      expect(flash[:alert]).to include('no longer waiting for confirmation')
    end

    it 'refuses to confirm an upload that was queued without a confirmation' do
      allow(Importing::HudZip::HmisAutoMigrateJob).to receive(:perform_later).and_return(enqueued_job)
      post_create(file: zip_upload)
      matched = GrdaWarehouse::Upload.order(:id).last
      expect(matched.delayed_job_id).to eq(42)

      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)

      post confirm_data_source_upload_path(data_source, matched), params: { acknowledge: '1' }

      expect(response).to redirect_to(action: :index)
      expect(matched.reload.export_source_check).to be_nil
    end

    it 'refuses without the acknowledgment' do
      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)

      post_confirm(acknowledge: '0')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('must acknowledge')
      expect(upload.reload.delayed_job_id).to be_nil
    end

    it 'does not reach an upload belonging to another data source' do
      other = create(:source_data_source, short_name: 'OT')
      upload.update_column(:data_source_id, other.id)
      expect(Importing::HudZip::HmisAutoMigrateJob).not_to receive(:perform_later)

      post confirm_data_source_upload_path(data_source, upload), params: { acknowledge: '1' }

      expect(response).to have_http_status(:not_found)
      expect(upload.reload.export_source_check).to be_nil
    end
  end

  # set_upload is shared, so scoping it for #confirm tightened these too
  describe 'upload lookup scoping' do
    let!(:other_upload) do
      other = create(:source_data_source, short_name: 'OT')
      create(:grda_warehouse_upload, data_source: other)
    end

    it 'does not show an upload belonging to another data source' do
      get data_source_upload_path(data_source, other_upload)

      expect(response).to have_http_status(:not_found)
    end
  end
end
