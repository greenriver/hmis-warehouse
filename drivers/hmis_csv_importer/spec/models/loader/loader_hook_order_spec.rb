###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::Loader, type: :model do
  def write_export_csv(dir)
    File.write(File.join(dir, 'Export.csv'), "ExportID,CSVVersion\nEX-1,2026\n")
  end

  describe '#load_source_files! hook ordering' do
    it 'remaps HUD keys before filtering projects, and passes the remap source id to the filter' do
      data_source = create(
        :grda_warehouse_data_source,
        pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true },
      )

      Dir.mktmpdir do |dir|
        write_export_csv(dir)
        loader = described_class.new(
          data_source_id: data_source.id,
          file_path: dir,
          limit_projects: true,
          remove_files: false,
        )
        loader.instance_variable_set(:@export, { SourceID: 'SRC-1' })
        allow(loader).to receive(:loadable_files).and_return({})
        allow(Importers::HmisAutoMigrate).to receive(:apply_migrations).and_return('2026')

        call_order = []
        allow(HmisCsvImporter::Loader::HudKeyRemapper).to receive(:remap!) { call_order << :remap }
        allow(HmisCsvImporter::Loader::ProjectFilter).to receive(:filter) do |*, **kwargs|
          call_order << [:filter, kwargs]
        end

        loader.send(:load_source_files!)

        expect(call_order).to eq([:remap, [:filter, { remap_source_id: 'SRC-1' }]])
        expect(HmisCsvImporter::Loader::HudKeyRemapper).to have_received(:remap!).with(dir, {}, 'SRC-1')
        expect(HmisCsvImporter::Loader::ProjectFilter).to have_received(:filter).with(dir, data_source.id, nil, remap_source_id: 'SRC-1')
      end
    end

    it 'does not remap or pass a remap source id when HudKeyRemapper is not enabled for the data source' do
      data_source = create(:grda_warehouse_data_source)

      Dir.mktmpdir do |dir|
        write_export_csv(dir)
        loader = described_class.new(
          data_source_id: data_source.id,
          file_path: dir,
          limit_projects: true,
          remove_files: false,
        )
        loader.instance_variable_set(:@export, { SourceID: 'SRC-1' })
        allow(loader).to receive(:loadable_files).and_return({})
        allow(Importers::HmisAutoMigrate).to receive(:apply_migrations).and_return('2026')

        allow(HmisCsvImporter::Loader::HudKeyRemapper).to receive(:remap!)
        allow(HmisCsvImporter::Loader::ProjectFilter).to receive(:filter)

        loader.send(:load_source_files!)

        expect(HmisCsvImporter::Loader::HudKeyRemapper).not_to have_received(:remap!)
        expect(HmisCsvImporter::Loader::ProjectFilter).to have_received(:filter).with(dir, data_source.id, nil, remap_source_id: nil)
      end
    end
  end
end
