###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate::Local do
  describe '#pre_process' do
    include_context 'a directory of files to archive'

    let(:data_source) { create(:source_data_source) }
    let(:importer) do
      described_class.new(data_source_id: data_source.id, file_path: zip_directory).tap do |instance|
        # #upload would attach the archive to a new upload record.
        allow(instance).to receive(:upload)
      end
    end
    # compress_and_upload names the archive itself.
    let(:archive_path) { Dir.glob(File.join(zip_directory, '*.zip')).first }

    def archive!
      importer.pre_process
    end

    include_examples 'creates a zip archive of a directory of files'
  end
end
