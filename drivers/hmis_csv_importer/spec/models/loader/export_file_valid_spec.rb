###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::Loader, type: :model do
  describe '#export_file_valid?' do
    let(:data_source) { create(:grda_warehouse_data_source, source_id: 'MA-500') }
    let(:csv_dir) do
      Dir.mktmpdir('export-file-valid').tap do |dir|
        File.write(File.join(dir, 'Export.csv'), "ExportID,CSVVersion\nEX-1,2026\n")
      end
    end

    after(:each) { FileUtils.remove_entry(csv_dir) if File.exist?(csv_dir) }

    def loader_for(source_id_override:, file_source_id: 'MA-999')
      described_class.new(
        data_source_id: data_source.id,
        file_path: csv_dir,
        remove_files: false,
        source_id_override: source_id_override,
      ).tap do |instance|
        instance.instance_variable_set(:@export, { SourceID: file_source_id })
        instance.instance_variable_set(:@loaded_at, Time.current)
        instance.send(:setup_summary, 'Export.csv')
      end
    end

    it 'fails a mismatched SourceID by default' do
      loader = loader_for(source_id_override: false)

      expect(loader.send(:export_file_valid?)).to be false
      expect(loader.loader_log.reload.status).to eq('failed')
    end

    it 'accepts a mismatched SourceID when the override is set' do
      loader = loader_for(source_id_override: true)

      expect(loader.send(:export_file_valid?)).to be true
      expect(loader.loader_log.reload.status).to eq('started')
    end

    it 'logs both values when overriding' do
      loader = loader_for(source_id_override: true)
      expect(loader).to receive(:log).with(/SourceID check overridden.*MA-999.*MA-500/)

      loader.send(:export_file_valid?)
    end

    it 'defaults the override to false' do
      loader = described_class.new(data_source_id: data_source.id, file_path: csv_dir, remove_files: false)

      expect(loader.instance_variable_get(:@source_id_override)).to be false
    end

    it 'still accepts a matching SourceID without the override' do
      loader = loader_for(source_id_override: false, file_source_id: 'ma-500')

      expect(loader.send(:export_file_valid?)).to be true
    end
  end
end
