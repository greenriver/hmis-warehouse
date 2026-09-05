###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate::UploadedZip do
  # #pre_process normalizes a .7z upload into a plain zip by shelling out to
  # the 7z binary and re-zipping the results, which exercises both rubyzip 3
  # changes: Zip::File.open(..., create: true) in place of the removed
  # Zip::File::CREATE, and entries added under a nested path.
  describe '#pre_process for a .7z upload' do
    let(:source_dir) { Dir.mktmpdir('uploaded-zip-source') }
    let(:data_source) { create(:source_data_source) }
    let(:seven_zip_path) { File.join(source_dir, 'hmis_upload.7z') }
    let(:upload) do
      create(:grda_warehouse_upload, data_source: data_source).tap do |record|
        record.hmis_zip.attach(
          io: File.open(build_seven_zip),
          filename: File.basename(seven_zip_path),
          content_type: 'application/x-7z-compressed',
        )
        record.save!
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

    def build_seven_zip
      csv_dir = write_files(File.join(source_dir, 'csvs'), hud_csv_entries)
      system("7z a #{seven_zip_path} #{csv_dir}/*.csv", out: File::NULL) ||
        raise('unable to build the .7z fixture')
      seven_zip_path
    end

    after(:each) do
      FileUtils.remove_entry(source_dir) if File.exist?(source_dir)
      hud_csv_entries.each_key { |name| FileUtils.rm_f(File.join(Dir.pwd, name)) }
    end

    it 'replaces the upload with a readable zip' do
      importer.pre_process

      expect(upload.reload.hmis_zip.filename.to_s).to end_with('.zip')
      expect { zip_entry_names(downloaded_zip) }.not_to raise_error
    end

    # force_standard_zip adds each file as File.join(File.basename(tmp_folder),
    # filename), so every entry carries the 7z file's basename as a directory.
    it 'prefixes every entry with the extraction folder basename' do
      importer.pre_process

      expect(zip_entry_names(downloaded_zip)).to match_array(hud_csv_entries.keys.map { |name| File.join('hmis_upload', name) })
    end
  end
end
