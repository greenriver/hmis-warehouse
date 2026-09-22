###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::ExportSourceCheck do
  let(:tmp_dir) { Dir.mktmpdir('export-source-check') }

  after(:each) { FileUtils.remove_entry(tmp_dir) }

  def build_zip(entries, name: 'export.zip')
    path = File.join(tmp_dir, name)
    Zip::File.open(path, create: true) do |zip|
      entries.each do |entry_name, contents|
        zip.get_output_stream(entry_name) { |f| f.write(contents) }
      end
    end
    path
  end

  def export_csv(source_id: 'MA-500', source_name: 'Example Vendor')
    <<~CSV
      ExportID,SourceType,SourceID,SourceName,ExportStartDate,ExportEndDate
      abc123,3,#{source_id},#{source_name},2026-01-01,2026-06-30
    CSV
  end

  it 'returns the SourceID, SourceName and export date range' do
    result = described_class.new(file_path: build_zip({ 'Export.csv' => export_csv })).run

    expect(result).to be_ok
    expect(result.source_id).to eq('MA-500')
    expect(result.source_name).to eq('Example Vendor')
    expect(result.export_start_date).to eq(Date.new(2026, 1, 1))
    expect(result.export_end_date).to eq(Date.new(2026, 6, 30))
  end

  it 'finds Export.csv nested in a directory, case-insensitively' do
    result = described_class.new(file_path: build_zip({ 'some folder/EXPORT.CSV' => export_csv })).run

    expect(result).to be_ok
    expect(result.source_id).to eq('MA-500')
  end

  it 'reports a malformed zip' do
    path = File.join(tmp_dir, 'broken.zip')
    File.binwrite(path, 'this is not a zip file')

    expect(described_class.new(file_path: path).run.error).to eq(:malformed_zip)
  end

  it 'reports a missing Export.csv' do
    result = described_class.new(file_path: build_zip({ 'Client.csv' => "PersonalID\n1\n" })).run

    expect(result.error).to eq(:missing_export_file)
  end

  it 'reports an Export.csv with no data row' do
    header_only = "ExportID,SourceType,SourceID,SourceName,ExportStartDate,ExportEndDate\n"
    result = described_class.new(file_path: build_zip({ 'Export.csv' => header_only })).run

    expect(result.error).to eq(:unparseable_export_file)
  end

  describe '7z archives' do
    def seven_zip(entry_path: 'Export.csv', contents: export_csv, name: 'export.7z')
      staging = File.join(tmp_dir, 'staging')
      target = File.join(staging, entry_path)
      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, contents)
      path = File.join(tmp_dir, name)
      system('7z', 'a', '-bso0', '-bsp0', path, File.join(staging, entry_path.split('/').first),
             out: File::NULL, err: File::NULL)
      FileUtils.rm_rf(staging)
      path
    end

    it 'reads the SourceID out of a .7z' do
      result = described_class.new(file_path: seven_zip).run

      expect(result).to be_ok
      expect(result.source_id).to eq('MA-500')
      expect(result.source_name).to eq('Example Vendor')
    end

    it 'finds Export.csv nested in a directory, case-insensitively' do
      result = described_class.new(file_path: seven_zip(entry_path: 'HMIS_EXPORT/EXPORT.CSV')).run

      expect(result).to be_ok
      expect(result.source_id).to eq('MA-500')
    end

    it 'reports a missing Export.csv' do
      result = described_class.new(file_path: seven_zip(entry_path: 'Client.csv', contents: "PersonalID\n1\n")).run

      expect(result.error).to eq(:missing_export_file)
    end

    it 'reports an unreadable archive as unverifiable' do
      path = File.join(tmp_dir, 'corrupt.7z')
      File.binwrite(path, 'not a 7z archive at all')

      expect(described_class.new(file_path: path).run.error).to eq(:unverifiable)
    end

    # The extension test matches UploadedZip#force_standard_zip exactly, so the
    # check and the import job never disagree about which archives 7z handles.
    it 'does not treat an uppercase .7Z extension as a 7z archive' do
      path = seven_zip(name: 'export.7Z')

      expect(described_class.new(file_path: path).run.error).to eq(:malformed_zip)
    end
  end

  describe '#source_id_matches?' do
    let(:result) { described_class.new(file_path: build_zip({ 'Export.csv' => export_csv })).run }

    it 'matches case-insensitively' do
      expect(result.source_id_matches?('ma-500')).to be true
    end

    it 'does not match a different source id' do
      expect(result.source_id_matches?('MA-501')).to be false
    end

    it 'does not match when either side is blank' do
      blank = described_class.new(file_path: build_zip({ 'Export.csv' => export_csv(source_id: '') }, name: 'blank.zip')).run

      expect(blank.source_id_matches?('MA-500')).to be false
      expect(result.source_id_matches?('')).to be false
    end
  end
end
