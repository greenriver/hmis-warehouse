###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Export::Exporter do
  # The real includers (HmisCsvTwentyTwentySix::Exporter::Base and friends)
  # need a data source, a user and a full Kiba run to instantiate; #zip_archive
  # only reads @file_path and #zip_path.
  let(:including_class) do
    Class.new do
      include ::Export::Exporter

      def initialize(file_path:, zip_path:)
        @file_path = file_path
        @zip_path = zip_path
      end
    end
  end

  describe '#zip_archive' do
    include_context 'a directory of files to archive'

    let(:zip_directory) { File.join(archive_root, 'csvs') }
    let(:archive_path) { File.join(archive_root, 'export.zip') }
    let(:exporter) { including_class.new(file_path: zip_directory, zip_path: archive_path) }

    def archive!
      exporter.zip_archive
    end

    include_examples 'creates a zip archive of a directory of files'
  end
end
