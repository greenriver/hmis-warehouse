###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty::Loader::Loader, type: :model do
  describe '#expand' do
    include_context 'a zip file to extract'

    let(:data_source) { create(:grda_warehouse_data_source) }

    # #expand reads @local_path, which the class itself never assigns, so set
    # it here the way a caller would have to.
    let(:loader) do
      csv_dir = File.join(scratch_dir, 'csvs')
      FileUtils.mkdir_p(csv_dir)
      described_class.new(data_source_id: data_source.id, file_path: csv_dir, remove_files: false).tap do |instance|
        instance.instance_variable_set(:@local_path, destination_dir)
      end
    end

    let(:destination_dir) { File.join(scratch_dir, 'expanded').tap { |dir| FileUtils.mkdir_p(dir) } }

    def extract!
      loader.send(:expand, file_path: zip_source)
    end

    include_examples 'extracts entries into the destination directory'

    it 'removes the source zip' do
      extract!

      expect(File.exist?(zip_source)).to be false
    end
  end
end
