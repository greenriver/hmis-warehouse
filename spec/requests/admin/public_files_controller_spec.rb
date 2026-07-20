###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::PublicFilesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:collection) { create :collection }

  before(:each) do
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'GET #index' do
    it 'renders a file upload input for the upload form' do
      get admin_public_files_path
      expect(response.body).to include('type="file"')
    end
  end

  describe 'POST #create' do
    let(:pdf_upload) do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.pdf'), 'application/pdf')
    end

    it 'creates a public file with content, content_type, and size set from the uploaded file' do
      expect do
        post admin_public_files_path, params: { grda_warehouse_public_file: { name: 'client/hmis_consent', file: pdf_upload } }
      end.to change(GrdaWarehouse::PublicFile, :count).by(1)

      file = GrdaWarehouse::PublicFile.last
      expect(file.content_type).to eq('application/pdf')
      expect(file.size).to eq(File.size(Rails.root.join('spec/fixtures/files/test.pdf')))
      expect(file.content).to eq(File.binread(Rails.root.join('spec/fixtures/files/test.pdf')))
      expect(file.file).to eq('test.pdf')
      expect(response).to redirect_to(admin_public_files_path)
    end

    it 'rejects a disallowed content type' do
      zip_upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/lsa/fy2019/sample_hmis_export.zip'), 'application/zip')

      expect do
        post admin_public_files_path, params: { grda_warehouse_public_file: { name: 'client/hmis_consent', file: zip_upload } }
      end.not_to change(GrdaWarehouse::PublicFile, :count)

      expect(response).to redirect_to(admin_public_files_path)
      expect(flash[:error]).to include('File type not allowed')
    end

    it 'rejects a file over 4 megabytes' do
      jpeg_bytes = File.binread(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'))
      padded_bytes = jpeg_bytes + ("\x00" * (4.megabytes + 1 - jpeg_bytes.bytesize))
      tempfile = Tempfile.new(['oversized', '.jpg'])
      tempfile.binmode
      tempfile.write(padded_bytes)
      tempfile.rewind
      oversized_upload = Rack::Test::UploadedFile.new(tempfile.path, 'image/jpeg')

      expect do
        post admin_public_files_path, params: { grda_warehouse_public_file: { name: 'client/hmis_consent', file: oversized_upload } }
      end.not_to change(GrdaWarehouse::PublicFile, :count)

      expect(response).to redirect_to(admin_public_files_path)
      expect(flash[:error]).to include('File size should be less than 4 MB')
    ensure
      tempfile&.close
      tempfile&.unlink
    end
  end
end
