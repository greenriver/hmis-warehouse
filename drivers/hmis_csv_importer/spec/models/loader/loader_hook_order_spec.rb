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

    it 'regenerates CLS IDs after filtering unlinked records and before remapping HUD keys' do
      data_source = create(
        :grda_warehouse_data_source,
        pre_process_hooks: {
          'HmisCsvImporter::Loader::UnlinkedRecordFilter' => true,
          'HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator' => true,
          'HmisCsvImporter::Loader::HudKeyRemapper' => true,
        },
      )

      Dir.mktmpdir do |dir|
        write_export_csv(dir)
        loader = described_class.new(
          data_source_id: data_source.id,
          file_path: dir,
          remove_files: false,
        )
        loader.instance_variable_set(:@export, { SourceID: 'SRC-1' })
        allow(loader).to receive(:loadable_files).and_return({})
        allow(Importers::HmisAutoMigrate).to receive(:apply_migrations).and_return('2026')

        call_order = []
        allow(HmisCsvImporter::Loader::UnlinkedRecordFilter).to receive(:filter!) { call_order << :unlinked }
        allow(HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator).to receive(:regenerate!) { call_order << :regenerate }
        allow(HmisCsvImporter::Loader::HudKeyRemapper).to receive(:remap!) { call_order << :remap }

        loader.send(:load_source_files!)

        expect(call_order).to eq([:unlinked, :regenerate, :remap])
        expect(HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator).to have_received(:regenerate!).with(dir, {}, loader.instance_variable_get(:@loader_log))
      end
    end

    it 'loads the regenerated CurrentLivingSitID hashed again with the SourceID when both hooks are enabled' do
      data_source = create(
        :grda_warehouse_data_source,
        pre_process_hooks: {
          'HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator' => true,
          'HmisCsvImporter::Loader::HudKeyRemapper' => true,
        },
      )
      klass = HmisCsvTwentyTwentySix::Loader::CurrentLivingSituation
      values = {
        'CurrentLivingSitID' => '1',
        'EnrollmentID' => 'E-1',
        'PersonalID' => 'C-1',
        'InformationDate' => '2026-01-15',
        'CurrentLivingSituation' => '101',
        'DateCreated' => '2026-01-15 09:30:00',
        'DateUpdated' => '2026-01-15 09:30:00',
        'UserID' => 'U-1',
        'ExportID' => 'EX-1',
      }

      Dir.mktmpdir do |dir|
        write_export_csv(dir)
        headers = klass.hud_csv_headers.map(&:to_s)
        File.write(File.join(dir, 'CurrentLivingSituation.csv'), headers.to_csv + headers.map { |header| values[header] }.to_csv)
        loader = described_class.new(
          data_source_id: data_source.id,
          file_path: dir,
          remove_files: false,
        )
        loader.instance_variable_set(:@export, { SourceID: 'SRC-1' })
        loader.instance_variable_set(:@loaded_at, Time.current)
        allow(loader).to receive(:loadable_files).and_return(
          {
            'Client.csv' => HmisCsvTwentyTwentySix::Loader::Client,
            'Enrollment.csv' => HmisCsvTwentyTwentySix::Loader::Enrollment,
            'CurrentLivingSituation.csv' => klass,
          },
        )
        allow(Importers::HmisAutoMigrate).to receive(:apply_migrations).and_return('2026')

        loader.send(:load_source_files!)

        regenerated_id = Digest::MD5.hexdigest('CurrentLivingSitID--E-1--C-1--2026-01-15--101--2026-01-15 09:30:00')
        expect(klass.where(loader_id: loader.loader_log.id).pluck(:CurrentLivingSitID, :EnrollmentID, :PersonalID)).to eq(
          [
            [
              Digest::MD5.hexdigest("CurrentLivingSitID--SRC-1--#{regenerated_id}"),
              Digest::MD5.hexdigest('EnrollmentID--SRC-1--E-1'),
              Digest::MD5.hexdigest('PersonalID--SRC-1--C-1'),
            ],
          ],
        )
      end
    end

    it 'does not regenerate CLS IDs when CurrentLivingSitIdRegenerator is not enabled for the data source' do
      data_source = create(:grda_warehouse_data_source, pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true })

      Dir.mktmpdir do |dir|
        write_export_csv(dir)
        loader = described_class.new(
          data_source_id: data_source.id,
          file_path: dir,
          remove_files: false,
        )
        loader.instance_variable_set(:@export, { SourceID: 'SRC-1' })
        allow(loader).to receive(:loadable_files).and_return({})
        allow(Importers::HmisAutoMigrate).to receive(:apply_migrations).and_return('2026')

        allow(HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator).to receive(:regenerate!)
        allow(HmisCsvImporter::Loader::HudKeyRemapper).to receive(:remap!)

        loader.send(:load_source_files!)

        expect(HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator).not_to have_received(:regenerate!)
        expect(HmisCsvImporter::Loader::HudKeyRemapper).to have_received(:remap!).with(dir, {}, 'SRC-1')
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
