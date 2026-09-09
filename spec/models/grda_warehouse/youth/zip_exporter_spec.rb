###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Youth::ZipExporter do
  describe '#create_zip_file' do
    include_context 'a directory of files to archive'

    # The intake collections and the controller belong to #export!, not to
    # archiving.
    let(:exporter) do
      described_class.new(
        intakes: [],
        referrals: [],
        dfas: [],
        case_managements: [],
        follow_ups: [],
        housing_resolution_plans: [],
        controller: nil,
        file_path: archive_root,
      )
    end
    # The exporter appends the pid to the file_path it was given.
    let(:zip_directory) { File.join(archive_root, Process.pid.to_s) }
    let(:archive_path) { File.join(zip_directory, 'yya_export.zip') }

    def archive!
      exporter.create_zip_file
    end

    include_examples 'creates a zip archive of a directory of files'
  end
end
