###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::UploadValidityCheck do
  let(:tmp_dir) { Dir.mktmpdir('upload-validity-check') }

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

    # Reading past MAX_EXPORT_FILE_BYTES leaves 7z with more to write. This
    # example hangs rather than fails if the read stops being bounded or the
    # child stops being closed out.
    it 'gives up on an Export.csv larger than the read cap instead of blocking' do
      oversized = export_csv + ("x,1,MA-500,Vendor,2026-01-01,2026-06-30\n" * 40_000)
      path = seven_zip(contents: oversized, name: 'oversized.7z')

      result = Timeout.timeout(60) { described_class.new(file_path: path).run }

      expect(result.error).to eq(:unverifiable)
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

  describe described_class::Result do
    def result_with(error)
      described_class.new(error: error)
    end

    # The list used to live in UploadsController, which meant the controller knew
    # the check's error vocabulary.
    it 'hard rejects only what the Loader would fail on anyway' do
      expect(result_with(:malformed_zip)).to be_hard_reject
      expect(result_with(:missing_export_file)).to be_hard_reject
      expect(result_with(:unparseable_export_file)).to be_hard_reject
      expect(result_with(:unverifiable)).not_to be_hard_reject
      expect(result_with(nil)).not_to be_hard_reject
    end

    it 'has a message for every hard reject and none otherwise' do
      expect(result_with(:malformed_zip).error_message).to include('could not be read as a zip archive')
      expect(result_with(:missing_export_file).error_message).to include('does not contain an Export.csv')
      expect(result_with(:unparseable_export_file).error_message).to include('could not be read')
      expect(result_with(:unverifiable).error_message).to be_nil
      expect(result_with(nil).error_message).to be_nil
    end

    # Every hard reject needs something to show the user, and nothing else may
    # claim one, or #create would re-render the form with a blank alert.
    it 'covers exactly the hard rejects' do
      expect(HmisCsvImporter::UploadValidityCheck::ERROR_MESSAGES.keys).
        to match_array(HmisCsvImporter::UploadValidityCheck::HARD_REJECT_ERRORS)
    end

    # #confirm acts on the stored row instead of opening the archive a second time.
    it 'round trips through the audit row' do
      original = described_class.new(
        source_id: 'MA-500',
        source_name: 'Example Vendor',
        export_start_date: Date.new(2026, 1, 1),
        export_end_date: Date.new(2026, 6, 30),
      )

      restored = described_class.from_audit_h(original.to_audit_h)

      expect(restored.source_id).to eq('MA-500')
      expect(restored.source_name).to eq('Example Vendor')
      expect(restored.export_start_date).to eq(Date.new(2026, 1, 1))
      expect(restored.export_end_date).to eq(Date.new(2026, 6, 30))
      expect(restored).to be_ok
    end

    it 'restores the error as a symbol' do
      restored = described_class.from_audit_h(described_class.new(error: :unverifiable).to_audit_h)

      expect(restored.error).to eq(:unverifiable)
      expect(restored).not_to be_ok
    end

    it 'tolerates a missing audit row' do
      expect(described_class.from_audit_h(nil).error).to be_nil
    end
  end

  describe '.for_uploaded_file' do
    def uploaded(path, name)
      ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path), filename: name)
    end

    it 'reads Export.csv off the request tempfile' do
      file = uploaded(build_zip({ 'Export.csv' => export_csv }), 'export.zip')

      expect(described_class.for_uploaded_file(file).source_id).to eq('MA-500')
    end

    # A request tempfile is not named after the upload, and the extension is what
    # decides whether the archive goes to rubyzip or to 7z.
    it 'picks the reader from the uploaded name, not the tempfile path' do
      scratch = File.join(tmp_dir, 'RackMultipart-no-extension')
      FileUtils.cp(seven_zip, scratch)

      expect(described_class.for_uploaded_file(uploaded(scratch, 'export.7z')).source_id).to eq('MA-500')
      expect(described_class.new(file_path: scratch).run.error).to eq(:malformed_zip)
    end
  end
end
