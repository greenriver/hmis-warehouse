###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ZipExporter do
  describe '#create_zip_file' do
    include_context 'a directory of files to archive'

    # Only the report's name is used, to name the archive.
    let(:report) { double(report_name: 'spec-report') }
    let(:exporter) { described_class.new(report, file_path: archive_root) }
    # The exporter appends the pid to the file_path it was given.
    let(:zip_directory) { File.join(archive_root, Process.pid.to_s) }
    let(:archive_path) { File.join(zip_directory, 'spec-report.zip') }

    def archive!
      exporter.create_zip_file
    end

    include_examples 'creates a zip archive of a directory of files'
  end
end
