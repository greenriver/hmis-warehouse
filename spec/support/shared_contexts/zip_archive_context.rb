###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A scratch directory of loose files for an archive-creation call site to zip
# up. Override zip_directory when the code under test derives its own, building
# it under archive_root so the cleanup still catches it.
RSpec.shared_context 'a directory of files to archive' do
  let(:archive_root) { Dir.mktmpdir('zip-archive') }
  let(:zip_directory) { archive_root }
  let(:archive_entries) { hud_csv_entries }

  after(:each) do
    FileUtils.remove_entry(archive_root) if File.exist?(archive_root)
  end
end
