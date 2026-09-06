###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'English'
require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate::UploadedZip do
  # #pre_process normalizes a .7z upload into a plain zip, exercising
  # Zip::File.open(..., create: true) and entries added under a nested path.
  describe '#pre_process for a .7z upload' do
    let(:source_dir) { Dir.mktmpdir('uploaded-zip-source') }
    let(:data_source) { create(:source_data_source) }
    let(:seven_zip_path) { File.join(source_dir, 'hmis_upload.7z') }
    let(:upload) do
      create(:grda_warehouse_upload, data_source: data_source).tap do |record|
        attach_hmis_zip(
          record,
          build_seven_zip,
          filename: File.basename(seven_zip_path),
          content_type: 'application/x-7z-compressed',
        )
      end
    end
    let(:importer) do
      described_class.new(upload_id: upload.id, data_source_id: data_source.id)
    end

    # Round trip the attachment through disk; Zip::File wants a real path.
    def downloaded_zip
      path = File.join(source_dir, 'downloaded.zip')
      File.binwrite(path, upload.reload.hmis_zip.download)
      path
    end

    # Needs the 7z binary (p7zip-full in the app image, 7zip in CI).
    def build_seven_zip
      csv_dir = write_files(File.join(source_dir, 'csvs'), hud_csv_entries)
      system("7z a #{seven_zip_path} #{csv_dir}/*.csv", out: File::NULL) ||
        raise("unable to build the .7z fixture; 7z exited #{$CHILD_STATUS.inspect}")
      seven_zip_path
    end

    after(:each) do
      FileUtils.remove_entry(source_dir) if File.exist?(source_dir)
      remove_leaked_files(hud_csv_entries.keys)
    end

    it 'replaces the upload with a readable zip' do
      importer.pre_process

      expect(upload.reload.hmis_zip.filename.to_s).to end_with('.zip')
      expect { zip_entry_names(downloaded_zip) }.not_to raise_error
    end

    # force_standard_zip adds each file under File.basename(tmp_folder), which
    # is the 7z file's basename.
    it 'prefixes every entry with the extraction folder basename' do
      importer.pre_process

      expect(zip_entry_names(downloaded_zip)).to match_array(hud_csv_entries.keys.map { |name| File.join('hmis_upload', name) })
    end
  end
end
