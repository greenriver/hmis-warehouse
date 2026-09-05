###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::HmisAutoMigrate::Base do
  describe '#expand_upload' do
    include_context 'a zip file to extract'

    let(:upload) do
      create(:grda_warehouse_upload).tap do |record|
        record.hmis_zip.attach(
          io: File.open(zip_source),
          filename: 'upload.zip',
          content_type: 'application/zip',
        )
        record.save!
      end
    end

    # Base has no initializer of its own -- the subclasses set @upload and
    # @local_path -- and expand_upload reads nothing else.
    let(:importer) do
      described_class.new.tap do |instance|
        instance.instance_variable_set(:@upload, upload)
        instance.instance_variable_set(:@local_path, destination_dir)
      end
    end

    def extract!
      importer.send(:expand_upload)
    end

    include_examples 'extracts entries into the destination directory'

    it 'removes the zip it reconstituted from the upload' do
      extract!

      expect(File.exist?(File.join(destination_dir, 'upload.zip'))).to be false
    end
  end
end
