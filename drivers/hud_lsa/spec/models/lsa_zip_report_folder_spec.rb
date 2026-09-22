###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Stubbing unzip_path keeps the archive out of the shared tmp/lsa directory.
[HudLsa::Generators::Fy2026::Lsa, HudLsa::Generators::Fy2027::Lsa].each do |lsa_class|
  RSpec.describe lsa_class, type: :model do
    describe '#zip_report_folder' do
      include_context 'a directory of files to archive'

      let(:report) do
        lsa_class.new.tap do |instance|
          allow(instance).to receive(:id).and_return(1)
          allow(instance).to receive(:unzip_path).and_return(zip_directory)
        end
      end
      let(:archive_path) { File.join(zip_directory, '1.zip') }

      def archive!
        report.zip_report_folder
      end

      include_examples 'creates a zip archive of a directory of files'
    end
  end
end
