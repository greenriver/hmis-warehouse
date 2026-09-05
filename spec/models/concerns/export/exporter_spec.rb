###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Export::Exporter do
  # The concern is mixed into the per-year exporter bases
  # (HmisCsvTwentyTwentySix::Exporter::Base and friends), all of which need a
  # data source, a user and a full Kiba run to instantiate. #zip_archive only
  # reads @file_path and #zip_path, so exercise it through a bare includer.
  let(:including_class) do
    Class.new do
      include ::Export::Exporter

      def initialize(file_path:, zip_path:)
        @file_path = file_path
        @zip_path = zip_path
      end
    end
  end

  let(:tmp_dir) { Dir.mktmpdir('exporter-spec') }
  let(:export_dir) { File.join(tmp_dir, 'csvs') }
  let(:zip_path) { File.join(tmp_dir, 'export.zip') }
  let(:exporter) { including_class.new(file_path: export_dir, zip_path: zip_path) }

  before(:each) do
    write_files(export_dir, hud_csv_entries)
  end

  after(:each) do
    FileUtils.remove_entry(tmp_dir) if File.exist?(tmp_dir)
  end

  describe '#zip_archive' do
    # rubyzip 3 removed Zip::File::CREATE in favor of create: true; without a
    # truthy create the open call raises Errno::ENOENT for a missing file.
    it 'creates the zip file at zip_path' do
      expect(File.exist?(zip_path)).to be false

      exporter.zip_archive

      expect(File.exist?(zip_path)).to be true
    end

    it 'adds each exported file without its directory prefix' do
      exporter.zip_archive

      expect(zip_entry_names(zip_path)).to match_array(hud_csv_entries.keys)
    end

    it 'round trips the file contents' do
      exporter.zip_archive

      contents = Zip::File.open(zip_path) do |zipfile|
        zipfile.to_h { |entry| [entry.name, entry.get_input_stream.read] }
      end

      expect(contents).to eq(hud_csv_entries)
    end
  end
end
